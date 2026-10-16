import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/assessment/services/avaliacao_service.dart';

void main() {
  test('GAD7 pontua sete respostas', () {
    expect(AvaliacaoService.pontuar('GAD7', [0, 1, 2, 3, 0, 1, 2]), 9);
  });
  test('PHQ9 pontua nove respostas', () {
    expect(AvaliacaoService.pontuar('PHQ9', List.filled(9, 3)), 27);
  });
  test('Rejeita respostas fora da escala', () {
    expect(() => AvaliacaoService.pontuar('GAD7', [0, 1, 2, 4, 0, 1, 2]),
        throwsArgumentError);
  });
  test('Rejeita comprimento incorreto', () {
    expect(() => AvaliacaoService.pontuar('PHQ9', List.filled(8, 0)),
        throwsArgumentError);
  });
  test(
      'PHQ9 sinaliza resposta positiva no item sensível independentemente do total',
      () {
    expect(
        AvaliacaoService.itemSensivelPositivo(
            'PHQ9', [0, 0, 0, 0, 0, 0, 0, 0, 1]),
        isTrue);
    expect(AvaliacaoService.itemSensivelPositivo('PHQ9', List.filled(9, 0)),
        isFalse);
  });
}
