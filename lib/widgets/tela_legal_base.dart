import 'package:flutter/material.dart';

// ======================================================================
// WIDGET BASE - TELAS LEGAIS (Termos de Uso / Política de Privacidade)
// ======================================================================
//
// Layout compartilhado entre `termos_uso_tela.dart` e
// `politica_privacidade_tela.dart`.
//
// Suporte completo aos temas claro e escuro do Mindful You,
// mantendo a identidade visual terracota/bege.
// ======================================================================

class SecaoTextoLegal {
  final String titulo;
  final String corpo;

  const SecaoTextoLegal({
    required this.titulo,
    required this.corpo,
  });
}

class TelaLegalBase extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String ultimaAtualizacao;
  final IconData icone;
  final String introducao;
  final List<SecaoTextoLegal> secoes;

  const TelaLegalBase({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.ultimaAtualizacao,
    required this.icone,
    required this.introducao,
    required this.secoes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    // ==============================================================
    // CORES ADAPTATIVAS
    // ==============================================================

    final backgroundColor =
        isDark ? const Color(0xFF191716) : const Color(0xFFF8F5F2);

    final headerStartColor =
        isDark ? const Color(0xFF302827) : const Color(0xFFE8DCD4);

    final headerEndColor =
        isDark ? const Color(0xFF252120) : const Color(0xFFF1E8E1);

    final headerTextColor =
        isDark ? const Color(0xFFF3ECE8) : const Color(0xFF40352F);

    final accentColor =
        isDark ? const Color(0xFFD5A6A6) : const Color(0xFF8D6E63);

    final secondaryTextColor =
        isDark ? const Color(0xFFB0A19A) : const Color(0xFF9A8C84);

    final introBackgroundColor =
        isDark ? const Color(0xFF252120) : Colors.white;

    final introBorderColor =
        isDark ? const Color(0xFF3A3330) : const Color(0xFFE9E0DB);

    final bodyTextColor =
        isDark ? const Color(0xFFD6CCC7) : const Color(0xFF6B5D55);

    final sectionTitleColor =
        isDark ? const Color(0xFFF3ECE8) : const Color(0xFF40352F);

    final footerTextColor =
        isDark ? const Color(0xFFBFAFA8) : const Color(0xFF80675C);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ======================================================
          // CABEÇALHO
          // ======================================================

          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            backgroundColor: headerStartColor,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: headerTextColor,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 56,
                bottom: 16,
              ),
              title: Text(
                titulo,
                style: TextStyle(
                  color: headerTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      headerStartColor,
                      headerEndColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 22,
                      top: 10,
                    ),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFD5A6A6).withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icone,
                        color: isDark
                            ? const Color(0xFFD5A6A6)
                            : const Color(0xFF8D6E63),
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ======================================================
          // CONTEÚDO
          // ======================================================

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                22,
                20,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // NOME DO APP
                  // ==================================================

                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFD5A6A6)
                          : const Color(0xFF8D6E63),
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ==================================================
                  // DATA DE ATUALIZAÇÃO
                  // ==================================================

                  Text(
                    "Última atualização: $ultimaAtualizacao",
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // INTRODUÇÃO
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: introBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: introBorderColor,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      introducao,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: isDark
                            ? const Color(0xFFD6CCC7)
                            : const Color(0xFF5A4D46),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // SEÇÕES NUMERADAS
                  // ==================================================

                  ...secoes.map(
                    (secao) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            secao.titulo,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: sectionTitleColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            secao.corpo,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.55,
                              color: bodyTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ==================================================
                  // RODAPÉ
                  // ==================================================

                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: isDark
                              ? const Color(0xFFD5A6A6)
                              : const Color(0xFFC89494),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Mindful You",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: footerTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
