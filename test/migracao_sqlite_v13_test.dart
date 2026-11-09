import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mindful_you/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory diretorio;
  late Database banco;
  late Map<String, Object?> usuarioAntes;
  late Map<String, Object?> checkinAntes;
  late Map<String, Object?> avaliacaoAntes;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    diretorio = await Directory.systemTemp.createTemp(
      'mindful_migracao_v13_',
    );

    await databaseFactoryFfi.setDatabasesPath(diretorio.path);

    final caminho = p.join(diretorio.path, 'mindful_you.db');

    final bancoAntigo = await databaseFactoryFfi.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        version: 12,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE usuarios (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
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
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              usuario_id INTEGER NOT NULL
                REFERENCES usuarios(id),
              data_iso TEXT NOT NULL,
              criado_em TEXT NOT NULL,
              operacao_id TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE avaliacoes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              usuario_id INTEGER NOT NULL
                REFERENCES usuarios(id),
              instrumento TEXT NOT NULL,
              versao TEXT NOT NULL,
              pontuacao INTEGER NOT NULL,
              criado_em TEXT NOT NULL,
              operacao_id TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE vinculos_contas_firebase (
              usuario_id INTEGER PRIMARY KEY
                REFERENCES usuarios(id) ON DELETE CASCADE,
              firebase_uid TEXT NOT NULL,
              estado TEXT NOT NULL,
              criado_em TEXT NOT NULL,
              confirmado_em TEXT,
              revogado_em TEXT
            )
          ''');
        },
      ),
    );

    for (final id in [1, 2]) {
      await bancoAntigo.insert('usuarios', {
        'id': id,
        'nome': 'Usuario $id',
        'email': 'usuario$id@teste.invalid',
        'senha': 'hash_ficticio',
        'salt': 'salt_teste',
        'criado_em': '2026-01-01T10:00:00',
        'tipo_usuario': 'paciente',
      });

      await bancoAntigo.insert('checkins', {
        'id': id * 10,
        'usuario_id': id,
        'data_iso': '2026-01-01',
        'criado_em': '2026-01-01T10:00:00',
        'operacao_id': null,
      });

      await bancoAntigo.insert('avaliacoes', {
        'id': id * 100,
        'usuario_id': id,
        'instrumento': 'GAD7',
        'versao': '1',
        'pontuacao': id * 5,
        'criado_em': '2026-01-01T10:00:00',
        'operacao_id': null,
      });
    }

    await bancoAntigo.insert('vinculos_contas_firebase', {
      'usuario_id': 2,
      'firebase_uid': 'uid-antigo-teste',
      'estado': 'revogado',
      'criado_em': '2026-01-01T10:00:00',
      'revogado_em': '2026-01-02T10:00:00',
    });

    usuarioAntes = Map<String, Object?>.from(
      (await bancoAntigo.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: [1],
      ))
          .single,
    );

    checkinAntes = Map<String, Object?>.from(
      (await bancoAntigo.query(
        'checkins',
        where: 'id = ?',
        whereArgs: [10],
      ))
          .single,
    );

    avaliacaoAntes = Map<String, Object?>.from(
      (await bancoAntigo.query(
        'avaliacoes',
        where: 'id = ?',
        whereArgs: [100],
      ))
          .single,
    );

    expect(await bancoAntigo.getVersion(), 12);

    await bancoAntigo.close();

    banco = await DatabaseService.instance.database;
  });

  tearDownAll(() async {
    await banco.close();

    if (await diretorio.exists()) {
      await diretorio.delete(recursive: true);
    }
  });

  test('atualiza banco existente da versao 12 para 15', () async {
    expect(await banco.getVersion(), 15);
  });

  test('cria as tres tabelas auxiliares', () async {
    final tabelas = await banco.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
    ''');

    final nomes = tabelas.map((linha) => linha['name']).toSet();

    expect(nomes, contains('identidades_registros'));
    expect(nomes, contains('lotes_migracao'));
    expect(nomes, contains('itens_migracao'));
  });

  test('preserva os usuarios antigos', () async {
    final usuarios = await banco.query('usuarios');

    expect(usuarios, hasLength(2));

    final usuarioDepois = (await banco.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [1],
    ))
        .single;

    expect(usuarioDepois, usuarioAntes);
  });

  test('preserva checkin antigo sem operacao_id', () async {
    final checkins = await banco.query('checkins');

    expect(checkins, hasLength(2));

    final checkinDepois = (await banco.query(
      'checkins',
      where: 'id = ?',
      whereArgs: [10],
    ))
        .single;

    expect(checkinDepois, checkinAntes);
    expect(checkinDepois['operacao_id'], isNull);
  });

  test('preserva avaliacao antiga sem operacao_id', () async {
    final avaliacoes = await banco.query('avaliacoes');

    expect(avaliacoes, hasLength(2));

    final avaliacaoDepois = (await banco.query(
      'avaliacoes',
      where: 'id = ?',
      whereArgs: [100],
    ))
        .single;

    expect(avaliacaoDepois, avaliacaoAntes);
    expect(avaliacaoDepois['operacao_id'], isNull);
  });

  test('preserva vinculo Firebase revogado', () async {
    final vinculos = await banco.query(
      'vinculos_contas_firebase',
      where: 'usuario_id = ?',
      whereArgs: [2],
    );

    expect(vinculos, hasLength(1));
    expect(vinculos.single['estado'], 'revogado');
    expect(vinculos.single['firebase_uid'], 'uid-antigo-teste');
  });

  test('tabelas auxiliares iniciam vazias', () async {
    expect(await banco.query('identidades_registros'), isEmpty);
    expect(await banco.query('lotes_migracao'), isEmpty);
    expect(await banco.query('itens_migracao'), isEmpty);
  });

  test('chaves estrangeiras permanecem habilitadas', () async {
    final resultado = await banco.rawQuery('PRAGMA foreign_keys');

    expect(resultado.single['foreign_keys'], 1);
  });

  test('rejeita identidade de usuario inexistente', () async {
    await expectLater(
      banco.insert('identidades_registros', {
        'usuario_id': 999,
        'tipo': 'checkin',
        'registro_local_id': 10,
        'global_id': '0123456789abcdef0123456789abcdef',
        'criado_em': '2026-01-01T10:00:00',
      }),
      throwsA(isA<DatabaseException>()),
    );

    expect(await banco.query('identidades_registros'), isEmpty);
  });

  test('rejeita identificador global invalido', () async {
    await expectLater(
      banco.insert('identidades_registros', {
        'usuario_id': 1,
        'tipo': 'checkin',
        'registro_local_id': 10,
        'global_id': 'id-invalido',
        'criado_em': '2026-01-01T10:00:00',
      }),
      throwsA(isA<DatabaseException>()),
    );

    expect(await banco.query('identidades_registros'), isEmpty);
  });

  test('verifica integridade das chaves estrangeiras', () async {
    final problemas = await banco.rawQuery(
      'PRAGMA foreign_key_check',
    );

    expect(problemas, isEmpty);
  });
}
