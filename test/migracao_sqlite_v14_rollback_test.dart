import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mindful_you/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory pasta;
  late String caminho;

  const data = '2026-11-05T12:00:00';
  const globalId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    pasta = await Directory.systemTemp.createTemp(
      'mindful_rollback_v14_',
    );

    await databaseFactoryFfi.setDatabasesPath(pasta.path);
    caminho = p.join(pasta.path, 'mindful_you.db');

    final db = await databaseFactoryFfi.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        version: 13,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE usuarios (
              id INTEGER PRIMARY KEY,
              nome TEXT NOT NULL,
              email TEXT NOT NULL UNIQUE,
              senha TEXT NOT NULL,
              salt TEXT NOT NULL DEFAULT '',
              foto_path TEXT,
              criado_em TEXT NOT NULL,
              tipo_usuario TEXT NOT NULL DEFAULT 'paciente'
            )
          ''');

          await db.execute('''
            CREATE TABLE checkins (
              id INTEGER PRIMARY KEY,
              usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
              data_iso TEXT NOT NULL,
              criado_em TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE avaliacoes (
              id INTEGER PRIMARY KEY,
              usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
              instrumento TEXT NOT NULL,
              versao TEXT NOT NULL,
              pontuacao INTEGER NOT NULL,
              criado_em TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE identidades_registros (
              id INTEGER PRIMARY KEY,
              usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
              tipo TEXT NOT NULL,
              registro_local_id INTEGER NOT NULL,
              global_id TEXT NOT NULL UNIQUE,
              criado_em TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE lotes_migracao (
              id TEXT PRIMARY KEY,
              usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
              estado TEXT NOT NULL,
              criado_em TEXT NOT NULL,
              atualizado_em TEXT NOT NULL,
              consentido_em TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE itens_migracao (
              lote_id TEXT NOT NULL REFERENCES lotes_migracao(id),
              identidade_id INTEGER NOT NULL
                REFERENCES identidades_registros(id),
              estado TEXT NOT NULL,
              atualizado_em TEXT NOT NULL,
              PRIMARY KEY(lote_id, identidade_id)
            )
          ''');
        },
      ),
    );

    await db.insert('usuarios', {
      'id': 1,
      'nome': 'Paciente Teste',
      'email': 'rollback@teste.invalid',
      'senha': 'hash_ficticio',
      'salt': 'salt_teste',
      'criado_em': data,
      'tipo_usuario': 'paciente',
    });

    // Identidade inconsistente:
    // aponta para um check-in que nao existe.
    await db.insert('identidades_registros', {
      'id': 1,
      'usuario_id': 1,
      'tipo': 'checkin',
      'registro_local_id': 999,
      'global_id': globalId,
      'criado_em': data,
    });

    expect(await db.getVersion(), 13);
    await db.close();
  });

  tearDownAll(() async {
    if (await pasta.exists()) {
      await pasta.delete(recursive: true);
    }
  });

  test('migração v14 rejeita identidade inconsistente', () async {
    await expectLater(
      DatabaseService.instance.database,
      throwsA(anything),
    );
  });

  test('rollback preserva a versao 13', () async {
    final db = await databaseFactoryFfi.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        readOnly: true,
        singleInstance: false,
      ),
    );

    try {
      expect(await db.getVersion(), 13);
    } finally {
      await db.close();
    }
  });

  test('rollback preserva usuario e identidade', () async {
    final db = await databaseFactoryFfi.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        readOnly: true,
        singleInstance: false,
      ),
    );

    try {
      final usuarios = await db.query('usuarios');
      final identidades = await db.query(
        'identidades_registros',
      );

      expect(usuarios, hasLength(1));
      expect(identidades, hasLength(1));
      expect(identidades.single['registro_local_id'], 999);
      expect(identidades.single['global_id'], globalId);
    } finally {
      await db.close();
    }
  });

  test('rollback nao instala gatilhos v14', () async {
    final db = await databaseFactoryFfi.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        readOnly: true,
        singleInstance: false,
      ),
    );

    try {
      final gatilhos = await db.rawQuery('''
        SELECT name FROM sqlite_master
        WHERE type = 'trigger'
          AND name LIKE 'v14_%'
      ''');

      expect(gatilhos, isEmpty);
    } finally {
      await db.close();
    }
  });
}
