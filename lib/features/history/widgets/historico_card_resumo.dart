import 'package:flutter/material.dart';

// Cartão visual do resumo; os indicadores são calculados pela tela.
class HistoricoCardResumo extends StatelessWidget {
  final int totalCheckins;
  final int sequencia;
  final int mediaBemEstar;

  const HistoricoCardResumo({
    super.key,
    required this.totalCheckins,
    required this.sequencia,
    required this.mediaBemEstar,
  });

  static const Color kMarrom = Color(0xFF40352F);
  static const Color kMarromClaro = Color(0xFF80675C);
  static const Color kBege = Color(0xFFE8DCD4);
  static const Color kBegeClaro = Color(0xFFF1E8E1);
  static const Color kCinza = Color(0xFF8A7B73);

  @override
  Widget build(BuildContext context) {
    return _cardResumo(
      totalCheckins: totalCheckins,
      sequencia: sequencia,
      mediaBemEstar: mediaBemEstar,
    );
  }

  Widget _cardResumo({
    required int totalCheckins,
    required int sequencia,
    required int mediaBemEstar,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kBege,
            kBegeClaro,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: kMarromClaro,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sua jornada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kMarrom,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Um resumo do seu progresso',
                    style: TextStyle(
                      fontSize: 12,
                      color: kCinza,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _indicador(
                  valor: '$totalCheckins',
                  titulo: 'Check-ins',
                  icone: Icons.favorite_rounded,
                ),
              ),
              _divisor(),
              Expanded(
                child: _indicador(
                  valor: '$sequencia',
                  titulo: 'Dias seguidos',
                  icone: Icons.local_fire_department_rounded,
                ),
              ),
              _divisor(),
              Expanded(
                child: _indicador(
                  valor: '$mediaBemEstar%',
                  titulo: 'Bem-estar',
                  icone: Icons.auto_graph_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _indicador({
    required String valor,
    required String titulo,
    required IconData icone,
  }) {
    return Column(
      children: [
        Icon(
          icone,
          size: 19,
          color: kMarromClaro,
        ),
        const SizedBox(height: 6),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: kMarrom,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            color: kCinza,
          ),
        ),
      ],
    );
  }

  Widget _divisor() {
    return Container(
      height: 48,
      width: 1,
      color: Colors.black.withValues(alpha: 0.08),
    );
  }

  // ============================================================
  // CARD EVOLUÇÃO
}
