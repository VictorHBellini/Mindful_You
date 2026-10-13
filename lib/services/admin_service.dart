import 'package:shared_preferences/shared_preferences.dart';

import 'package:mindful_you/services/crypto_utils.dart';

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
    'suporte@mindful.com', // TODO: troque pelo seu e-mail de cadastro
  ];

  /// Segunda camada de proteção: além do e-mail estar na lista de admins,
  /// é preciso digitar esta senha para abrir a tela de gerenciar usuários
  /// (mesmo que alguém tente acessar a rota diretamente).
  ///
  /// MELHORIA: antes, a senha ficava em texto puro aqui (`#Ti_@dmin`) —
  /// bastava abrir o app descompilado num editor de texto pra lê-la.
  /// Agora só o hash SHA-256 dela fica no código; pra descobrir a senha
  /// de verdade seria preciso quebrar o hash, não só ler uma string.
  ///
  /// Gerado com: `CryptoUtils.sha256Hex('#Ti_@dmin')`.
  /// Para trocar a senha de admin, gere o novo hash da mesma forma e
  /// substitua o valor abaixo.
  static const String _hashSenhaAdmin =
      '5ec3b8f8f61dd18cdefc572bd799fe9ab700497c711c6a416c4c3c6db4d5bed3';

  /// Verifica se o [email] informado pertence a um administrador.
  /// A comparação ignora maiúsculas/minúsculas e espaços nas pontas,
  /// já que é assim que o e-mail é normalizado ao salvar no banco
  /// (ver `DatabaseService.criarUsuario`).
  static bool ehAdmin(String email) {
    final normalizado = email.trim().toLowerCase();
    return _emailsAdmin.contains(normalizado);
  }

  /// Confere a senha extra exigida para abrir a área administrativa,
  /// comparando o hash da senha digitada com o hash salvo (em tempo
  /// constante, para não vazar informação pelo tempo de resposta).
  static bool senhaAdminValida(String senha) {
    return CryptoUtils.hashesIguais(
      CryptoUtils.sha256Hex(senha),
      _hashSenhaAdmin,
    );
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
