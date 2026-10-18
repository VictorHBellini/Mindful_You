import 'package:flutter/material.dart';
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

    final mediaBemEstar = _calcularMediaBemEstar(historicos);

    final sequencia = _calcularSequencia(historicos);

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
                          _estadoVazio(context)
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
                            _cardSinalAtencao(),
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

                          _cardUltimoCheckin(
                            context,
                            ultimo!,
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
                              return _historicoCard(
                                context,
                                historicos[index],
                                index,
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
  // TÍTULO
  // ============================================================

  // ============================================================

  // ============================================================

  // ============================================================
  // SINAL DE ATENÇÃO (humor e energia)
  // ============================================================
  //
  // Aparece quando `possuiPadraoRecenteDeAtencao` (em
  // `historico_global.dart`) identifica que, nos últimos check-ins,
  // sinais de humor ou burnout apareceram com frequência. É um apoio
  // visual para notar padrões — não é uma pontuação clínica validada
  // nem substitui a avaliação do terapeuta, e o texto deixa isso
  // claro.

  Widget _cardSinalAtencao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E1D8),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: Color(0xFF9A6B4C),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Um sinal para observar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kMarrom,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nos seus check-ins mais recentes, sinais de humor '
                  'ou cansaço emocional apareceram com frequência. '
                  'Pode ser um bom assunto para trazer para a sua '
                  'próxima conversa com seu terapeuta.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: kMarromClaro,
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
  // GRÁFICO
  // ============================================================

  // ============================================================
  // ÚLTIMO CHECK-IN
  // ============================================================

  Widget _cardUltimoCheckin(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final valor = _getBemEstar(item);

    final cor = _getCor(item);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/relatorio',
          arguments: item,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cor.withValues(alpha: 0.90),
              cor.withValues(alpha: 0.70),
            ],
          ),
          borderRadius: BorderRadius.circular(23),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['data']?.toString() ?? 'Data não informada',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    if (contarSinaisElevados(item) > 0) ...[
                      const Icon(
                        Icons.notifications_active_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$valor%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item['status']?.toString() ?? 'Check-in realizado',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 17,
                  color: Colors.white,
                ),
                const SizedBox(width: 7),
                const Text(
                  'Ver relatório completo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD HISTÓRICO
  // ============================================================

  Widget _historicoCard(
    BuildContext context,
    Map<String, dynamic> item,
    int index,
  ) {
    final valor = _getBemEstar(item);

    final cor = _getCor(item);

    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: 0,
        end: 1,
      ),
      duration: Duration(
        milliseconds: 300 + (index * 70),
      ),
      curve: Curves.easeOut,
      builder: (
        context,
        animation,
        child,
      ) {
        return Opacity(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(
              0,
              10 * (1 - animation),
            ),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/relatorio',
            arguments: item,
          );
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(
            bottom: 12,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 67,
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['data']?.toString() ?? 'Data não informada',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: kMarrom,
                            ),
                          ),
                        ),
                        if (contarSinaisElevados(item) > 0) ...[
                          const Icon(
                            Icons.notifications_active_outlined,
                            size: 14,
                            color: Color(0xFF9A6B4C),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kRosa.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(
                              9,
                            ),
                          ),
                          child: Text(
                            '$valor%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kMarromClaro,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['status']?.toString() ?? 'Check-in realizado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: kCinza,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 13,
                          color: kMarromClaro.withValues(
                            alpha: 0.75,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Ver relatório',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: kMarromClaro.withValues(
                              alpha: 0.80,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 27,
                color: Color(0xFFC8BEB8),
              ),
            ],
          ),
        ),
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
  // ESTADO VAZIO
  // ============================================================

  Widget _estadoVazio(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: kRosa.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_rounded,
              size: 42,
              color: kRosa,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sua jornada começa aqui 🌱',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kMarrom,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Faça seu primeiro check-in e comece '
            'a acompanhar como você está se '
            'sentindo ao longo do tempo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: kCinza,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/questionario',
                );
              },
              icon: const Icon(
                Icons.favorite_outline_rounded,
              ),
              label: const Text(
                'Fazer meu primeiro check-in',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D6E63),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                ),
              ),
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
  // MÉDIA
  // ============================================================

  int _calcularMediaBemEstar(
    List<Map<String, dynamic>> historicos,
  ) {
    return calcularMediaBemEstar(historicos);
  }

  // ============================================================
  // SEQUÊNCIA
  // ============================================================
  //
  // BUG CORRIGIDO: este método lia um campo 'sequencia' que nunca era
  // gravado em lugar nenhum e, na prática, sempre caía num valor
  // aproximado (`min(total de check-ins, 7)`), diferente do número
  // mostrado na tela de Perfil. Agora as duas telas usam a mesma função
  // `calcularSequenciaAtual`, que calcula dias consecutivos reais a
  // partir da data de cada check-in.

  int _calcularSequencia(
    List<Map<String, dynamic>> historicos,
  ) {
    return calcularSequenciaAtual(historicos);
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
