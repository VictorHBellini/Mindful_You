import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mindful_you/features/auth/services/account_link_repository.dart';
import 'package:mindful_you/features/auth/services/account_link_policy.dart';
import 'package:mindful_you/features/auth/services/auth_contracts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory temporaryDirectory;
  late Database db;

  const identity = AuthIdentity(
    provider: AuthProviderKind.firebase,
    providerUserId: 'firebase-uid-123',
    email: 'teste@example.com',
    emailVerified: true,
  );

  setUp(() async {
    temporaryDirectory =
        await Directory.systemTemp.createTemp('mindful_link_test_');

    final path = '${temporaryDirectory.path}/test.db';

    db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE vinculos_contas_firebase (
              usuario_id INTEGER PRIMARY KEY,
              firebase_uid TEXT NOT NULL,
              estado TEXT NOT NULL
            )
          ''');
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
    await temporaryDirectory.delete(recursive: true);
  });

  Future<AccountLinkDecision> evaluate() {
    return const AccountLinkRepository().evaluateCandidate(
      db,
      authenticatedLocalUserId: 1,
      remoteIdentity: identity,
    );
  }

  Future<void> insertLink({
    required int userId,
    required String uid,
    required String state,
  }) async {
    await db.insert('vinculos_contas_firebase', {
      'usuario_id': userId,
      'firebase_uid': uid,
      'estado': state,
    });
  }

  group('Repositorio SQLite - seguranca de vinculos', () {
    test('sem vinculo permite pre-verificacao', () async {
      expect(
        await evaluate(),
        AccountLinkDecision.eligibleForServerVerification,
      );
    });

    test('vinculo pendente exige revisao', () async {
      await insertLink(
        userId: 1,
        uid: 'firebase-uid-123',
        state: 'pendente',
      );

      expect(
        await evaluate(),
        AccountLinkDecision.pendingLinkRequiresReview,
      );
    });

    test('vinculo revogado bloqueia mesmo UID', () async {
      await insertLink(
        userId: 1,
        uid: 'firebase-uid-123',
        state: 'revogado',
      );

      expect(
        await evaluate(),
        AccountLinkDecision.revokedLinkRequiresReview,
      );
    });

    test('vinculo revogado bloqueia UID diferente', () async {
      await insertLink(
        userId: 1,
        uid: 'outro-uid',
        state: 'revogado',
      );

      expect(
        await evaluate(),
        AccountLinkDecision.revokedLinkRequiresReview,
      );
    });

    test('vinculo confirmado com outro UID gera conflito', () async {
      await insertLink(
        userId: 1,
        uid: 'outro-uid',
        state: 'confirmado',
      );

      expect(
        await evaluate(),
        AccountLinkDecision.conflictingRemoteIdentity,
      );
    });

    test('UID ativo em outra conta gera conflito', () async {
      await insertLink(
        userId: 2,
        uid: 'firebase-uid-123',
        state: 'confirmado',
      );

      expect(
        await evaluate(),
        AccountLinkDecision.remoteIdentityAlreadyLinked,
      );
    });

    test('vinculo confirmado com mesmo UID passa no preflight', () async {
      await insertLink(
        userId: 1,
        uid: 'firebase-uid-123',
        state: 'confirmado',
      );

      expect(
        await evaluate(),
        AccountLinkDecision.eligibleForServerVerification,
      );
    });
  });
}
