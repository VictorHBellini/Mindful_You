import 'package:shared_preferences/shared_preferences.dart';

/// Administração sensível desativada no protótipo Android.
/// Um segredo ou uma lista de e-mails embarcados não constitui autorização.
/// Reativar somente com autorização verificada por um backend confiável.
class AdminService {
  AdminService._();

  static bool ehAdmin(String email) => false;

  static bool senhaAdminValida(String senha) => false;

  static Future<void> salvarStatusAdmin(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isAdmin');
  }

  static Future<bool> statusAdminSalvo() async => false;
}
