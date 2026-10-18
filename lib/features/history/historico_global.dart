import 'package:mindful_you/features/checkin/data/checkin_repository.dart';

export 'package:mindful_you/features/checkin/domain/historico_calculos.dart';

// Cache compatível com as telas atuais. O SQLite permanece a fonte dos dados.
List<Map<String, dynamic>> historicoGlobal = [];

// Descarta carregamentos antigos quando o usuário muda ou outro load começa.
int _versaoCarregamentoHistorico = 0;

/// Invalida leituras pendentes e remove os dados da sessão anterior.
/// Deve ser chamada quando a identidade local é encerrada ou trocada.
void invalidarCacheHistorico() {
  ++_versaoCarregamentoHistorico;
  historicoGlobal = [];
}


Future<void> carregarHistorico() async {
  final versao = ++_versaoCarregamentoHistorico;
  final usuarioId = await usuarioIdAtualCheckin();
  if (versao != _versaoCarregamentoHistorico) return;

  if (usuarioId == null) {
    historicoGlobal = [];
    return;
  }

  final entradas = await listarEntradasCheckin(usuarioId);
  if (versao != _versaoCarregamentoHistorico) return;
  if (await usuarioIdAtualCheckin() != usuarioId) {
    historicoGlobal = [];
    return;
  }
  if (versao != _versaoCarregamentoHistorico) return;
  historicoGlobal = entradas;
}

Future<void> adicionarHistorico(Map<String, dynamic> entrada) async {
  final usuarioId = await usuarioIdAtualCheckin();
  if (usuarioId == null) return;

  await inserirEntradaCheckin(usuarioId, entrada);
  await carregarHistorico();
}

Future<void> limparHistorico() async {
  final usuarioId = await usuarioIdAtualCheckin();
  if (usuarioId != null) {
    await limparEntradasCheckin(usuarioId);
  }
  if (await usuarioIdAtualCheckin() == usuarioId) {
    ++_versaoCarregamentoHistorico;
    historicoGlobal = [];
  }
}
