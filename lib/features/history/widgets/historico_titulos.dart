import 'package:flutter/material.dart';

/// Título principal do Histórico. Mantém a apresentação original da tela.
class HistoricoTitulo extends StatelessWidget {
  const HistoricoTitulo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico',
          style: TextStyle(
            fontSize: 31,
            fontWeight: FontWeight.w700,
            color: Color(0xFF40352F),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Acompanhe sua jornada ao longo do tempo',
          style: TextStyle(fontSize: 15, color: Color(0xFF8A7B73)),
        ),
      ],
    );
  }
}

/// Cabeçalho reutilizável das seções da tela Histórico.
class HistoricoTituloSecao extends StatelessWidget {
  const HistoricoTituloSecao(this.titulo, this.subtitulo, {super.key});

  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF40352F),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitulo,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8A7B73)),
        ),
      ],
    );
  }
}
