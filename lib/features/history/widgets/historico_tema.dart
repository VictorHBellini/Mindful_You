import 'package:flutter/material.dart';

/// Paleta visual exclusiva do Histórico; não modifica dados ou indicadores.
class HistoricoTema {
  static bool escuro(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color fundo(BuildContext context) =>
      escuro(context) ? const Color(0xFF141414) : const Color(0xFFF8F5F2);
  static Color cartao(BuildContext context) =>
      escuro(context) ? const Color(0xFF241F1F) : Colors.white;
  static Color texto(BuildContext context) =>
      escuro(context) ? const Color(0xFFF1E8E4) : const Color(0xFF40352F);
  static Color secundario(BuildContext context) =>
      escuro(context) ? const Color(0xFFC9B7B2) : const Color(0xFF8A7B73);
  static Color destaque(BuildContext context) =>
      escuro(context) ? const Color(0xFFD9ABA9) : const Color(0xFF80675C);
  static Color iconeFundo(BuildContext context) => escuro(context)
      ? const Color(0xFF382C2C)
      : Colors.white.withValues(alpha: 0.75);
  static Color rosa(BuildContext context) =>
      escuro(context) ? const Color(0xFFD9ABA9) : const Color(0xFFC89494);
}
