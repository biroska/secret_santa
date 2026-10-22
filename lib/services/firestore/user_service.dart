import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

import '../../models/user.dart'; // Importando a classe Users

class UserService {
  final CollectionReference _usersCollection;

  UserService({FirebaseFirestore? firestore})
      : _usersCollection =
            (firestore ?? FirebaseFirestore.instance).collection('users');

  /// Verifica se um usuário existe na coleção 'users' pelo UID.
  Future<bool> userExists(String uid) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();
      return docSnapshot.exists;
    } catch (e) {
      debugPrint('Erro ao verificar existência do usuário $uid: $e');
      return false;
    }
  }

  /// Cria um novo registro de usuário na coleção 'users'.
  Future<void> createUser(Users user) async {
    try {
      // Convertendo Users para um Map compatível com Firestore,
      // ajustando createdAt para Timestamp
      final Map<String, dynamic> userData = {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'createdAt': Timestamp.fromDate(user.createdAt), // Convertendo DateTime para Timestamp
      };
      await _usersCollection.doc(user.id).set(userData);
      debugPrint('Usuário ${user.id} criado com sucesso no Firestore.');
    } catch (e) {
      debugPrint('Erro ao criar usuário ${user.id} no Firestore: $e');
      rethrow;
    }
  }

  /// Obtém um Users pelo UID.
  Future<Users?> getUserById(String uid) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        // Convertendo Timestamp de volta para DateTime para o construtor Users
        // Certifique-se de que o campo 'createdAt' existe e é um Timestamp
        final createdAtTimestamp = data['createdAt'] as Timestamp?;
        final createdAt = createdAtTimestamp?.toDate() ?? DateTime.now(); // Fallback para evitar null
        final rawTokens = data['fcmTokens'];
        final fcmTokens = rawTokens is List
            ? rawTokens.whereType<String>().toList()
            : const <String>[];

        return Users(
          id: data['id'] as String,
          name: data['name'] as String,
          email: data['email'] as String,
          photoUrl: data['photoUrl'] as String,
          createdAt: createdAt,
          fcmTokens: fcmTokens,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao obter usuário $uid do Firestore: $e');
      return null;
    }
  }

  /// Registra um token FCM no documento do usuário (multi-dispositivo).
  Future<void> addFcmToken(String uid, String token) async {
    if (uid.isEmpty || token.isEmpty) return;
    try {
      await _usersCollection.doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmTokensUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro ao adicionar fcmToken do usuário $uid: $e');
      rethrow;
    }
  }

  /// Remove um token FCM do documento do usuário.
  Future<void> removeFcmToken(String uid, String token) async {
    if (uid.isEmpty || token.isEmpty) return;
    try {
      await _usersCollection.doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
        'fcmTokensUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erro ao remover fcmToken do usuário $uid: $e');
    }
  }
}
