import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mindful_you/services/database_service.dart';

// ============================================================
// HISTÓRICO DE CHECK-INS DO USUÁRIO LOGADO
// ============================================================
//
// BUG CORRIGIDO: antes, todo o histórico de check-ins (e os campos
// "último sentimento/emoji/data") ficavam salvos em chaves globais do
// SharedPreferences — as mesmas para qualquer conta usada no aparelho.
// Como o app permite múltiplas contas (login/cadastro/gerenciar
// usuários), trocar de usuário (logout + login com outra conta) fazia
// a pessoa ver o histórico de check-ins de quem tivesse usado o app
// antes dela no mesmo celular.
//
// Agora cada check-in é salvo na tabela `checkins` do SQLite
// (`database_service.dart`), vinculado ao `usuario_id` de quem
// respondeu. Esta lista em memória continua existindo (para não
// precisar mudar todas as telas que já a usam), mas passa a ser
// apenas um cache dos registros do usuário atualmente logado.

/// Lista em memória — cache dos check-ins do usuário atualmente logado.
List<Map<String, dynamic>> historicoGlobal = [];

// Invalida resultados de carregamentos anteriores que terminem fora de ordem.
int _versaoCarregamentoHistorico = 0;

/// Retorna o id do usuário atualmente logado (salvo em SharedPreferences
/// no login/cadastro), ou `null` se não houver ninguém logado.
Future<int?> _usuarioIdAtual() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('usuarioId');
}

/// Converte uma linha da tabela `checkins` para o mesmo formato de Map
/// que as telas (Histórico, Gráfico, Relatório etc) já esperavam
/// quando o histórico vinha do SharedPreferences.
Map<String, dynamic> _linhaParaEntrada(Map<String, dynamic> linha) {
  final cansaco = linha['cansaco'] as num?;
  final ansiedade = linha['ansiedade'] as num?;
  final sono = linha['sono'] as num?;
  final produtividade = linha['produtividade'] as num?;

  final atividade = linha['atividade_significativa']?.toString();
  final sentimento = linha['sentimento']?.toString() ?? '';
  final emoji = linha['emoji']?.toString() ?? '';

  // Sinais de humor e energia (podem vir vazios em check-ins salvos
  // antes desta funcionalidade existir).
  final humorFrequencia = linha['humor_frequencia']?.toString() ?? '';
  final interesseFrequencia = linha['interesse_frequencia']?.toString() ?? '';
  final exaustaoBurnout = linha['exaustao_burnout']?.toString() ?? '';
  final distanciamentoBurnout =
      linha['distanciamento_burnout']?.toString() ?? '';

  return {
    'data': linha['data_formatada'],
    'dataIso': linha['data_iso'],
    'sentimento': sentimento,
    'emoji': emoji,
    // BUG CORRIGIDO: os cards de `historico_tela.dart` (último check-in
    // e cada item da lista) leem `item['status']` para mostrar um
    // resumo do registro, mas essa chave nunca era preenchida — todo
    // check-in aparecia com o texto genérico "Check-in realizado".
    // Agora usamos o sentimento e o emoji escolhidos no questionário.
    'status': sentimento.isNotEmpty
        ? '$sentimento ${emoji.isNotEmpty ? emoji : ''}'.trim()
        : null,
    'cor': linha['cor_valor'] is int
        ? Color(linha['cor_valor'] as int)
        : const Color(0xFFE8DCD4),
    'bemEstar': linha['bem_estar'],
    'atividadeSignificativa': atividade,
    'dadosGrafico': {
      'cansaco': cansaco,
      'ansiedade': ansiedade,
      'sono': sono,
      'produtividade': produtividade,
      'atividadeSignificativa': atividade,
    },
    // Sinais de humor e energia — ver observação no topo da seção
    // "SINAIS DE HUMOR E ENERGIA" mais abaixo neste arquivo.
    'humorFrequencia': humorFrequencia,
    'interesseFrequencia': interesseFrequencia,
    'exaustaoBurnout': exaustaoBurnout,
    'distanciamentoBurnout': distanciamentoBurnout,
    // Mantém compatibilidade com a tela de Relatório (RegistrosTela),
    // que espera 'perguntas' e 'respostas'. Os 4 itens de humor e
    // energia só entram na lista quando o check-in tem alguma
    // resposta salva para eles (check-ins antigos, de antes desta
    // funcionalidade, não têm — e não devem aparecer como "vazio"
    // no relatório).
    'perguntas': [
      'Cansaço',
      'Ansiedade',
      'Falta de sono',
      if (atividade == null) 'Produtividade' else 'Atividade significativa',
      if (humorFrequencia.isNotEmpty) 'Humor (desânimo ou tristeza)',
      if (interesseFrequencia.isNotEmpty) 'Interesse ou prazer',
      if (exaustaoBurnout.isNotEmpty) 'Exaustão emocional',
      if (distanciamentoBurnout.isNotEmpty) 'Distanciamento ou desmotivação',
    ],
    'respostas': [
      (cansaco == null ? 'Não informado' : '${cansaco.toInt()}%'),
      (ansiedade == null ? 'Não informado' : '${ansiedade.toInt()}%'),
      (sono == null ? 'Não informado' : '${sono.toInt()}%'),
      if (atividade == null)
        (produtividade == null ? 'Não informado' : '${produtividade.toInt()}%')
      else if (atividade == 'Prefiro não responder')
        'Não informado'
      else
        atividade,
      if (humorFrequencia.isNotEmpty) humorFrequencia,
      if (interesseFrequencia.isNotEmpty) interesseFrequencia,
      if (exaustaoBurnout.isNotEmpty) exaustaoBurnout,
      if (distanciamentoBurnout.isNotEmpty) distanciamentoBurnout,
    ],
    'principalPonto': linha['principal_ponto'],
  };
}

/// Carrega, da tabela `checkins` do SQLite para a lista em memória, os
/// registros do usuário atualmente logado (do mais antigo para o mais
/// recente). Deve ser chamado sempre que um usuário faz login ou
/// cadastro — assim a lista em memória nunca mistura o histórico de
/// outra conta que tenha usado o app no mesmo aparelho.
Future<void> carregarHistorico() async {
  final versao = ++_versaoCarregamentoHistorico;
  final usuarioId = await _usuarioIdAtual();
  if (versao != _versaoCarregamentoHistorico) return;

  if (usuarioId == null) {
    historicoGlobal = [];
    return;
  }

  final linhas = await DatabaseService.instance.listarCheckins(usuarioId);
  if (versao != _versaoCarregamentoHistorico) return;
  // A conta pode ter mudado enquanto o SQLite respondia.
  if (await _usuarioIdAtual() != usuarioId) {
    historicoGlobal = [];
    return;
  }
  if (versao != _versaoCarregamentoHistorico) return;
  historicoGlobal = linhas.map(_linhaParaEntrada).toList();
}

/// Adiciona um check-in ao histórico do usuário atualmente logado,
/// persistindo na tabela `checkins` do SQLite, e atualiza a lista em
/// memória. Se não houver usuário logado (não deveria acontecer, já
/// que só se chega ao questionário depois do login), o check-in não é
/// salvo.
Future<void> adicionarHistorico(Map<String, dynamic> entrada) async {
  final usuarioId = await _usuarioIdAtual();
  if (usuarioId == null) return;

  final dadosGrafico = entrada['dadosGrafico'] as Map? ?? {};
  final cor = entrada['cor'];

  await DatabaseService.instance.inserirCheckin(
    usuarioId: usuarioId,
    dataIso: entrada['dataIso']?.toString() ?? DateTime.now().toIso8601String(),
    dataFormatada: entrada['data']?.toString() ?? '',
    sentimento: entrada['sentimento']?.toString() ?? '',
    emoji: entrada['emoji']?.toString() ?? '🙂',
    cansaco: (dadosGrafico['cansaco'] as num?)?.toDouble() ?? 0,
    ansiedade: (dadosGrafico['ansiedade'] as num?)?.toDouble() ?? 0,
    sono: (dadosGrafico['sono'] as num?)?.toDouble() ?? 0,
    produtividade: (dadosGrafico['produtividade'] as num?)?.toDouble(),
    atividadeSignificativa: entrada['atividadeSignificativa']?.toString(),
    bemEstar: (entrada['bemEstar'] as num).round(),
    principalPonto: entrada['principalPonto']?.toString() ?? '',
    corValor: cor is Color ? cor.toARGB32() : 0xFFE8DCD4,
    humorFrequencia: entrada['humorFrequencia']?.toString() ?? '',
    interesseFrequencia: entrada['interesseFrequencia']?.toString() ?? '',
    exaustaoBurnout: entrada['exaustaoBurnout']?.toString() ?? '',
    distanciamentoBurnout: entrada['distanciamentoBurnout']?.toString() ?? '',
    operacaoId: entrada['operacaoId'] as String?,
  );

  // Recarrega a lista em memória para refletir o novo registro.
  await carregarHistorico();
}

/// Limpa todo o histórico salvo (memória + SQLite) do usuário
/// atualmente logado.
Future<void> limparHistorico() async {
  final usuarioId = await _usuarioIdAtual();
  if (usuarioId != null) {
    await DatabaseService.instance.limparCheckins(usuarioId);
  }
  // Não apagar o cache de uma conta que entrou durante a operação.
  if (await _usuarioIdAtual() == usuarioId) {
    ++_versaoCarregamentoHistorico;
    historicoGlobal = [];
  }
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
