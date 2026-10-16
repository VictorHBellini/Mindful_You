/// Regras de interpretação do check-in breve do Mindful You.
/// Não constitui escala psicométrica nem diagnóstico clínico.
class CheckinIndicadores {
  final double bemEstar;
  final double ansiedade;
  final double energia;
  final double qualidadeSono;
  final String atividadeSignificativa;

  CheckinIndicadores({
    required this.bemEstar,
    required this.ansiedade,
    required this.energia,
    required this.qualidadeSono,
    required this.atividadeSignificativa,
  }) {
    for (final valor in [bemEstar, ansiedade, energia, qualidadeSono]) {
      if (!valor.isFinite || valor < 0 || valor > 100) {
        throw ArgumentError('Escalas devem estar entre 0 e 100.');
      }
    }
    if (!const ['Sim', 'Parcialmente', 'Não', 'Prefiro não responder']
        .contains(atividadeSignificativa)) {
      throw ArgumentError('Resposta de atividade significativa inválida.');
    }
  }

  /// Indicadores descritivos, não equivalências clínicas validadas.
  double get cansacoEstimado => 100 - energia;
  double get ansiedadePercebida => ansiedade;
  double get dificuldadeSonoEstimada => 100 - qualidadeSono;
  int get bemEstarInformado => bemEstar.round();
  String get atividadeExibida =>
      atividadeSignificativa == 'Prefiro não responder'
          ? 'Não informado'
          : atividadeSignificativa;

  /// Não compara atividade significativa com sintomas de maneira artificial.
  String get principalIndicador {
    final valores = <String, double>{
      'Cansaço estimado': cansacoEstimado,
      'Ansiedade percebida': ansiedadePercebida,
      'Dificuldade percebida com o sono': dificuldadeSonoEstimada,
    };
    return valores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Map<String, Object?> toDados() => {
        'bemEstar': bemEstarInformado,
        'cansaco': cansacoEstimado,
        'ansiedade': ansiedadePercebida,
        'sono': dificuldadeSonoEstimada,
        'atividadeSignificativa': atividadeSignificativa,
        // Não atribuir produtividade numérica a partir da atividade.
        'produtividade': null,
        'principalPonto': principalIndicador,
      };
}
