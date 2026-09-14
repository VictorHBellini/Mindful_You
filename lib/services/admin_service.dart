import 'package:shared_preferences/shared_preferences.dart';

/// Serviço central de administração do app.
///
/// Por enquanto, "ser admin" é definido por uma lista fixa de e-mails no
/// código (sem autenticação online ainda). Quem fizer login com um desses
/// e-mails ganha acesso à tela "Gerenciar Usuários" no menu lateral.
///
/// Para adicionar/remover admins, edite a lista [_emailsAdmin] abaixo.
class AdminService {
  AdminService._();

  static const List<String> _emailsAdmin = [
    'suporte@mindfulyou.com',
  ];

  /// Segunda camada de proteção: além do e-mail estar na lista de admins,
  /// é preciso digitar esta senha para abrir a tela de gerenciar usuários
  /// (mesmo que alguém tente acessar a rota diretamente).
  static const String _senhaAdmin = '#Ti_@dmin';

  /// Verifica se o [email] informado pertence a um administrador.
  /// A comparação ignora maiúsculas/minúsculas e espaços nas pontas,
  /// já que é assim que o e-mail é normalizado ao salvar no banco
  /// (ver `DatabaseService.criarUsuario`).
  static bool ehAdmin(String email) {
    final normalizado = email.trim().toLowerCase();
    return _emailsAdmin.contains(normalizado);
  }

  /// Confere a senha extra exigida para abrir a área administrativa.
  static bool senhaAdminValida(String senha) {
    return senha == _senhaAdmin;
  }

  /// Salva no dispositivo se o usuário atualmente logado é admin.
  /// Deve ser chamado logo após um login bem-sucedido.
  static Future<void> salvarStatusAdmin(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdmin', ehAdmin(email));
  }

  /// Lê o status de admin salvo localmente (padrão: false).
  static Future<bool> statusAdminSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isAdmin') ?? false;
  }
}
