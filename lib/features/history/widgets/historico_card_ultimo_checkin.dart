import 'package:flutter/material.dart';

/// Apresentação do check-in mais recente, com navegação ao relatório.
class HistoricoCardUltimoCheckin extends StatelessWidget {
  final Map<String, dynamic> item;
  final int valor;
  final Color cor;
  final bool possuiSinaisElevados;

  const HistoricoCardUltimoCheckin({
    super.key,
    required this.item,
    required this.valor,
    required this.cor,
    required this.possuiSinaisElevados,
  });

  @override
  Widget build(BuildContext context) {
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
                    if (possuiSinaisElevados) ...[
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
}
