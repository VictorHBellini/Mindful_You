import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mindful_you/features/auth/services/account_link_proof_adapters.dart';
import 'package:mindful_you/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory diretorio;
  late Database banco;
  late SqliteAccountLinkConflictLookup consulta;

  setUp(() async {
    diretorio = await Directory.systemTemp.createTemp(
      'mindful_conflict_lookup_',
    );

    banco = await databaseFactoryFfi.openDatabase(
      '${diretorio.path}/teste.db',
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE vinculos_contas_firebase (
              usuario_id INTEGER PRIMARY KEY,
              firebase_uid TEXT NOT NULL,
              estado TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    consulta = SqliteAccountLinkConflictLookup(
      database: DatabaseService.paraTeste(banco),
    );
  });

  tearDown(() async {
    await banco.close();
    await diretorio.delete(recursive: true);
  });

  Future<void> inserirVinculo({
    required int usuarioId,
    required String uid,
    required String estado,
  }) async {
    await banco.insert('vinculos_contas_firebase', {
      'usuario_id': usuarioId,
      'firebase_uid': uid,
      'estado': estado,
    });
  }

  group('Consulta SQLite de vinculos Firebase', () {
    test('usuario sem vinculo retorna null', () async {
      final vinculo = await consulta.linkForLocalUser(1);

      expect(vinculo, isNull);
    });

    test('retorna UID e estado pendente', () async {
      await inserirVinculo(
        usuarioId: 1,
        uid: 'uid-pendente',
        estado: 'pendente',
      );

      final vinculo = await consulta.linkForLocalUser(1);

      expect(vinculo, isNotNull);
      expect(vinculo!.firebaseUid, 'uid-pendente');
      expect(vinculo.state, 'pendente');
    });

    test('retorna UID e estado confirmado', () async {
      await inserirVinculo(
        usuarioId: 1,
        uid: 'uid-confirmado',
        estado: 'confirmado',
      );

      final vinculo = await consulta.linkForLocalUser(1);

      expect(vinculo, isNotNull);
      expect(vinculo!.firebaseUid, 'uid-confirmado');
      expect(vinculo.state, 'confirmado');
    });

    test('nao ignora vinculo revogado', () async {
      await inserirVinculo(
        usuarioId: 1,
        uid: 'uid-revogado',
        estado: 'revogado',
      );

      final vinculo = await consulta.linkForLocalUser(1);

      expect(vinculo, isNotNull);
      expect(vinculo!.firebaseUid, 'uid-revogado');
      expect(vinculo.state, 'revogado');
    });

    test('detecta UID pendente em outra conta', () async {
      await inserirVinculo(
        usuarioId: 2,
        uid: 'uid-compartilhado',
        estado: 'pendente',
      );

      final conflito = await consulta.uidBelongsToOtherUser(
        'uid-compartilhado',
        1,
      );

      expect(conflito, isTrue);
    });

    test('detecta UID confirmado em outra conta', () async {
      await inserirVinculo(
        usuarioId: 2,
        uid: 'uid-compartilhado',
        estado: 'confirmado',
      );

      final conflito = await consulta.uidBelongsToOtherUser(
        'uid-compartilhado',
        1,
      );

      expect(conflito, isTrue);
    });

    test('UID revogado de outra conta nao e vinculo ativo', () async {
      await inserirVinculo(
        usuarioId: 2,
        uid: 'uid-revogado',
        estado: 'revogado',
      );

      final conflito = await consulta.uidBelongsToOtherUser(
        'uid-revogado',
        1,
      );

      expect(conflito, isFalse);
    });

    test('estado desconhecido provoca falha segura', () async {
      await inserirVinculo(
        usuarioId: 1,
        uid: 'uid-invalido',
        estado: 'desconhecido',
      );

      await expectLater(
        consulta.linkForLocalUser(1),
        throwsStateError,
      );
    });

    test('UID vazio provoca falha segura', () async {
      await inserirVinculo(
        usuarioId: 1,
        uid: '',
        estado: 'confirmado',
      );

      await expectLater(
        consulta.linkForLocalUser(1),
        throwsStateError,
      );
    });
  });
}
