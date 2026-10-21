import 'package:flutter/material.dart';

/// Estado apresentado quando ainda não há check-ins no Histórico.
class HistoricoEstadoVazio extends StatelessWidget {
  const HistoricoEstadoVazio({super.key});

  static const Color _kRosa = Color(0xFFC89494);
  static const Color _kMarrom = Color(0xFF40352F);
  static const Color _kCinza = Color(0xFF8A7B73);

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final tituloCor = escuro ? const Color(0xFFF1E8E4) : _kMarrom;
    final textoCor = escuro ? const Color(0xFFC9B7B2) : _kCinza;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: escuro ? const Color(0xFF241F1F) : Colors.white,
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
              color: _kRosa.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_rounded,
              size: 42,
              color: _kRosa,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sua jornada começa aqui 🌱',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: tituloCor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Faça seu primeiro check-in e comece '
            'a acompanhar como você está se '
            'sentindo ao longo do tempo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textoCor,
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
                backgroundColor:
                    escuro ? const Color(0xFFD9ABA9) : const Color(0xFF8D6E63),
                foregroundColor:
                    escuro ? const Color(0xFF241F1F) : Colors.white,
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
}
