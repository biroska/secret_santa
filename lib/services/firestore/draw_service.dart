import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Erro amigável ao chamar a Cloud Function de sorteio.
class DrawException implements Exception {
  const DrawException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Serviço responsável por acionar o sorteio (executado no backend/Firebase).
class DrawService {
  DrawService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Executa o sorteio do evento [eventId] via Cloud Function `performDraw`.
  ///
  /// A geração dos pares giver/receiver acontece inteiramente no backend
  /// (respeitando as regras de negócio e sem exposição do algoritmo/dados
  /// para o cliente), garantindo performance e segurança.
  Future<void> performDraw(String eventId) async {
    try {
      final callable = _functions.httpsCallable('performDraw');
      debugPrint(
        'Invocando Cloud Function performDraw para o evento $eventId.',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'eventId': eventId,
      });
      debugPrint(
        'Retorno da Cloud Function performDraw para o evento $eventId: '
        'success=${result.data['success']}, '
        'pairsCount=${result.data['pairsCount']}.',
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Erro ao realizar sorteio do evento $eventId: ${e.code} ${e.message}',
      );
      throw DrawException(_messageForCode(e));
    } catch (e) {
      debugPrint('Erro inesperado ao realizar sorteio do evento $eventId: $e');
      throw const DrawException(
        'Não foi possível realizar o sorteio. Tente novamente.',
      );
    }
  }

  /// Retorna o receiver associado ao participante autenticado.
  Future<String> getMyDraw(String eventId) async {
    try {
      final callable = _functions.httpsCallable('getMyDraw');
      debugPrint('Invocando Cloud Function getMyDraw para o evento $eventId.');
      final result = await callable.call<Map<String, dynamic>>({
        'eventId': eventId,
      });
      final receiverId = result.data['receiverId'];
      if (receiverId is! String || receiverId.isEmpty) {
        throw const DrawException(
          'A resposta do sorteio não contém um participante válido.',
        );
      }
      debugPrint(
        'Retorno da Cloud Function getMyDraw para o evento $eventId: '
        'success=true.',
      );
      return receiverId;
    } on DrawException {
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Erro ao revelar o amigo secreto do evento $eventId: '
        '${e.code} ${e.message}',
      );
      throw DrawException(_messageForCode(e));
    } catch (e) {
      debugPrint(
        'Erro inesperado ao revelar o amigo secreto do evento $eventId: $e',
      );
      throw const DrawException(
        'Não foi possível revelar o amigo secreto. Tente novamente.',
      );
    }
  }

  Future<List<String>> validateEventDraw(String eventId) async {
    try {
      final callable = _functions.httpsCallable('validateEventDraw');
      final result = await callable.call<Map<String, dynamic>>({
        'eventId': eventId,
      });
      final issues = result.data['issues'];
      if (issues is! List || !issues.every((issue) => issue is String)) {
        throw const DrawException(
          'A resposta da validação possui um formato inválido.',
        );
      }
      return issues.cast<String>();
    } on DrawException {
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      throw DrawException(_messageForCode(e));
    }
  }

  String _messageForCode(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'failed-precondition':
        return e.message ?? 'Não é possível realizar o sorteio no momento.';
      case 'permission-denied':
        return e.message ?? 'Você não tem permissão para esta ação.';
      case 'unauthenticated':
        return 'É necessário estar autenticado para realizar o sorteio.';
      case 'not-found':
        return e.message ?? 'Evento ou resultado de sorteio não encontrado.';
      default:
        return e.message ?? 'Não foi possível realizar o sorteio.';
    }
  }
}
