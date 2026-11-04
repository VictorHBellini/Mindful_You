import 'package:sqflite/sqflite.dart';

import 'account_link_policy.dart';
import 'auth_contracts.dart';

/// Consulta somente leitura dos vínculos persistidos no SQLite v12.
/// Um registro local 'confirmado' NÃO é prova de autorização no servidor.
class AccountLinkRepository {
  const AccountLinkRepository();

  Future<StoredAccountLink?> readForLocalUser(
    DatabaseExecutor db,
    int localUserId,
  ) async {
    if (localUserId <= 0) return null;
    final rows = await db.query(
      'vinculos_contas_firebase',
      columns: ['usuario_id', 'firebase_uid', 'estado'],
      where: 'usuario_id = ?',
      whereArgs: [localUserId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return StoredAccountLink.fromRow(rows.single);
  }

  Future<bool> isUidActiveForAnotherUser(
    DatabaseExecutor db, {
    required String firebaseUid,
    required int localUserId,
  }) async {
    if (firebaseUid.trim().isEmpty || localUserId <= 0) return true;
    final rows = await db.query(
      'vinculos_contas_firebase',
      columns: ['usuario_id'],
      where:
          "firebase_uid = ? AND usuario_id != ? AND estado IN ('pendente', 'confirmado')",
      whereArgs: [firebaseUid, localUserId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Apenas elegibilidade preliminar. Nunca cria vínculo nem concede sessão.
  Future<AccountLinkDecision> evaluateCandidate(
    DatabaseExecutor db, {
    required int? authenticatedLocalUserId,
    required AuthIdentity? remoteIdentity,
  }) async {
    if (authenticatedLocalUserId == null || authenticatedLocalUserId <= 0) {
      return AccountLinkDecision.localAuthenticationRequired;
    }
    if (remoteIdentity == null ||
        remoteIdentity.provider != AuthProviderKind.firebase ||
        remoteIdentity.providerUserId.trim().isEmpty) {
      return AccountLinkDecision.remoteAuthenticationRequired;
    }
    if (!remoteIdentity.emailVerified) {
      return AccountLinkDecision.verifiedEmailRequired;
    }
    final existing = await readForLocalUser(db, authenticatedLocalUserId);
    final conflicting = await isUidActiveForAnotherUser(
      db,
      firebaseUid: remoteIdentity.providerUserId,
      localUserId: authenticatedLocalUserId,
    );
    return const AccountLinkPolicy().evaluate(
      authenticatedLocalUserId: authenticatedLocalUserId,
      remoteIdentity: remoteIdentity,
      alreadyLinkedUidForLocalUser: existing?.firebaseUid,
      remoteUidLinkedToAnotherLocalUser: conflicting,
      existingLinkState: existing?.state,
    );
  }
}

class StoredAccountLink {
  const StoredAccountLink({
    required this.localUserId,
    required this.firebaseUid,
    required this.state,
  });

  final int localUserId;
  final String firebaseUid;
  final String state;

  static StoredAccountLink fromRow(Map<String, Object?> row) {
    final id = row['usuario_id'];
    final uid = row['firebase_uid'];
    final state = row['estado'];
    if (id is! int ||
        id <= 0 ||
        uid is! String ||
        uid.isEmpty ||
        state is! String ||
        !const {'pendente', 'confirmado', 'revogado'}.contains(state)) {
      throw StateError('Registro de vínculo local inválido.');
    }
    return StoredAccountLink(localUserId: id, firebaseUid: uid, state: state);
  }
}
