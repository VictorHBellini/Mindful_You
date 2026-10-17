import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/checkin/data/checkin_repository.dart';

void main() {
  test('converte registro SQLite preservando indicadores e status', () {
    final entrada = linhaParaEntradaCheckin({
      'data_iso': '2026-10-17T10:00:00',
      'data_formatada': '17/10/2026',
      'sentimento': 'Bem',
      'emoji': '🙂',
      'cor_valor': 0xFFE8DCD4,
      'bem_estar': 80,
      'cansaco': 30,
      'ansiedade': 20,
      'sono': 10,
      'atividade_significativa': 'Prefiro não responder',
      'principal_ponto': 'Cansaço estimado',
    });

    expect(entrada['dataIso'], '2026-10-17T10:00:00');
    expect(entrada['status'], 'Bem 🙂');
    expect(entrada['bemEstar'], 80);
    expect(entrada['principalPonto'], 'Cansaço estimado');
    expect(entrada['dadosGrafico']['cansaco'], 30);
    expect(entrada['dadosGrafico']['ansiedade'], 20);
    expect(entrada['respostas'][3], 'Não informado');
    expect(entrada['perguntas'], hasLength(4));
  });

  test('registro legado não inventa respostas de humor e energia', () {
    final entrada = linhaParaEntradaCheckin({
      'data_iso': '2025-01-01',
      'data_formatada': '01/01/2025',
      'sentimento': '',
      'cansaco': null,
      'ansiedade': null,
      'sono': null,
      'produtividade': null,
    });

    expect(entrada['status'], isNull);
    expect(entrada['perguntas'], hasLength(4));
    expect(entrada['respostas'], everyElement('Não informado'));
    expect(entrada['dadosGrafico']['cansaco'], isNull);
  });

  test('inclui sinais adicionais apenas quando registrados', () {
    final entrada = linhaParaEntradaCheckin({
      'atividade_significativa': 'Sim',
      'humor_frequencia': 'Frequentemente',
      'exaustao_burnout': 'Raramente',
    });
    expect(entrada['perguntas'], hasLength(6));
    expect(entrada['respostas'][3], 'Sim');
    expect(entrada['respostas'][4], 'Frequentemente');
    expect(entrada['respostas'][5], 'Raramente');
  });
}
