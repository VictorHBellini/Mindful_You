import 'package:mindful_you/features/history/widgets/historico_tema.dart';
import 'package:flutter/material.dart';
import 'package:mindful_you/features/history/historico_global.dart';

/// Cartão visual de um registro; não altera nem persiste dados.
class HistoricoCardRegistro extends StatelessWidget {
  const HistoricoCardRegistro({
    super.key,
    required this.item,
    required this.index,
    required this.valor,
    required this.cor,
  });

  final Map<String, dynamic> item;
  final int index;
  final int valor;
  final Color cor;

  static const Color kMarrom = Color(0xFF40352F);
  static const Color kMarromClaro = Color(0xFF80675C);
  static const Color kRosa = Color(0xFFC89494);
  static const Color kCinza = Color(0xFF8A7B73);

  @override
  Widget build(BuildContext context) {
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
            color: HistoricoTema.cartao(context),
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
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['data']?.toString() ?? 'Data não informada',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: HistoricoTema.texto(context),
                            ),
                          ),
                        ),
                        if (contarSinaisElevados(item) > 0) ...[
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 14,
                            color: HistoricoTema.destaque(context),
                          ),
                          SizedBox(width: 5),
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
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: HistoricoTema.destaque(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      item['status']?.toString() ?? 'Check-in realizado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: HistoricoTema.secundario(context),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 13,
                          color: HistoricoTema.destaque(context).withValues(
                            alpha: 0.75,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Ver relatório',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: HistoricoTema.destaque(context).withValues(
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
              SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 27,
                color: HistoricoTema.secundario(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
