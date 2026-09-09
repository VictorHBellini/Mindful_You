import 'package:flutter/material.dart';

// ======================================================================
// WIDGET BASE - TELAS LEGAIS (Termos de Uso / Política de Privacidade)
// ======================================================================
//
// Layout compartilhado entre `termos_uso_tela.dart` e
// `politica_privacidade_tela.dart`, mantendo a mesma linguagem visual
// usada nas demais telas do Mindful You (paleta terracota/bege,
// cabeçalho com gradiente e cantos arredondados).
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ======================================================
          // CABEÇALHO
          // ======================================================
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            backgroundColor: const Color(0xFFE8DCD4),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF40352F),
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                titulo,
                style: const TextStyle(
                  color: Color(0xFF40352F),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFE8DCD4),
                      Color(0xFFF1E8E1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 22, top: 10),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icone,
                        color: const Color(0xFF8D6E63),
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
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NOME DO APP
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8D6E63),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // DATA DE ATUALIZAÇÃO
                  Text(
                    "Última atualização: $ultimaAtualizacao",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A8C84),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // INTRODUÇÃO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE9E0DB),
                      ),
                    ),
                    child: Text(
                      introducao,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: Color(0xFF5A4D46),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // SEÇÕES NUMERADAS
                  ...secoes.map(
                    (secao) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            secao.titulo,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF40352F),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            secao.corpo,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.55,
                              color: Color(0xFF6B5D55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // RODAPÉ
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: Color(0xFFC89494),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Mindful You",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF80675C),
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
