import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mindful_you/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory pasta;
  late String caminho;
  late Database banco;

  const data = '2026-11-05T12:00:00';
  const globalId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    pasta = await Directory.systemTemp.createTemp(
      'mindful_v13_para_v14_valida_',
    );

    await databaseFactoryFfi.setDatabasesPath(pasta.path);
    caminho = p.join(pasta.path, 'mindful_you.db');

    final antigo = await databaseFactoryFfi.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        version: 13,
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
              usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
              data_iso TEXT NOT NULL,
              data_formatada TEXT NOT NULL,
              sentimento TEXT NOT NULL DEFAULT '',
              emoji TEXT NOT NULL DEFAULT '',
              cansaco REAL NOT NULL,
              ansiedade REAL NOT NULL,
              sono REAL NOT NULL,
              produtividade REAL,
              atividade_significativa TEXT,
              bem_estar INTEGER NOT NULL,
              principal_ponto TEXT NOT NULL DEFAULT '',
              cor_valor INTEGER NOT NULL,
              humor_frequencia TEXT NOT NULL DEFAULT '',
              interesse_frequencia TEXT NOT NULL DEFAULT '',
              exaustao_burnout TEXT NOT NULL DEFAULT '',
              distanciamento_burnout TEXT NOT NULL DEFAULT '',
              criado_em TEXT NOT NULL,
              operacao_id TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE avaliacoes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
              instrumento TEXT NOT NULL,
              versao TEXT NOT NULL,
              pontuacao INTEGER NOT NULL,
              criado_em TEXT NOT NULL,
              operacao_id TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE identidades_registros (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              usuario_id INTEGER NOT NULL
                REFERENCES usuarios(id) ON DELETE CASCADE,
              tipo TEXT NOT NULL,
              registro_local_id INTEGER NOT NULL,
              global_id TEXT NOT NULL UNIQUE,
              criado_em TEXT NOT NULL,
              UNIQUE(usuario_id, tipo, registro_local_id)
            )
          ''');

          await db.execute('''
            CREATE TABLE lotes_migracao (
              id TEXT PRIMARY KEY,
              usuario_id INTEGER NOT NULL
                REFERENCES usuarios(id) ON DELETE CASCADE,
              estado TEXT NOT NULL,
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
                REFERENCES identidades_registros(id) ON DELETE CASCADE,
              estado TEXT NOT NULL,
              atualizado_em TEXT NOT NULL,
              PRIMARY KEY(lote_id, identidade_id)
            )
          ''');
        },
      ),
    );

    for (final id in [1, 2]) {
      await antigo.insert('usuarios', {
        'id': id,
        'nome': 'Paciente $id',
        'email': 'valido$id@teste.invalid',
        'senha': 'hash_ficticio',
        'salt': 'salt_teste',
        'criado_em': data,
        'tipo_usuario': 'paciente',
      });
    }

    await antigo.insert('checkins', {
      'id': 10,
      'usuario_id': 1,
      'data_iso': '2026-11-05',
      'data_formatada': '05/11/2026',
      'sentimento': 'Bem',
      'emoji': '🙂',
      'cansaco': 20.0,
      'ansiedade': 10.0,
      'sono': 80.0,
      'bem_estar': 90,
      'principal_ponto': 'Teste de migracao',
      'cor_valor': 123456,
      'criado_em': data,
    });

    await antigo.insert('avaliacoes', {
      'id': 20,
      'usuario_id': 1,
      'instrumento': 'GAD7',
      'versao': '1',
      'pontuacao': 5,
      'criado_em': data,
    });

    await antigo.insert('identidades_registros', {
      'id': 100,
      'usuario_id': 1,
      'tipo': 'checkin',
      'registro_local_id': 10,
      'global_id': globalId,
      'criado_em': data,
    });

    await antigo.insert('lotes_migracao', {
      'id': 'lote-valido',
      'usuario_id': 1,
      'estado': 'preparacao',
      'criado_em': data,
      'atualizado_em': data,
    });

    await antigo.insert('itens_migracao', {
      'lote_id': 'lote-valido',
      'identidade_id': 100,
      'estado': 'pendente',
      'atualizado_em': data,
    });

    expect(await antigo.getVersion(), 13);
    await antigo.close();

    // Executa a migracao real do DatabaseService.
    banco = await DatabaseService.instance.database;
  });

  tearDownAll(() async {
    await banco.close();

    if (await pasta.exists()) {
      await pasta.delete(recursive: true);
    }
  });

  test('atualiza banco valido da versao 13 para 15', () async {
    expect(await banco.getVersion(), 15);
  });

  test('preserva os dois usuarios', () async {
    final usuarios = await banco.query('usuarios');
    expect(usuarios, hasLength(2));
  });

  test('preserva checkin e proprietario', () async {
    final registros = await banco.query('checkins');
    expect(registros, hasLength(1));
    expect(registros.single['id'], 10);
    expect(registros.single['usuario_id'], 1);
    expect(registros.single['bem_estar'], 90);
  });

  test('preserva avaliacao', () async {
    final registros = await banco.query('avaliacoes');
    expect(registros, hasLength(1));
    expect(registros.single['pontuacao'], 5);
  });

  test('preserva identidade global', () async {
    final registros = await banco.query(
      'identidades_registros',
    );

    expect(registros, hasLength(1));
    expect(registros.single['global_id'], globalId);
    expect(registros.single['registro_local_id'], 10);
  });

  test('preserva lote e item de migracao', () async {
    final lotes = await banco.query('lotes_migracao');
    final itens = await banco.query('itens_migracao');

    expect(lotes, hasLength(1));
    expect(itens, hasLength(1));
    expect(lotes.single['usuario_id'], 1);
    expect(itens.single['identidade_id'], 100);
  });

  test('instala os 13 gatilhos de protecao v14 e v15', () async {
    final gatilhos = await banco.rawQuery('''
    SELECT name
    FROM sqlite_master
    WHERE type = 'trigger'
      AND (
        name LIKE 'v14_%'
        OR name LIKE 'v15_%'
      )
  ''');

    final nomes = gatilhos.map((linha) => linha['name'] as String).toSet();

    expect(gatilhos, hasLength(13));

    expect(
      nomes.where((nome) => nome.startsWith('v14_')),
      hasLength(11),
    );

    expect(
      nomes,
      containsAll([
        'v15_checkin_immutable',
        'v15_avaliacao_immutable',
      ]),
    );

    expect(nomes, isNot(contains('v14_checkin_owner')));
    expect(nomes, isNot(contains('v14_avaliacao_owner')));
  });

  test('bloqueia exclusao de checkin migrado', () async {
    await expectLater(
      banco.delete(
        'checkins',
        where: 'id = ?',
        whereArgs: [10],
      ),
      throwsA(isA<DatabaseException>()),
    );

    expect(
      await banco.query(
        'checkins',
        where: 'id = ?',
        whereArgs: [10],
      ),
      hasLength(1),
    );
  });

  test('bloqueia alteracao de proprietario', () async {
    await expectLater(
      banco.update(
        'checkins',
        {'usuario_id': 2},
        where: 'id = ?',
        whereArgs: [10],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('mantem integridade referencial', () async {
    final problemas = await banco.rawQuery(
      'PRAGMA foreign_key_check',
    );

    expect(problemas, isEmpty);
  });
}
