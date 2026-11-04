import 'package:mindful_you/features/auth/services/account_link_proof_adapters.dart';
import 'package:mindful_you/features/auth/services/session_service.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cancela somente uma solicitação local pendente após prova de senha.
/// Não altera o Firebase, não vincula contas e não toca em históricos.
class PendingLocalLinkCancellation {
  const PendingLocalLinkCancellation();

  Future<String> cancel({
    required int localUserId,
    required String expectedUid,
    required String localPassword,
  }) async {
    if (localUserId <= 0 || expectedUid.isEmpty || localPassword.isEmpty) {
      return 'Dados insuficientes. Nenhuma alteração realizada.';
    }
    final initial = await SessionService.validar();
    if (initial?.id != localUserId) {
      return 'A sessão local mudou. Faça login novamente.';
    }
    final verified = await SqlitePasswordProof(password: localPassword)
        .verifyLocalUser(localUserId);
    if (!verified) {
      return 'Senha local incorreta. Nenhuma alteração realizada.';
    }
    final again = await SessionService.validar();
    if (again?.id != localUserId) {
      return 'A sessão local mudou. Nenhuma alteração realizada.';
    }
    final db = await DatabaseService.instance.database;
    return db.transaction((txn) async {
      // Nunca consultar SessionService dentro da transação SQLite.
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getInt('usuarioId') != localUserId) {
        return 'A sessão local mudou. Nenhuma alteração realizada.';
      }
      final rows = await txn.query(
        'vinculos_contas_firebase',
        columns: ['firebase_uid', 'estado'],
        where: 'usuario_id = ?',
        whereArgs: [localUserId],
        limit: 1,
      );
      if (rows.length != 1 ||
          rows.single['estado'] != 'pendente' ||
          rows.single['firebase_uid'] != expectedUid) {
        return 'A solicitação mudou ou não está pendente. Nenhuma alteração realizada.';
      }
      // Auditoria não armazena senha, e-mail nem UID em texto puro.
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS auditoria_cancelamento_vinculo_local (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          usuario_id INTEGER NOT NULL,
          evento TEXT NOT NULL,
          criado_em TEXT NOT NULL
        )
      ''');
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final count = await txn.update(
        'vinculos_contas_firebase',
        {'estado': 'revogado', 'revogado_em': timestamp},
        where: "usuario_id = ? AND firebase_uid = ? AND estado = 'pendente'",
        whereArgs: [localUserId, expectedUid],
      );
      if (count != 1) {
        throw StateError('Não foi possível confirmar a alteração do vínculo.');
      }
      await txn.insert('auditoria_cancelamento_vinculo_local', {
        'usuario_id': localUserId,
        'evento': 'solicitacao_pendente_revogada',
        'criado_em': timestamp,
      });
      return 'Solicitação pendente cancelada somente neste dispositivo. '
          'Nenhum histórico foi alterado.';
    });
  }
}
