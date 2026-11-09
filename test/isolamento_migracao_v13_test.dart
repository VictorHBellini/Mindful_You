import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory diretorio;
  late Database banco;

  const agora = '2026-01-01T10:00:00';

  setUp(() async {
    sqfliteFfiInit();

    diretorio = await Directory.systemTemp.createTemp(
      'mindful_isolamento_v13_',
    );

    final caminho = p.join(diretorio.path, 'isolamento.db');

    banco = await databaseFactoryFfi.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE usuarios (
              id INTEGER PRIMARY KEY,
              nome TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE checkins (
              id INTEGER PRIMARY KEY,
              usuario_id INTEGER NOT NULL
                REFERENCES usuarios(id)
            )
          ''');

          await db.execute('''
            CREATE TABLE identidades_registros (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              usuario_id INTEGER NOT NULL
                REFERENCES usuarios(id) ON DELETE CASCADE,
              tipo TEXT NOT NULL
                CHECK(tipo IN ('checkin', 'avaliacao')),
              registro_local_id INTEGER NOT NULL,
              global_id TEXT NOT NULL UNIQUE
                CHECK(
                  length(global_id) = 32
                  AND global_id NOT GLOB '*[^0-9a-f]*'
                ),
              criado_em TEXT NOT NULL,
              UNIQUE(usuario_id, tipo, registro_local_id)
            )
          ''');

          await db.execute('''
            CREATE TABLE lotes_migracao (
              id TEXT PRIMARY KEY,
              usuario_id INTEGER NOT NULL
                REFERENCES usuarios(id) ON DELETE CASCADE,
              estado TEXT NOT NULL DEFAULT 'preparacao',
              criado_em TEXT NOT NULL,
              atualizado_em TEXT NOT NULL,
              consentido_em TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE itens_migracao (
              lote_id TEXT NOT NULL
                REFERENCES lotes_migracao(id) ON DELETE CASCADE,
              identidade_id INTEGER NOT NULL
                REFERENCES identidades_registros(id)
                ON DELETE CASCADE,
              estado TEXT NOT NULL DEFAULT 'pendente',
              atualizado_em TEXT NOT NULL,
              PRIMARY KEY(lote_id, identidade_id)
            )
          ''');
        },
      ),
    );

    await banco.insert('usuarios', {
      'id': 1,
      'nome': 'Usuario 1',
    });

    await banco.insert('usuarios', {
      'id': 2,
      'nome': 'Usuario 2',
    });

    await banco.insert('checkins', {
      'id': 10,
      'usuario_id': 1,
    });

    await banco.insert('checkins', {
      'id': 20,
      'usuario_id': 2,
    });
  });

  tearDown(() async {
    await banco.close();

    if (await diretorio.exists()) {
      await diretorio.delete(recursive: true);
    }
  });

  test('demonstra identidade apontando para registro inexistente', () async {
    final identidadeId = await banco.insert('identidades_registros', {
      'usuario_id': 1,
      'tipo': 'checkin',
      'registro_local_id': 9999,
      'global_id': '11111111111111111111111111111111',
      'criado_em': agora,
    });

    expect(identidadeId, greaterThan(0));
  });

  test('demonstra identidade apontando para outro usuario', () async {
    final identidadeId = await banco.insert('identidades_registros', {
      'usuario_id': 1,
      'tipo': 'checkin',
      'registro_local_id': 20,
      'global_id': '22222222222222222222222222222222',
      'criado_em': agora,
    });

    expect(identidadeId, greaterThan(0));
  });

  test('demonstra item de lote associado a outro usuario', () async {
    await banco.insert('lotes_migracao', {
      'id': 'lote-usuario-2',
      'usuario_id': 2,
      'estado': 'preparacao',
      'criado_em': agora,
      'atualizado_em': agora,
    });

    final identidadeId = await banco.insert('identidades_registros', {
      'usuario_id': 1,
      'tipo': 'checkin',
      'registro_local_id': 10,
      'global_id': '33333333333333333333333333333333',
      'criado_em': agora,
    });

    final itemId = await banco.insert('itens_migracao', {
      'lote_id': 'lote-usuario-2',
      'identidade_id': identidadeId,
      'estado': 'pendente',
      'atualizado_em': agora,
    });

    expect(itemId, greaterThan(0));
  });

  test('confirma que as chaves estrangeiras estao habilitadas', () async {
    final resultado = await banco.rawQuery('PRAGMA foreign_keys');

    expect(resultado.single['foreign_keys'], 1);
  });

  test('confirma que nao existem registros orfaos por chave estrangeira',
      () async {
    final resultado = await banco.rawQuery('PRAGMA foreign_key_check');

    expect(resultado, isEmpty);
  });
}
