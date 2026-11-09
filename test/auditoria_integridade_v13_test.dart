import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();

  late Directory diretorio;
  late Database banco;

  setUp(() async {
    diretorio = await Directory.systemTemp.createTemp(
      'mindful_auditoria_v13_',
    );

    final caminho = p.join(diretorio.path, 'auditoria.db');

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
              id INTEGER PRIMARY KEY
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
            CREATE TABLE identidades_registros (
              id INTEGER PRIMARY KEY,
              usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
              tipo TEXT NOT NULL,
              registro_local_id INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE lotes_migracao (
              id TEXT PRIMARY KEY,
              usuario_id INTEGER NOT NULL REFERENCES usuarios(id)
            )
          ''');

          await db.execute('''
            CREATE TABLE itens_migracao (
              lote_id TEXT NOT NULL REFERENCES lotes_migracao(id),
              identidade_id INTEGER NOT NULL
                REFERENCES identidades_registros(id),
              PRIMARY KEY(lote_id, identidade_id)
            )
          ''');
        },
      ),
    );

    await banco.insert('usuarios', {'id': 1});
    await banco.insert('usuarios', {'id': 2});

    await banco.insert('checkins', {
      'id': 10,
      'usuario_id': 1,
    });

    await banco.insert('avaliacoes', {
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

  Future<List<Map<String, Object?>>> auditarIdentidades() {
    return banco.rawQuery('''
      SELECT i.id
      FROM identidades_registros i
      LEFT JOIN checkins c
        ON i.tipo = 'checkin'
        AND c.id = i.registro_local_id
        AND c.usuario_id = i.usuario_id
      LEFT JOIN avaliacoes a
        ON i.tipo = 'avaliacao'
        AND a.id = i.registro_local_id
        AND a.usuario_id = i.usuario_id
      WHERE
        (i.tipo = 'checkin' AND c.id IS NULL)
        OR (i.tipo = 'avaliacao' AND a.id IS NULL)
        OR i.tipo NOT IN ('checkin', 'avaliacao')
        OR i.tipo IS NULL
    ''');
  }

  Future<List<Map<String, Object?>>> auditarItens() {
    return banco.rawQuery('''
      SELECT m.lote_id, m.identidade_id
      FROM itens_migracao m
      LEFT JOIN lotes_migracao l
        ON l.id = m.lote_id
      LEFT JOIN identidades_registros i
        ON i.id = m.identidade_id
      WHERE
        l.id IS NULL
        OR i.id IS NULL
        OR l.usuario_id != i.usuario_id
    ''');
  }

  test('aceita estrutura consistente', () async {
    await banco.insert('identidades_registros', {
      'id': 100,
      'usuario_id': 1,
      'tipo': 'checkin',
      'registro_local_id': 10,
    });

    await banco.insert('lotes_migracao', {
      'id': 'lote-1',
      'usuario_id': 1,
    });

    await banco.insert('itens_migracao', {
      'lote_id': 'lote-1',
      'identidade_id': 100,
    });

    final identidadesInvalidas = await auditarIdentidades();
    final itensInvalidos = await auditarItens();
    final chavesInvalidas = await banco.rawQuery(
      'PRAGMA foreign_key_check',
    );

    expect(identidadesInvalidas, isEmpty);
    expect(itensInvalidos, isEmpty);
    expect(chavesInvalidas, isEmpty);
  });

  test('detecta identidade sem historico correspondente', () async {
    await banco.insert('identidades_registros', {
      'id': 101,
      'usuario_id': 1,
      'tipo': 'checkin',
      'registro_local_id': 9999,
    });

    final inconsistencias = await auditarIdentidades();

    expect(inconsistencias, hasLength(1));
    expect(inconsistencias.single['id'], 101);
  });

  test('detecta item de migracao pertencente a outro usuario', () async {
    await banco.insert('identidades_registros', {
      'id': 102,
      'usuario_id': 1,
      'tipo': 'checkin',
      'registro_local_id': 10,
    });

    await banco.insert('lotes_migracao', {
      'id': 'lote-usuario-2',
      'usuario_id': 2,
    });

    await banco.insert('itens_migracao', {
      'lote_id': 'lote-usuario-2',
      'identidade_id': 102,
    });

    final inconsistencias = await auditarItens();

    expect(inconsistencias, hasLength(1));
    expect(inconsistencias.single['lote_id'], 'lote-usuario-2');
    expect(inconsistencias.single['identidade_id'], 102);
  });
}
