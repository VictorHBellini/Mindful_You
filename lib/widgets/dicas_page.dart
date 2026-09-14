import 'package:flutter/material.dart';

import 'package:mindful_you/widgets/responsive_center.dart';

class DicasTela extends StatelessWidget {
  const DicasTela({super.key});

  static const List<Map<String, dynamic>> _dicas = [
    {
      'icone': Icons.air_rounded,
      'titulo': 'Respiração 4-7-8',
      'categoria': 'Redução de Ansiedade',
      'descricao':
          'Inspire pelo nariz por 4 segundos, segure o ar por 7 segundos e expire suavemente pela boca por 8 segundos. Repita 4 ciclos.',
      'tempo': '2 min',
      'cor': Color(0xFF9575CD),
    },
    {
      'icone': Icons.self_improvement_rounded,
      'titulo': 'Pausa de Atenção Plena',
      'categoria': 'Foco & Presença',
      'descricao':
          'Feche os olhos por um minuto. Traga a atenção para os sons ao seu redor, sem julgá-los, e depois para o fluxo natural da sua respiração.',
      'tempo': '3 min',
      'cor': Color(0xFFC89494),
    },
    {
      'icone': Icons.bedtime_outlined,
      'titulo': 'Higiene do Sono',
      'categoria': 'Descanso Restaurador',
      'descricao':
          'Evite telas brilhantes 30 minutos antes de dormir. Deixe o quarto em temperatura amena e adote uma iluminação mais quente e suave.',
      'tempo': 'Noturno',
      'cor': Color(0xFF5C8BD6),
    },
    {
      'icone': Icons.nature_people_rounded,
      'titulo': 'Técnica de Aterramento 5-4-3-2-1',
      'categoria': 'Alívio Imediato',
      'descricao':
          'Identifique ao seu redor: 5 coisas que pode ver, 4 que pode tocar, 3 que pode ouvir, 2 que pode cheirar e 1 que pode saborear.',
      'tempo': '5 min',
      'cor': Color(0xFF6E9B7B),
    },
    {
      'icone': Icons.favorite_outline_rounded,
      'titulo': 'Check-in Emocional Sem Julgamento',
      'categoria': 'Autocompaixão',
      'descricao':
          'Lembre-se: não há emoções "erradas". Reconheça o cansaço ou a tensão como sinais do seu corpo pedindo gentileza e acolhimento.',
      'tempo': 'Diário',
      'cor': Color(0xFFE8B46D),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Dicas & Bem-estar',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
      ),

      // ============================================================
      // CONTEÚDO
      // ============================================================

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ResponsiveCenter(
            maxWidth: 760,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // TÍTULO
                // ==================================================

                Text(
                  'Práticas para o seu dia 🌱',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 6),

                // ==================================================
                // SUBTÍTULO
                // ==================================================

                Text(
                  'Pequenas pausas e exercícios para renovar sua energia e acalmar a mente.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // LISTA DE DICAS
                // ==================================================

                ...List.generate(
                  _dicas.length,
                  (index) {
                    final dica = _dicas[index];
                    final cor = dica['cor'] as Color;

                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: 16,
                      ),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.18 : 0.04,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ========================================
                          // ÍCONE
                          // ========================================

                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: cor.withValues(
                                alpha: isDark ? 0.20 : 0.14,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              dica['icone'] as IconData,
                              color: cor,
                              size: 26,
                            ),
                          ),

                          const SizedBox(width: 14),

                          // ========================================
                          // CONTEÚDO
                          // ========================================

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ==================================
                                // CATEGORIA + TEMPO
                                // ==================================

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(
                                                  0xFF302827,
                                                )
                                              : const Color(
                                                  0xFFF3ECE8,
                                                ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          dica['categoria'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? const Color(
                                                    0xFFD5A6A6,
                                                  )
                                                : const Color(
                                                    0xFF80675C,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dica['tempo'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // ==================================
                                // TÍTULO DA DICA
                                // ==================================

                                Text(
                                  dica['titulo'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colors.onSurface,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // ==================================
                                // DESCRIÇÃO
                                // ==================================

                                Text(
                                  dica['descricao'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
