import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mindful_you/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory diretorio;
  late Database banco;
  late DatabaseService servico;

  setUp(() async {
    diretorio = await Directory.systemTemp.createTemp('mindful_exclusao_');

    banco = await databaseFactoryFfi.openDatabase(
      '${diretorio.path}/teste.db',
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE usuarios (
              id INTEGER PRIMARY KEY,
              foto_path TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE vinculos_contas_firebase (
              usuario_id INTEGER PRIMARY KEY
                REFERENCES usuarios(id) ON DELETE CASCADE,
              firebase_uid TEXT NOT NULL,
              estado TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE checkins (
              id INTEGER PRIMARY KEY,
              usuario_id INTEGER NOT NULL REFERENCES usuarios(id)
            )
          ''');

          await db.execute('''
            CREATE TABLE avaliacoes (
              id INTEGER PRIMARY KEY,
              usuario_id INTEGER NOT NULL REFERENCES usuarios(id)
            )
          ''');

          await db.execute('''
            CREATE TABLE vinculos_terapeuticos (
              id INTEGER PRIMARY KEY,
              terapeuta_id INTEGER NOT NULL REFERENCES usuarios(id),
              paciente_id INTEGER NOT NULL REFERENCES usuarios(id)
            )
          ''');

          await db.execute('''
            CREATE TABLE auditoria_cancelamento_vinculo_local (
              id INTEGER PRIMARY KEY,
              usuario_id INTEGER NOT NULL,
              evento TEXT NOT NULL,
              criado_em TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    servico = DatabaseService.paraTeste(banco);

    await banco.insert('usuarios', {'id': 1});
    await banco.insert('usuarios', {'id': 2});

    await banco.insert('checkins', {'id': 11, 'usuario_id': 1});
    await banco.insert('checkins', {'id': 22, 'usuario_id': 2});

    await banco.insert('avaliacoes', {'id': 11, 'usuario_id': 1});
    await banco.insert('avaliacoes', {'id': 22, 'usuario_id': 2});

    await banco.insert('vinculos_terapeuticos', {
      'id': 1,
      'terapeuta_id': 1,
      'paciente_id': 2,
    });

    await banco.insert('auditoria_cancelamento_vinculo_local', {
      'id': 1,
      'usuario_id': 1,
      'evento': 'solicitacao_pendente_revogada',
      'criado_em': DateTime.utc(2026, 1, 1).toIso8601String(),
    });
  });

  tearDown(() async {
    await banco.close();
    await diretorio.delete(recursive: true);
  });

  Future<void> adicionarVinculo(String estado) async {
    await banco.insert('vinculos_contas_firebase', {
      'usuario_id': 1,
      'firebase_uid': 'uid-teste',
      'estado': estado,
    });
  }

  Future<void> verificarDadosPreservados() async {
    expect(
      await banco.query('usuarios', where: 'id = 1'),
      isNotEmpty,
    );
    expect(
      await banco.query('checkins', where: 'usuario_id = 1'),
      isNotEmpty,
    );
    expect(
      await banco.query('avaliacoes', where: 'usuario_id = 1'),
      isNotEmpty,
    );
    expect(
      await banco.query('vinculos_terapeuticos', where: 'terapeuta_id = 1'),
      isNotEmpty,
    );
    expect(
      await banco.query('auditoria_cancelamento_vinculo_local'),
      hasLength(1),
    );
  }

  group('Exclusao local segura', () {
    for (final estado in ['pendente', 'confirmado', 'revogado']) {
      test('bloqueia exclusao com vinculo $estado', () async {
        await adicionarVinculo(estado);

        await expectLater(
          servico.deletarUsuarioLocalSemVinculo(1),
          throwsStateError,
        );

        await verificarDadosPreservados();

        expect(
          await banco.query('vinculos_contas_firebase'),
          hasLength(1),
        );
      });
    }

    test('exclui somente conta sem vinculo', () async {
      final excluidos = await servico.deletarUsuarioLocalSemVinculo(1);

      expect(excluidos, 1);

      expect(await banco.query('usuarios', where: 'id = 1'), isEmpty);
      expect(await banco.query('checkins', where: 'usuario_id = 1'), isEmpty);
      expect(await banco.query('avaliacoes', where: 'usuario_id = 1'), isEmpty);
      expect(
        await banco.query('vinculos_terapeuticos', where: 'terapeuta_id = 1'),
        isEmpty,
      );

      expect(await banco.query('usuarios', where: 'id = 2'), hasLength(1));
      expect(
        await banco.query('checkins', where: 'usuario_id = 2'),
        hasLength(1),
      );
      expect(
        await banco.query('avaliacoes', where: 'usuario_id = 2'),
        hasLength(1),
      );

      expect(
        await banco.query('auditoria_cancelamento_vinculo_local'),
        hasLength(1),
      );
    });

    test('usuario inexistente retorna zero', () async {
      expect(await servico.deletarUsuarioLocalSemVinculo(999), 0);
      await verificarDadosPreservados();
    });

    test('ID invalido nao permite exclusao', () async {
      await expectLater(
        servico.deletarUsuarioLocalSemVinculo(0),
        throwsArgumentError,
      );
      await verificarDadosPreservados();
    });

    test('falha SQLite reverte toda a transacao', () async {
      await banco.execute('''
        CREATE TRIGGER impedir_exclusao_usuario
        BEFORE DELETE ON usuarios
        WHEN OLD.id = 1
        BEGIN
          SELECT RAISE(ABORT, 'falha simulada');
        END
      ''');

      await expectLater(
        servico.deletarUsuarioLocalSemVinculo(1),
        throwsA(isA<DatabaseException>()),
      );

      await verificarDadosPreservados();
    });
  });
}
