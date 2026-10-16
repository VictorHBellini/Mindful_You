import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/services/checkin_indicadores.dart';

void main() {
  test('conversões e ausência de resposta', () {
    final resultado = CheckinIndicadores(
      bemEstar: 80,
      ansiedade: 20,
      energia: 70,
      qualidadeSono: 90,
      atividadeSignificativa: 'Prefiro não responder',
    );
    expect(resultado.bemEstarInformado, 80);
    expect(resultado.cansacoEstimado, 30);
    expect(resultado.ansiedadePercebida, 20);
    expect(resultado.dificuldadeSonoEstimada, 10);
    expect(resultado.atividadeExibida, 'Não informado');
    expect(resultado.toDados()['produtividade'], isNull);
    expect(resultado.principalIndicador, 'Cansaço estimado');
  });

  test('extremos e atividade respondida', () {
    final resultado = CheckinIndicadores(
      bemEstar: 0,
      ansiedade: 100,
      energia: 0,
      qualidadeSono: 100,
      atividadeSignificativa: 'Sim',
    );
    expect(resultado.cansacoEstimado, 100);
    expect(resultado.dificuldadeSonoEstimada, 0);
    expect(resultado.atividadeExibida, 'Sim');
  });

  test('recusa valores inválidos', () {
    expect(
      () => CheckinIndicadores(
        bemEstar: 101,
        ansiedade: 20,
        energia: 70,
        qualidadeSono: 90,
        atividadeSignificativa: 'Sim',
      ),
      throwsArgumentError,
    );
  });
}
