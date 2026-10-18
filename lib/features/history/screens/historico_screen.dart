import 'package:flutter/material.dart';
import 'package:mindful_you/features/history/widgets/historico_card_sinal_atencao.dart';
import 'package:mindful_you/features/history/widgets/historico_card_ultimo_checkin.dart';
import 'package:mindful_you/features/history/widgets/historico_estado_vazio.dart';
import 'package:mindful_you/features/history/widgets/historico_card_registro.dart';
import 'package:mindful_you/features/history/widgets/historico_grafico_evolucao.dart';
import 'package:mindful_you/features/history/widgets/historico_titulos.dart';
import 'package:mindful_you/features/history/widgets/historico_card_resumo.dart';
import 'package:mindful_you/features/history/widgets/historico_card_evolucao.dart';
import 'package:mindful_you/features/history/historico_global.dart';
import 'package:mindful_you/core/widgets/menu_lateral_widget.dart';
import 'package:mindful_you/widgets/avatar_perfil.dart';

// ============================================================
// CORES GLOBAIS DA TELA
// ============================================================

const Color kFundo = Color(0xFFF8F5F2);
const Color kMarrom = Color(0xFF40352F);
const Color kMarromClaro = Color(0xFF80675C);
const Color kRosa = Color(0xFFC89494);
const Color kBege = Color(0xFFE8DCD4);
const Color kBegeClaro = Color(0xFFF1E8E1);
const Color kCinza = Color(0xFF8A7B73);
const Color kVerde = Color(0xFF78927A);

// ============================================================
// TELA HISTÓRICO
// ============================================================

class HistoricoTela extends StatefulWidget {
  const HistoricoTela({super.key});

  @override
  State<HistoricoTela> createState() => _HistoricoTelaState();
}

class _HistoricoTelaState extends State<HistoricoTela>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _animacaoFundo;

  late Animation<double> _movimentoX;
  late Animation<double> _movimentoY;
  late Animation<double> _escala;

  @override
  void initState() {
    super.initState();

    // Garante que `historicoGlobal` reflita o usuário atualmente
    // logado mesmo se esta tela for a primeira a precisar do
    // histórico nesta sessão (por exemplo, após um hot restart).
    _carregarHistorico();

    // ==========================================================
    // ANIMAÇÃO DO FUNDO
    // ==========================================================

    _animacaoFundo = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    _movimentoX = Tween<double>(
      begin: -7,
      end: 7,
    ).animate(
      CurvedAnimation(
        parent: _animacaoFundo,
        curve: Curves.easeInOut,
      ),
    );

    _movimentoY = Tween<double>(
      begin: -4,
      end: 6,
    ).animate(
      CurvedAnimation(
        parent: _animacaoFundo,
        curve: Curves.easeInOut,
      ),
    );

    _escala = Tween<double>(
      begin: 0.985,
      end: 1.025,
    ).animate(
      CurvedAnimation(
        parent: _animacaoFundo,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animacaoFundo.dispose();
    super.dispose();
  }

  Future<void> _carregarHistorico() async {
    await carregarHistorico();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final historicos = [
      ...historicoGlobal.reversed,
    ];

    final totalCheckins = historicos.length;

    final mediaBemEstar = calcularMediaBemEstar(historicos);

    final sequencia = calcularSequenciaAtual(historicos);

    final ultimo = historicos.isNotEmpty ? historicos.first : null;

    final evolucao = _calcularEvolucao(historicos);

    final possuiSinalRecente = possuiPadraoRecenteDeAtencao(historicos);

    return Scaffold(
      key: scaffoldKey,
      drawer: const MenuLateral(),
      backgroundColor: kFundo,
      body: SafeArea(
        child: Stack(
          children: [
            // ==================================================
            // IMAGEM DE FUNDO ANIMADA
            // ==================================================

            Positioned(
              top: -160,
              right: -190,
              child: AnimatedBuilder(
                animation: _animacaoFundo,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _movimentoX.value,
                      _movimentoY.value,
                    ),
                    child: Transform.scale(
                      scale: _escala.value,
                      child: child,
                    ),
                  );
                },
                child: Opacity(
                  opacity: 0.65,
                  child: Image.asset(
                    'assets/img/6.png',
                    width: 460,
                    height: 360,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // ==================================================
            // CONTEÚDO
            // ==================================================

            Column(
              children: [
                _cabecalho(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      22,
                      10,
                      22,
                      35,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const HistoricoTitulo(),
                        const SizedBox(height: 24),
                        if (historicos.isEmpty)
                          const HistoricoEstadoVazio()
                        else ...[
                          // ======================================
                          // RESUMO
                          // ======================================

                          HistoricoCardResumo(
                            totalCheckins: totalCheckins,
                            sequencia: sequencia,
                            mediaBemEstar: mediaBemEstar,
                          ),

                          const SizedBox(height: 24),

                          // ======================================
                          // EVOLUÇÃO
                          // ======================================

                          if (historicos.length >= 2) ...[
                            HistoricoTituloSecao(
                              'Como você está ultimamente?',
                              'Uma visão geral da sua evolução',
                            ),
                            const SizedBox(height: 12),
                            HistoricoCardEvolucao(
                              evolucao: evolucao,
                            ),
                            const SizedBox(height: 28),
                            HistoricoTituloSecao(
                              'Sua evolução',
                              'Veja seus últimos registros',
                            ),
                            const SizedBox(height: 12),
                            HistoricoGraficoEvolucao(
                                registros: historicos
                                    .take(7)
                                    .toList()
                                    .reversed
                                    .toList(),
                                dados: historicos
                                    .take(7)
                                    .toList()
                                    .reversed
                                    .map(_getBemEstar)
                                    .toList()),
                            const SizedBox(height: 28),
                          ],

                          // ======================================
                          // SINAIS DE ATENÇÃO RECENTES
                          // ======================================

                          if (possuiSinalRecente) ...[
                            const HistoricoCardSinalAtencao(),
                            const SizedBox(height: 28),
                          ],

                          // ======================================
                          // ÚLTIMO CHECK-IN
                          // ======================================

                          HistoricoTituloSecao(
                            'Seu último check-in',
                            'Seu momento mais recente',
                          ),

                          const SizedBox(height: 12),

                          HistoricoCardUltimoCheckin(
                            item: ultimo!,
                            valor: _getBemEstar(ultimo),
                            cor: _getCor(ultimo),
                            possuiSinaisElevados:
                                contarSinaisElevados(ultimo) > 0,
                          ),

                          const SizedBox(height: 28),

                          // ======================================
                          // HISTÓRICO
                          // ======================================

                          HistoricoTituloSecao(
                            'Seus check-ins',
                            'Toque em um registro para ver o relatório',
                          ),

                          const SizedBox(height: 14),

                          ...List.generate(
                            historicos.length,
                            (index) {
                              return HistoricoCardRegistro(
                                item: historicos[index],
                                index: index,
                                valor:
                                    obterBemEstarDoRegistro(historicos[index]),
                                cor: _getCor(historicos[index]),
                              );
                            },
                          ),

                          if (historicos.length >= 3) ...[
                            const SizedBox(height: 10),
                            _cardInsight(historicos),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CABEÇALHO
  // ============================================================

  Widget _cabecalho(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        8,
        18,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  scaffoldKey.currentState?.openDrawer();
                },
                icon: const Icon(
                  Icons.menu_rounded,
                  size: 31,
                  color: Color(0xFFB5ACA4),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/inicial',
                  );
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 21,
                  color: Color(0xFFB5ACA4),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/perfil',
              );
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const AvatarPerfil(
                radius: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INSIGHT
  // ============================================================

  Widget _cardInsight(
    List<Map<String, dynamic>> historicos,
  ) {
    final recentes = historicos.take(3).map(_getBemEstar).toList();

    final mediaRecente = recentes.isEmpty
        ? 0
        : (recentes.reduce(
                  (a, b) => a + b,
                ) /
                recentes.length)
            .round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: kBegeClaro,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: kMarromClaro,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Um pequeno insight',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kMarrom,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nos seus últimos 3 check-ins, '
                  'a média de bem-estar foi '
                  '$mediaRecente%. Continue observando '
                  'como pequenos momentos do seu '
                  'dia podem influenciar você.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: kCinza,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LEITURA DO BEM-ESTAR
  // ============================================================
  //
  // BUG CORRIGIDO: esta lógica foi movida para `historico_global.dart`
  // (`obterBemEstarDoRegistro`), de onde a tela de Perfil também passou
  // a lê-la. Antes, cada tela calculava o "bem-estar" de um jeito
  // diferente e mostrava números diferentes para o mesmo usuário.

  int _getBemEstar(
    Map<String, dynamic> item,
  ) {
    return obterBemEstarDoRegistro(item);
  }

  // ============================================================
  // EVOLUÇÃO
  // ============================================================

  int _calcularEvolucao(
    List<Map<String, dynamic>> historicos,
  ) {
    if (historicos.length < 2) {
      return 0;
    }

    final atual = _getBemEstar(
      historicos.first,
    );

    final anterior = _getBemEstar(
      historicos.last,
    );

    return atual - anterior;
  }

  // ============================================================
  // COR DO HISTÓRICO
  // ============================================================

  Color _getCor(
    Map<String, dynamic> item,
  ) {
    if (item['cor'] is Color) {
      return item['cor'] as Color;
    }

    if (item['corValor'] is int) {
      return Color(
        item['corValor'] as int,
      );
    }

    return kRosa;
  }
}
