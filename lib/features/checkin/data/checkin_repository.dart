import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindful_you/services/database_service.dart';

// Camada de persistência do check-in. Não gerencia cache ou navegação.
Future<int?> usuarioIdAtualCheckin() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('usuarioId');
}

Map<String, dynamic> linhaParaEntradaCheckin(Map<String, dynamic> linha) {
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

Future<List<Map<String, dynamic>>> listarEntradasCheckin(int usuarioId) async {
  final linhas = await DatabaseService.instance.listarCheckins(usuarioId);
  return linhas.map(linhaParaEntradaCheckin).toList();
}

Future<void> inserirEntradaCheckin(
    int usuarioId, Map<String, dynamic> entrada) async {
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
}

Future<void> limparEntradasCheckin(int usuarioId) async {
  await DatabaseService.instance.limparCheckins(usuarioId);
}
