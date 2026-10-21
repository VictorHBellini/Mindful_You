import 'package:mindful_you/features/history/widgets/historico_tema.dart';
import 'package:flutter/material.dart';

// Apenas apresentação: os valores de bem-estar são calculados pela tela.
class HistoricoGraficoEvolucao extends StatelessWidget {
  final List<Map<String, dynamic>> registros;
  final List<int> dados;

  const HistoricoGraficoEvolucao({
    super.key,
    required this.registros,
    required this.dados,
  });

  static const Color kMarrom = Color(0xFF40352F);
  static const Color kRosa = Color(0xFFC89494);
  static const Color kCinza = Color(0xFF8A7B73);

  @override
  Widget build(BuildContext context) {
    String rotuloData(Map<String, dynamic> registro) {
      final data = DateTime.tryParse(registro['dataIso']?.toString() ?? '');
      if (data == null) return 'Sem data';
      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
    }

    return Container(
      width: double.infinity,
      height: 260,
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        12,
      ),
      decoration: BoxDecoration(
        color: HistoricoTema.cartao(context),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bem-estar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HistoricoTema.texto(context),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: kRosa,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'últimos registros',
                    style: TextStyle(
                      fontSize: 10,
                      color: HistoricoTema.secundario(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('100',
                          style: TextStyle(fontSize: 10, color: kCinza)),
                      Text('50', style: TextStyle(fontSize: 10, color: kCinza)),
                      Text('0', style: TextStyle(fontSize: 10, color: kCinza)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    child: CustomPaint(
                      painter: _GraficoHistoricoPainter(
                          dados: dados, escuro: HistoricoTema.escuro(context)),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 38, right: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(rotuloData(registros.first),
                    style: TextStyle(fontSize: 10, color: kCinza)),
                Text(rotuloData(registros.last),
                    style: TextStyle(fontSize: 10, color: kCinza)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GraficoHistoricoPainter extends CustomPainter {
  final List<int> dados;
  final bool escuro;

  _GraficoHistoricoPainter({
    required this.dados,
    required this.escuro,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (dados.isEmpty) {
      return;
    }

    final double largura = size.width;
    final double altura = size.height;

    // ==========================================================
    // LINHA
    // ==========================================================

    final paintLinha = Paint()
      ..color = HistoricoGraficoEvolucao.kRosa
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ==========================================================
    // PONTOS
    // ==========================================================

    final paintPonto = Paint()
      ..color = HistoricoGraficoEvolucao.kRosa
      ..style = PaintingStyle.fill;

    // ==========================================================
    // GRADE
    // ==========================================================

    final paintGrade = Paint()
      ..color = (escuro ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final double y = altura * (i / 3);

      canvas.drawLine(
        Offset(0, y),
        Offset(largura, y),
        paintGrade,
      );
    }

    // ==========================================================
    // CAMINHO DO GRÁFICO
    // ==========================================================

    final path = Path();

    final double espacamento =
        dados.length == 1 ? 0 : largura / (dados.length - 1);

    for (int i = 0; i < dados.length; i++) {
      final double x = dados.length == 1 ? largura / 2 : espacamento * i;

      // CORREÇÃO DO ERRO:
      // clamp() retorna num, então
      // convertemos explicitamente para double.
      final double valor = dados[i].clamp(0, 100).toDouble();

      final double y = altura - ((valor / 100.0) * altura);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      paintLinha,
    );

    // ==========================================================
    // DESENHA OS PONTOS
    // ==========================================================

    for (int i = 0; i < dados.length; i++) {
      final double x = dados.length == 1 ? largura / 2 : espacamento * i;

      // CORREÇÃO DO ERRO:
      final double valor = dados[i].clamp(0, 100).toDouble();

      final double y = altura - ((valor / 100.0) * altura);

      canvas.drawCircle(
        Offset(x, y),
        5,
        paintPonto,
      );

      final paintCentro = Paint()
        ..color = escuro ? const Color(0xFF241F1F) : Colors.white;

      canvas.drawCircle(
        Offset(x, y),
        2,
        paintCentro,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _GraficoHistoricoPainter oldDelegate,
  ) {
    return oldDelegate.dados != dados || oldDelegate.escuro != escuro;
  }
}
