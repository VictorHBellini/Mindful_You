import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Lista em memória — sincronizada com SharedPreferences
List<Map<String, dynamic>> historicoGlobal = [];

/// Carrega o histórico salvo no SharedPreferences para a lista em memória.
/// Deve ser chamado uma vez ao iniciar o app (no main.dart) ou
/// na tela de histórico antes de exibir.
Future<void> carregarHistorico() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString('historicoGlobal');

  if (jsonString != null) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) throw const FormatException('Histórico inválido');

      historicoGlobal = decoded.whereType<Map>().map((item) {
        // A Color não é serializável em JSON; reconstrói a partir do valor int salvo.
        final entry = Map<String, dynamic>.from(item);
        if (entry['corValor'] is int) {
          entry['cor'] = Color(entry['corValor'] as int);
        }
        return entry;
      }).toList();
    } on FormatException {
      historicoGlobal = [];
    }
  }
}

/// Adiciona um registro ao histórico e persiste no SharedPreferences.
Future<void> adicionarHistorico(Map<String, dynamic> entrada) async {
  // Converte Color para int antes de serializar
  final Map<String, dynamic> entradaSerializavel =
      Map<String, dynamic>.from(entrada);
  if (entradaSerializavel['cor'] is Color) {
    entradaSerializavel['corValor'] =
        (entradaSerializavel['cor'] as Color).toARGB32();
    entradaSerializavel.remove('cor');
  }
  // Remove chaves não serializáveis (perguntas/respostas são List<String> — OK)
  if (entradaSerializavel['dadosGrafico'] != null) {
    entradaSerializavel['dadosGrafico'] =
        Map<String, dynamic>.from(entradaSerializavel['dadosGrafico']);
  }

  // Persiste versão sem Color
  final prefs = await SharedPreferences.getInstance();
  List<dynamic> listaAtual = [];
  try {
    final decoded = jsonDecode(prefs.getString('historicoGlobal') ?? '[]');
    if (decoded is List) listaAtual = decoded;
  } on FormatException {
    // Um histórico local inválido não impede novos check-ins.
  }
  listaAtual.add(entradaSerializavel);
  await prefs.setString('historicoGlobal', jsonEncode(listaAtual));

  // Também adiciona na memória com Color reconstituída
  final Map<String, dynamic> entradaMemoria =
      Map<String, dynamic>.from(entradaSerializavel);
  if (entradaMemoria['corValor'] != null) {
    entradaMemoria['cor'] = Color(entradaMemoria['corValor'] as int);
  }
  historicoGlobal.add(entradaMemoria);
}

/// Limpa todo o histórico salvo (memória + SharedPreferences).
Future<void> limparHistorico() async {
  historicoGlobal.clear();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('historicoGlobal');
}

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

/// Retorna a pontuação de bem-estar (0 a 100) de um único registro do
/// histórico, tentando primeiro os campos numéricos diretos e, na
/// falta deles, calculando a média de `dadosGrafico` ou interpretando
/// o campo `status`.
int obterBemEstarDoRegistro(Map<String, dynamic> item) {
  final campos = [
    'bemEstar',
    'bem_estar',
    'pontuacao',
    'porcentagem',
    'percentual',
    'score',
    'media',
  ];

  for (final campo in campos) {
    final valor = item[campo];
    if (valor is num) {
      return valor.clamp(0, 100).round();
    }
  }

  final dados = item['dadosGrafico'];
  if (dados is Map) {
    final numeros = <double>[];
    for (final valor in dados.values) {
      if (valor is num) numeros.add(valor.toDouble());
    }
    if (numeros.isNotEmpty) {
      final media = numeros.reduce((a, b) => a + b) / numeros.length;
      return media.clamp(0, 100).round();
    }
  }

  final status = item['status']?.toString().toLowerCase() ?? '';

  if (status.contains('muito bem') || status.contains('excelente')) {
    return 90;
  }
  if (status.contains('bem')) return 80;
  if (status.contains('regular') || status.contains('normal')) return 65;
  if (status.contains('mal') || status.contains('baixo')) return 40;

  return 70;
}

/// Média de bem-estar (0 a 100) de todos os registros informados.
/// Retorna 0 se o histórico estiver vazio.
int calcularMediaBemEstar(List<Map<String, dynamic>> historico) {
  if (historico.isEmpty) return 0;

  final valores = historico.map(obterBemEstarDoRegistro).toList();
  final soma = valores.reduce((a, b) => a + b);

  return (soma / valores.length).round();
}
