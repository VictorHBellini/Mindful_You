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

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    pasta = await Directory.systemTemp.createTemp(
      'mindful_lote_invalido_v14_',
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
              criado_em TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE checkins (
              id INTEGER PRIMARY KEY,
              usuario_id INTEGER NOT NULL
                REFERENCES usuarios(id),
              data_iso TEXT NOT NULL,
              criado_em TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE avaliacoes (
              id INTEGER PRIMARY KEY,
              usuario_id INTEGER NOT NULL
                REFERENCES usuarios(id),
              instrumento TEXT NOT NULL,
              versao TEXT NOT NULL,
              pontuacao INTEGER NOT NULL,
              criado_em TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE identidades_registros (
              id INTEGER PRIMARY KEY,
              usuario_id INTEGER NOT NULL
                REFERENCES usuarios(id),
              tipo TEXT NOT NULL,
              registro_local_id INTEGER NOT NULL,
              global_id TEXT NOT NULL UNIQUE,
              criado_em TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE lotes_migracao (
              id TEXT PRIMARY KEY,
              usuario_id INTEGER NOT NULL
                REFERENCES usuarios(id),
              estado TEXT NOT NULL,
              criado_em TEXT NOT NULL,
              atualizado_em TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE itens_migracao (
              lote_id TEXT NOT NULL
                REFERENCES lotes_migracao(id),
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

    for (final id in [1, 2]) {
      await db.insert('usuarios', {
        'id': id,
        'nome': 'Usuario $id',
        'email': 'lote$id@teste.invalid',
        'senha': 'hash_ficticio',
        'salt': 'salt_teste',
        'criado_em': data,
      });
    }

    await db.insert('checkins', {
      'id': 10,
      'usuario_id': 1,
      'data_iso': '2026-11-05',
      'criado_em': data,
    });

    await db.insert('identidades_registros', {
      'id': 100,
      'usuario_id': 1,
      'tipo': 'checkin',
      'registro_local_id': 10,
      'global_id': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'criado_em': data,
    });

    await db.insert('lotes_migracao', {
      'id': 'lote-usuario-2',
      'usuario_id': 2,
      'estado': 'preparacao',
      'criado_em': data,
      'atualizado_em': data,
    });

    // Inconsistencia proposital:
    // lote do usuario 2 com identidade do usuario 1.
    await db.insert('itens_migracao', {
      'lote_id': 'lote-usuario-2',
      'identidade_id': 100,
      'estado': 'pendente',
      'atualizado_em': data,
    });

    expect(await db.getVersion(), 13);
    await db.close();
  });

  tearDownAll(() async {
    if (await pasta.exists()) {
      await pasta.delete(recursive: true);
    }
  });

  Future<Database> abrirParaVerificacao() {
    return databaseFactoryFfi.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        readOnly: true,
        singleInstance: false,
      ),
    );
  }

  test('rejeita lote associado a outro usuario', () async {
    await expectLater(
      DatabaseService.instance.database,
      throwsA(
        isA<StateError>().having(
          (erro) => erro.message,
          'mensagem',
          contains('item de migração'),
        ),
      ),
    );
  });

  test('preserva versao 13 apos falha', () async {
    final db = await abrirParaVerificacao();

    try {
      expect(await db.getVersion(), 13);
    } finally {
      await db.close();
    }
  });

  test('preserva identidade e lote originais', () async {
    final db = await abrirParaVerificacao();

    try {
      final identidades = await db.query('identidades_registros');
      final lotes = await db.query('lotes_migracao');
      final itens = await db.query('itens_migracao');

      expect(identidades, hasLength(1));
      expect(lotes, hasLength(1));
      expect(itens, hasLength(1));

      expect(identidades.single['usuario_id'], 1);
      expect(lotes.single['usuario_id'], 2);
      expect(itens.single['identidade_id'], 100);
    } finally {
      await db.close();
    }
  });

  test('nao instala gatilhos apos falha', () async {
    final db = await abrirParaVerificacao();

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
