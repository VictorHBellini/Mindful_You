import 'package:flutter/material.dart';

/// Aviso visual de padrões recentes; a decisão de exibi-lo fica na tela.
class HistoricoCardSinalAtencao extends StatelessWidget {
  const HistoricoCardSinalAtencao({super.key});

  static const Color kMarrom = Color(0xFF40352F);
  static const Color kMarromClaro = Color(0xFF80675C);

  @override
  Widget build(BuildContext context) {
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
}
