import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/history/historico_global.dart';

typedef Entradas = List<Map<String, dynamic>>;

void main() {
  setUp(invalidarCacheHistorico);
  tearDown(invalidarCacheHistorico);

  test('logout descarta uma leitura pendente', () async {
    final resposta = Completer<Entradas>();
    final carregamento = carregarHistorico(
      obterUsuarioId: () async => 1,
      listarEntradas: (_) => resposta.future,
    );
    // Permite que a consulta chegue à leitura de entradas.
    await Future<void>.delayed(Duration.zero);
    invalidarCacheHistorico();
    resposta.complete([
      {'sentimento': 'Conta A'}
    ]);
    await carregamento;
    expect(historicoGlobal, isEmpty);
  });

  test('leitura da conta A não sobrescreve resultado da conta B', () async {
    final respostaA = Completer<Entradas>();
    final leituraA = carregarHistorico(
      obterUsuarioId: () async => 1,
      listarEntradas: (_) => respostaA.future,
    );
    await Future<void>.delayed(Duration.zero);
    invalidarCacheHistorico();
    final leituraB = carregarHistorico(
      obterUsuarioId: () async => 2,
      listarEntradas: (_) async => [
        {'sentimento': 'Conta B'}
      ],
    );
    await leituraB;
    respostaA.complete([
      {'sentimento': 'Conta A'}
    ]);
    await leituraA;
    expect(historicoGlobal, hasLength(1));
    expect(historicoGlobal.single['sentimento'], 'Conta B');
  });

  test('mudança de identidade durante a consulta descarta o resultado',
      () async {
    var usuarioAtual = 1;
    final resposta = Completer<Entradas>();
    final carregamento = carregarHistorico(
      obterUsuarioId: () async => usuarioAtual,
      listarEntradas: (_) => resposta.future,
    );
    await Future<void>.delayed(Duration.zero);
    usuarioAtual = 2;
    resposta.complete([
      {'sentimento': 'Conta A'}
    ]);
    await carregamento;
    expect(historicoGlobal, isEmpty);
  });
}
