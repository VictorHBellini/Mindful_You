// Cálculos puros extraídos do histórico global.
// API pública preservada para compatibilidade com as telas existentes.

// ============================================================
// SEQUÊNCIA DE DIAS CONSECUTIVOS (STREAK)
// ============================================================
//
// Fonte única do cálculo de "sequência". Antes, `historico_tela.dart` e
// `perfil_tela.dart` calculavam esse número de formas diferentes
// (um lia um campo inexistente e caía num valor aproximado; o outro
// simplesmente usava o total de check-ins), então cada tela mostrava um
// número de "dias seguidos" diferente para o mesmo usuário. Agora as
// duas usam esta função.

/// Retorna a data (sem hora) do check-in salvo em [item], ou `null` se a
/// entrada for antiga e não tiver o campo `dataIso`.
DateTime? _dataDoRegistro(Map<String, dynamic> item) {
  final iso = item['dataIso'];
  if (iso is String) {
    final data = DateTime.tryParse(iso);
    if (data != null) return DateTime(data.year, data.month, data.day);
  }
  return null;
}

/// Calcula quantos dias seguidos (até hoje ou ontem) o usuário fez pelo
/// menos um check-in. Se o último check-in foi há 2 dias ou mais, a
/// sequência é considerada quebrada e retorna 0.
int calcularSequenciaAtual(List<Map<String, dynamic>> historico) {
  final diasComCheckin = <DateTime>{};
  for (final item in historico) {
    final data = _dataDoRegistro(item);
    if (data != null) diasComCheckin.add(data);
  }

  if (diasComCheckin.isEmpty) return 0;

  final hoje = DateTime.now();
  final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
  final ontem = hojeSemHora.subtract(const Duration(days: 1));

  DateTime cursor;
  if (diasComCheckin.contains(hojeSemHora)) {
    cursor = hojeSemHora;
  } else if (diasComCheckin.contains(ontem)) {
    cursor = ontem;
  } else {
    // Nenhum check-in hoje nem ontem: a sequência foi quebrada.
    return 0;
  }

  int sequencia = 0;
  while (diasComCheckin.contains(cursor)) {
    sequencia++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return sequencia;
}

// ============================================================
// BEM-ESTAR (PONTUAÇÃO) DOS CHECK-INS
// ============================================================
//
// Fonte única do "score" de bem-estar. Antes, `perfil_tela.dart`
// calculava o bem-estar a partir dos contadores simplificados de humor
// (dias felizes/calmos sobre o total de check-ins do questionário
// antigo), enquanto `historico_tela.dart` calculava a partir dos
// valores reais de cansaço/ansiedade/sono/produtividade de cada
// check-in salvo em `historicoGlobal`. Isso fazia a tela de Perfil
// mostrar um número de "bem-estar" diferente do mostrado no Histórico
// para o mesmo usuário. Agora as duas usam estas funções.

/// Pontuação explicitamente registrada; não deduz bem-estar de outros sinais.
/// Retorna null para registros legados que não tenham pontuação.
int? obterBemEstarInformado(Map<String, dynamic> item) {
  final valor = item['bemEstar'] ?? item['bem_estar'];
  if (valor is! num || !valor.isFinite || valor < 0 || valor > 100) {
    return null;
  }
  return valor.round();
}

/// API legada: telas que exigem int recebem 0 se não houver registro válido.
/// Para distinguir ausência de zero, use obterBemEstarInformado.
int obterBemEstarDoRegistro(Map<String, dynamic> item) =>
    obterBemEstarInformado(item) ?? 0;

/// Média apenas de valores efetivamente informados.
int calcularMediaBemEstar(List<Map<String, dynamic>> historico) {
  final valores =
      historico.map(obterBemEstarInformado).whereType<int>().toList();
  if (valores.isEmpty) return 0;
  return (valores.reduce((a, b) => a + b) / valores.length).round();
}

// ============================================================
// SINAIS DE HUMOR E ENERGIA (rastreio clínico)
// ============================================================
//
// Fonte única da lógica de "sinal de atenção" usada pelas telas de
// Gráfico e Histórico. Os 4 campos abaixo vêm do questionário
// (páginas de humor/interesse/exaustão/distanciamento, ver
// `questionario_tela.dart`) e guardam uma frequência ('Nunca',
// 'Raramente', 'Às vezes', 'Frequentemente', 'Quase sempre') ou ''
// quando o check-in é antigo e não tem essa informação.
//
// Importante: isso é um apoio visual para notar padrões ao longo do
// tempo — não é uma pontuação clínica validada nem substitui a
// avaliação de um profissional. As telas que usam essas funções devem
// sempre deixar isso claro para quem estiver lendo.

const List<String> camposSinaisClinicos = [
  'humorFrequencia',
  'interesseFrequencia',
  'exaustaoBurnout',
  'distanciamentoBurnout',
];

/// Rótulo amigável de cada campo em [camposSinaisClinicos], na mesma
/// ordem, para exibição nas telas.
const Map<String, String> rotulosSinaisClinicos = {
  'humorFrequencia': 'Humor (desânimo ou tristeza)',
  'interesseFrequencia': 'Interesse ou prazer',
  'exaustaoBurnout': 'Exaustão emocional',
  'distanciamentoBurnout': 'Distanciamento ou desmotivação',
};

/// Retorna `true` se a frequência informada representa um sinal que
/// merece atenção ('Frequentemente' ou 'Quase sempre').
bool frequenciaElevada(String? frequencia) {
  return frequencia == 'Frequentemente' || frequencia == 'Quase sempre';
}

/// Quantos dos 4 campos de humor/energia de um único registro estão em
/// nível elevado ('Frequentemente' ou 'Quase sempre').
int contarSinaisElevados(Map<String, dynamic> item) {
  int total = 0;

  for (final campo in camposSinaisClinicos) {
    if (frequenciaElevada(item[campo]?.toString())) {
      total++;
    }
  }

  return total;
}

/// Verifica se há um padrão recente que pode valer a pena conversar
/// com o terapeuta: entre os [janela] check-ins mais recentes,
/// pelo menos [minimoComSinal] deles têm algum sinal elevado de humor
/// ou burnout.
///
/// [historicoRecentePrimeiro] deve estar ordenado do check-in mais
/// recente para o mais antigo (é assim que `historico_tela.dart` já
/// usa a lista, com `historicoGlobal.reversed`).
bool possuiPadraoRecenteDeAtencao(
  List<Map<String, dynamic>> historicoRecentePrimeiro, {
  int janela = 3,
  int minimoComSinal = 2,
}) {
  final recentes = historicoRecentePrimeiro.take(janela);
  final comSinal = recentes
      .where(
        (item) => contarSinaisElevados(item) > 0,
      )
      .length;

  return comSinal >= minimoComSinal;
}
