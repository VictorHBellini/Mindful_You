import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:mindful_you/features/history/historico_global.dart';
import 'package:mindful_you/features/auth/services/session_operation_coordinator.dart';
import 'package:mindful_you/widgets/avatar_perfil_notifier.dart';

/// Identidade local validada no SQLite.
///
/// Dados do SharedPreferences nao constituem prova de
/// autenticacao ou autorizacao em ambiente hostil.
class LocalSession {
  const LocalSession({
    required this.id,
    required this.tipoUsuario,
  });

  final int id;
  final String tipoUsuario;
}

class SessionService {
  SessionService._();

  static const _chavesSessao = <String>[
    'usuarioId',
    'nomeUsuario',
    'emailUsuario',
    'tipoUsuario',
    'isAdmin',
    'fotoPerfil',
  ];

  /// Confirma a existencia e o perfil diretamente no SQLite.
  ///
  /// Nao confia nos campos emailUsuario, tipoUsuario ou isAdmin
  /// armazenados no SharedPreferences.
  ///
  /// Este metodo apenas valida. Nao encerra a sessao, pois pode
  /// ser chamado dentro de uma operacao ja coordenada.
  static Future<LocalSession?> validar() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('usuarioId');

    if (id == null || id <= 0) {
      return null;
    }

    final db = await DatabaseService.instance.database;

    final registros = await db.query(
      'usuarios',
      columns: ['id', 'tipo_usuario'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    // A conta nao existe mais no SQLite.
    // Nao chamar encerrar() aqui para evitar deadlock.
    if (registros.length != 1) {
      return null;
    }

    // Confirma que a identidade nao mudou durante a consulta.
    final prefsAtual = await SharedPreferences.getInstance();

    if (prefsAtual.getInt('usuarioId') != id) {
      return null;
    }

    final tipo = registros.single['tipo_usuario']?.toString() ?? '';

    if (tipo != 'paciente' && tipo != 'terapeuta') {
      return null;
    }

    return LocalSession(
      id: id,
      tipoUsuario: tipo,
    );
  }

  /// Inicia uma sessao local apos autenticacao ou cadastro.
  ///
  /// O chamador deve autenticar o usuario previamente.
  /// Este metodo nao verifica senhas nem concede privilegios.
  ///
  /// Nao chamar dentro de outra operacao coordenada.
  static Future<void> iniciar({
    required int usuarioId,
    required String nome,
    required String email,
    required String tipoUsuario,
    String? fotoPath,
  }) {
    return SessionOperationCoordinator.executar(() async {
      if (usuarioId <= 0 ||
          nome.trim().isEmpty ||
          email.trim().isEmpty ||
          (tipoUsuario != 'paciente' && tipoUsuario != 'terapeuta')) {
        throw ArgumentError('Dados invalidos para iniciar sessao.');
      }

      final prefs = await SharedPreferences.getInstance();

      // Invalida primeiro a identidade anterior.
      await prefs.remove('usuarioId');

      // Descarta historicos e leituras pendentes.
      invalidarCacheHistorico();

      // Remove metadados da sessao anterior.
      for (final chave in _chavesSessao) {
        if (chave != 'usuarioId') {
          await prefs.remove(chave);
        }
      }

      // Prepara os dados da nova sessao.
      await prefs.setString('nomeUsuario', nome);
      await prefs.setString('emailUsuario', email);
      await prefs.setString('tipoUsuario', tipoUsuario);

      // A administracao privilegiada permanece desativada.
      await prefs.remove('isAdmin');

      if (fotoPath != null && fotoPath.isNotEmpty) {
        await prefs.setString('fotoPerfil', fotoPath);
      }

      // Publica a identidade por ultimo.
      await prefs.setInt('usuarioId', usuarioId);

      // Atualiza os avatares apos iniciar a nova sessao.
      AvatarPerfilNotifier.notificarAlteracao();
    });
  }

  /// Encerra a sessao local de maneira coordenada.
  ///
  /// Aguarda operacoes anteriores que utilizem o mesmo
  /// coordenador, evitando sobreposicao com alteracao de senha.
  ///
  /// Nao chamar dentro de outra operacao
  /// SessionOperationCoordinator.executar().
  static Future<void> encerrar() {
    return SessionOperationCoordinator.executar(() async {
      final prefs = await SharedPreferences.getInstance();

      // Invalida primeiro a identidade local.
      await prefs.remove('usuarioId');

      // Descarta o historico armazenado em memoria.
      invalidarCacheHistorico();

      // Remove os demais dados da sessao.
      for (final chave in _chavesSessao) {
        if (chave != 'usuarioId') {
          await prefs.remove(chave);
        }
      }

      // Invalida os avatares da sessao encerrada.
      AvatarPerfilNotifier.notificarAlteracao();
    });
  }
}
