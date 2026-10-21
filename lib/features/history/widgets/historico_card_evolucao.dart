import 'package:mindful_you/features/history/widgets/historico_tema.dart';
import 'package:flutter/material.dart';

/// Cartão de evolução do bem-estar; cálculo realizado pela tela.
class HistoricoCardEvolucao extends StatelessWidget {
  final int evolucao;

  const HistoricoCardEvolucao({super.key, required this.evolucao});

  static const Color kMarrom = Color(0xFF40352F);
  static const Color kMarromClaro = Color(0xFF80675C);
  static const Color kRosa = Color(0xFFC89494);
  static const Color kCinza = Color(0xFF8A7B73);
  static const Color kVerde = Color(0xFF78927A);

  @override
  Widget build(BuildContext context) {
    final positiva = evolucao > 0;
    final neutra = evolucao == 0;

    String titulo;
    String descricao;
    IconData icone;

    if (neutra) {
      titulo = 'Seu bem-estar está estável';

      descricao = 'Seus registros mostram pouca variação '
          'entre os períodos analisados.';

      icone = Icons.horizontal_rule_rounded;
    } else if (positiva) {
      titulo = 'Seu bem-estar está evoluindo';

      descricao = 'Comparando seus registros, identificamos '
          'uma diferença positiva entre o primeiro e o último registro.';

      icone = Icons.trending_up_rounded;
    } else {
      titulo = 'Seu bem-estar apresentou uma queda';

      descricao = 'Seus últimos registros mostram uma '
          'diferença negativa entre o primeiro e o último registro. Observe como você '
          'tem se sentido nos próximos dias.';

      icone = Icons.trending_down_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: HistoricoTema.cartao(context),
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
              color: positiva
                  ? kVerde.withValues(alpha: 0.12)
                  : kRosa.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icone,
              color: positiva ? kVerde : kRosa,
              size: 25,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: HistoricoTema.texto(context),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  descricao,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: HistoricoTema.secundario(context),
                    height: 1.45,
                  ),
                ),
                if (!neutra) ...[
                  SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: positiva
                          ? kVerde.withValues(alpha: 0.10)
                          : kRosa.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      positiva
                          ? '+$evolucao p.p. de variação'
                          : '$evolucao p.p. de variação',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: positiva ? kVerde : kMarromClaro,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
