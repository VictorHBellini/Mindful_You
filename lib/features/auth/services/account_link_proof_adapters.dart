import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindful_you/features/auth/services/account_link_preflight.dart';
import 'package:mindful_you/features/auth/services/auth_contracts.dart';
import 'package:mindful_you/services/database_service.dart';

/// Confere novamente a senha SQLite do ID selecionado, sem confiar na sessão.
/// A senha é fornecida somente no momento da chamada; não é armazenada aqui.
class SqlitePasswordProof implements RecentLocalAccountProof {
  SqlitePasswordProof({
    required this.password,
    DatabaseService? database,
  }) : _database = database ?? DatabaseService.instance;

  final String password;
  final DatabaseService _database;

  @override
  Future<bool> verifyLocalUser(int localUserId) async {
    if (localUserId <= 0 || password.isEmpty) return false;

    final db = await _database.database;

    final rows = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [localUserId],
      limit: 1,
    );

    if (rows.length != 1) return false;

    return _database.senhaCorreta(
      usuario: rows.single,
      senhaDigitada: password,
    );
  }
}

/// Reautentica a sessão Firebase atual, sem criar ou trocar de usuário.
/// A senha não é persistida; descartar esta instância após o pré-teste.
class FirebasePasswordProof implements FreshRemoteAccountProof {
  FirebasePasswordProof({
    required this.password,
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  final String password;
  final FirebaseAuth _auth;

  @override
  Future<AuthIdentity?> authenticateAgain() async {
    final before = _auth.currentUser;
    final email = before?.email;

    if (before == null || email == null || email.isEmpty || password.isEmpty) {
      return null;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await before.reauthenticateWithCredential(credential);
      await before.reload();

      final after = _auth.currentUser;

      if (after == null || after.uid != before.uid) {
        return null;
      }

      return AuthIdentity(
        provider: AuthProviderKind.firebase,
        providerUserId: after.uid,
        email: after.email,
        emailVerified: after.emailVerified,
      );
    } on FirebaseAuthException {
      return null;
    }
  }
}

/// Apenas consultas: nenhuma gravação ou liberação de dados.
///
/// Retorna UID e estado juntos, inclusive para vínculos revogados.
/// Um vínculo revogado não pode ser tratado como inexistente.
class SqliteAccountLinkConflictLookup implements AccountLinkConflictLookup {
  SqliteAccountLinkConflictLookup({
    DatabaseService? database,
  }) : _database = database ?? DatabaseService.instance;

  final DatabaseService _database;

  @override
  Future<LocalAccountLinkSnapshot?> linkForLocalUser(
    int localUserId,
  ) async {
    if (localUserId <= 0) return null;

    final db = await _database.database;

    final rows = await db.query(
      'vinculos_contas_firebase',
      columns: ['firebase_uid', 'estado'],
      where: 'usuario_id = ?',
      whereArgs: [localUserId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final uid = rows.single['firebase_uid'];
    final state = rows.single['estado'];

    if (uid is! String ||
        uid.trim().isEmpty ||
        state is! String ||
        !const {'pendente', 'confirmado', 'revogado'}.contains(state)) {
      throw StateError('Registro de vínculo local inválido.');
    }

    return LocalAccountLinkSnapshot(
      firebaseUid: uid,
      state: state,
    );
  }

  @override
  Future<bool> uidBelongsToOtherUser(
    String uid,
    int localUserId,
  ) async {
    if (uid.trim().isEmpty || localUserId <= 0) return true;

    final db = await _database.database;

    final rows = await db.query(
      'vinculos_contas_firebase',
      columns: ['usuario_id'],
      where:
          "firebase_uid = ? AND usuario_id != ? AND estado IN ('pendente', 'confirmado')",
      whereArgs: [uid, localUserId],
      limit: 1,
    );

    return rows.isNotEmpty;
  }
}
