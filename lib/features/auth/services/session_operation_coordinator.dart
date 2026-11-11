import 'dart:async';

/// Serializa operacoes sensiveis da sessao dentro do processo.
///
/// Nao substitui autenticacao nem autorizacao.
/// Todos os pontos que alteram a identidade local precisam
/// participar deste coordenador.
class SessionOperationCoordinator {
  SessionOperationCoordinator._();

  static Future<void> _fila = Future<void>.value();

  static Future<T> executar<T>(
    Future<T> Function() operacao,
  ) async {
    final anterior = _fila;
    final liberacao = Completer<void>();

    _fila = liberacao.future;

    try {
      await anterior;
      return await operacao();
    } finally {
      if (!liberacao.isCompleted) {
        liberacao.complete();
      }
    }
  }
}
