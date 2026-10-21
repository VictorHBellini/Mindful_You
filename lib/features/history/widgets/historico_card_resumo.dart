import 'package:mindful_you/features/history/widgets/historico_tema.dart';
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
      context: context,
    );
  }

  Widget _cardResumo({
    required BuildContext context,
    required int totalCheckins,
    required int sequencia,
    required int mediaBemEstar,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? const [Color(0xFF332A2A), Color(0xFF251F20)]
              : const [kBege, kBegeClaro],
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
                  color: HistoricoTema.iconeFundo(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.spa_rounded,
                  color: HistoricoTema.destaque(context),
                  size: 23,
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sua jornada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: HistoricoTema.texto(context),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Um resumo do seu progresso',
                    style: TextStyle(
                      fontSize: 12,
                      color: HistoricoTema.secundario(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _indicador(
                  context: context,
                  valor: '$totalCheckins',
                  titulo: 'Check-ins',
                  icone: Icons.favorite_rounded,
                ),
              ),
              _divisor(context),
              Expanded(
                child: _indicador(
                  context: context,
                  valor: '$sequencia',
                  titulo: 'Dias seguidos',
                  icone: Icons.local_fire_department_rounded,
                ),
              ),
              _divisor(context),
              Expanded(
                child: _indicador(
                  context: context,
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
    required BuildContext context,
    required String valor,
    required String titulo,
    required IconData icone,
  }) {
    return Column(
      children: [
        Icon(
          icone,
          size: 19,
          color: HistoricoTema.destaque(context),
        ),
        SizedBox(height: 6),
        Text(
          valor,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: HistoricoTema.texto(context),
          ),
        ),
        SizedBox(height: 2),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            color: HistoricoTema.secundario(context),
          ),
        ),
      ],
    );
  }

  Widget _divisor(BuildContext context) {
    return Container(
      height: 48,
      width: 1,
      color: HistoricoTema.escuro(context)
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.08),
    );
  }
}
