import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:mindful_you/features/history/historico_global.dart';

/// Identidade local validada no SQLite. Dados do SharedPreferences não
/// constituem prova de autenticação ou autorização em ambiente hostil.
class LocalSession {
  const LocalSession({required this.id, required this.tipoUsuario});
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

  /// Confirma existência e perfil diretamente no banco, sem confiar em
  /// emailUsuario, tipoUsuario ou isAdmin do SharedPreferences.
  static Future<LocalSession?> validar() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('usuarioId');
    if (id == null) return null;
    final db = await DatabaseService.instance.database;
    final registros = await db.query('usuarios',
        columns: ['id', 'tipo_usuario'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1);
    if (registros.isEmpty) {
      await encerrar();
      return null;
    }
    // Evita aceitar resultado de consulta após troca de conta concorrente.
    final prefsAtual = await SharedPreferences.getInstance();
    if (prefsAtual.getInt('usuarioId') != id) return null;
    final tipo = registros.first['tipo_usuario']?.toString() ?? '';
    if (tipo != 'paciente' && tipo != 'terapeuta') return null;
    return LocalSession(id: id, tipoUsuario: tipo);
  }

  static Future<void> encerrar() async {
    final prefs = await SharedPreferences.getInstance();
    // Invalida primeiro a identidade para impedir leituras concorrentes.
    await prefs.remove('usuarioId');
    historicoGlobal.clear();
    for (final chave in _chavesSessao) {
      if (chave != 'usuarioId') await prefs.remove(chave);
    }
  }
}
