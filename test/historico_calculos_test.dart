import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/checkin/domain/historico_calculos.dart';

void main() {
  Map<String, dynamic> registro(DateTime data) => {
        'dataIso': data.toIso8601String(),
      };

  group('Sequência de check-ins', () {
    test('histórico vazio e datas inválidas não geram sequência', () {
      expect(calcularSequenciaAtual([]), 0);
      expect(
          calcularSequenciaAtual([
            {'dataIso': 'inválida'}
          ]),
          0);
    });

    test('conta dias consecutivos, sem duplicar registros do mesmo dia', () {
      final hoje = DateTime.now();
      final dia = DateTime(hoje.year, hoje.month, hoje.day);
      expect(
          calcularSequenciaAtual([
            registro(dia),
            registro(dia.add(const Duration(hours: 2))),
            registro(dia.subtract(const Duration(days: 1))),
            registro(dia.subtract(const Duration(days: 2))),
          ]),
          3);
    });

    test('permite último check-in ontem e interrompe após dois dias', () {
      final hoje = DateTime.now();
      final dia = DateTime(hoje.year, hoje.month, hoje.day);
      expect(
          calcularSequenciaAtual([
            registro(dia.subtract(const Duration(days: 1))),
            registro(dia.subtract(const Duration(days: 2))),
          ]),
          2);
      expect(
          calcularSequenciaAtual([
            registro(dia.subtract(const Duration(days: 2))),
          ]),
          0);
    });
  });

  group('Bem-estar', () {
    test('distingue zero de valor não informado', () {
      expect(obterBemEstarInformado({'bemEstar': 0}), 0);
      expect(obterBemEstarInformado({}), isNull);
      expect(obterBemEstarDoRegistro({}), 0);
    });

    test('descarta valores inválidos e calcula média dos informados', () {
      expect(obterBemEstarInformado({'bemEstar': -1}), isNull);
      expect(obterBemEstarInformado({'bemEstar': 101}), isNull);
      expect(obterBemEstarInformado({'bemEstar': double.nan}), isNull);
      expect(
          calcularMediaBemEstar([
            {'bemEstar': 80},
            {'bem_estar': 20},
            {},
            {'bemEstar': 150},
          ]),
          50);
      expect(calcularMediaBemEstar([]), 0);
    });
  });

  group('Sinais de atenção', () {
    test('somente frequências elevadas contam', () {
      expect(frequenciaElevada('Frequentemente'), isTrue);
      expect(frequenciaElevada('Quase sempre'), isTrue);
      expect(frequenciaElevada('Às vezes'), isFalse);
      expect(frequenciaElevada(null), isFalse);
      expect(
          contarSinaisElevados({
            'humorFrequencia': 'Frequentemente',
            'interesseFrequencia': 'Quase sempre',
            'exaustaoBurnout': 'Raramente',
          }),
          2);
    });

    test('identifica padrão recente conforme janela e mínimo', () {
      final sinal = {'humorFrequencia': 'Frequentemente'};
      final neutro = {'humorFrequencia': 'Nunca'};
      expect(possuiPadraoRecenteDeAtencao([sinal, neutro, sinal]), isTrue);
      expect(possuiPadraoRecenteDeAtencao([sinal, neutro, neutro]), isFalse);
      expect(
        possuiPadraoRecenteDeAtencao(
          [neutro, sinal, sinal],
          janela: 2,
          minimoComSinal: 2,
        ),
        isFalse,
      );
    });
  });
}
