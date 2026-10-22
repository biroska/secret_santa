import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../widgets/app_snack_bar.dart';
import '../firestore/user_service.dart';
import 'push_notification_payload.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('FCM background: ${message.messageId} ${message.data}');
  }
}

typedef PushNavigationHandler = void Function(String route);

const String kDrawEventsChannelId = 'draw_events';
const String kDrawEventsChannelName = 'Avisos de sorteio';
const String kDrawEventsChannelDescription =
    'Notificações quando o sorteio de um evento é realizado';

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    UserService? userService,
    FirebaseAuth? auth,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin(),
       _userService = userService ?? UserService(),
       _auth = auth ?? FirebaseAuth.instance;

  static PushNotificationService? _instance;

  static PushNotificationService get instance =>
      _instance ??= PushNotificationService();

  @visibleForTesting
  static set instanceForTesting(PushNotificationService? value) =>
      _instance = value;

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final UserService _userService;
  final FirebaseAuth _auth;

  PushNavigationHandler? _onNavigate;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  bool _initialized = false;
  String? _currentToken;
  String? _pendingRoute;
  String? _currentRouteHint;

  static bool get _isAndroidSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void attachNavigationHandler(PushNavigationHandler handler) {
    _onNavigate = handler;
    final pending = _pendingRoute;
    if (pending != null) {
      _pendingRoute = null;
      handler(pending);
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (!_isAndroidSupported) {
      _initialized = true;
      return;
    }

    await _initLocalNotifications();
    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleMessageOpened,
    );

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _queueOrNavigate(PushNotificationPayload.fromRemoteMessage(initial));
    }

    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      final previous = _currentToken;
      _currentToken = token;
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      try {
        if (previous != null && previous != token) {
          await _userService.removeFcmToken(uid, previous);
        }
        await _userService.addFcmToken(uid, token);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('Falha ao atualizar token FCM: $e\n$st');
        }
      }
    });

    _initialized = true;
  }

  Future<void> registerForUser(String uid) async {
    if (!_isAndroidSupported || uid.isEmpty) return;
    try {
      if (!_initialized) await initialize();
      if (!_initialized) return;
      final granted = await _requestPermissionIfNeeded();
      if (!granted) return;

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      _currentToken = token;
      await _userService.addFcmToken(uid, token);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Falha ao obter/salvar FCM token: $e\n$st');
      }
    }
  }

  Future<void> unregisterForUser(String uid) async {
    if (!_isAndroidSupported || uid.isEmpty) return;
    final token = _currentToken ?? await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _userService.removeFcmToken(uid, token);
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    const channel = AndroidNotificationChannel(
      kDrawEventsChannelId,
      kDrawEventsChannelName,
      description: kDrawEventsChannelDescription,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<bool> _requestPermissionIfNeeded() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    final status = settings.authorizationStatus;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final payload = PushNotificationPayload.fromRemoteMessage(message);
    await _showLocalNotification(message, payload);

    final eventId = payload.eventId;
    final alreadyOnEvent =
        eventId != null &&
        _currentRouteHint?.contains('/event-details/$eventId') == true;
    if (!alreadyOnEvent) {
      AppSnackBar.successRoot(payload.displayBody);
    }
  }

  void updateCurrentRouteHint(String? location) {
    _currentRouteHint = location;
  }

  Future<void> _showLocalNotification(
    RemoteMessage message,
    PushNotificationPayload payload,
  ) async {
    final title = payload.title ?? 'Secret Santa';
    final body = payload.displayBody;
    final payloadJson = jsonEncode({
      'type': message.data['type'],
      'eventId': payload.eventId,
      'eventTitle': payload.eventTitle,
    });

    const androidDetails = AndroidNotificationDetails(
      kDrawEventsChannelId,
      kDrawEventsChannelName,
      channelDescription: kDrawEventsChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    await _localNotifications.show(
      message.hashCode & 0x7fffffff,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payloadJson,
    );
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final payload = PushNotificationPayload(
        type: map['type'] == 'draw_completed'
            ? PushNotificationType.drawCompleted
            : PushNotificationType.unknown,
        eventId: map['eventId']?.toString(),
        eventTitle: map['eventTitle']?.toString(),
      );
      _queueOrNavigate(payload);
    } on FormatException catch (e) {
      if (kDebugMode) debugPrint('Payload local inválido: $e');
    } on TypeError catch (e) {
      if (kDebugMode) debugPrint('Formato de payload local inválido: $e');
    }
  }

  void _handleMessageOpened(RemoteMessage message) {
    _queueOrNavigate(PushNotificationPayload.fromRemoteMessage(message));
  }

  void _queueOrNavigate(PushNotificationPayload payload) {
    final route = payload.deepLinkRoute;
    if (route == null) return;
    final handler = _onNavigate;
    if (handler != null) {
      handler(route);
    } else {
      _pendingRoute = route;
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedAppSub?.cancel();
  }
}
