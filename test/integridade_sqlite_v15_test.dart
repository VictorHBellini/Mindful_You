import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mindful_you/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory pasta;
  late Database banco;

  late int usuario;
  late int checkinProtegido;
  late int checkinLivre;
  late int avaliacaoProtegida;
  late int avaliacaoLivre;

  const data = '2026-11-07T12:00:00';

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    pasta = await Directory.systemTemp.createTemp(
      'mindful_integridade_v15_',
    );

    await databaseFactoryFfi.setDatabasesPath(pasta.path);

    banco = await DatabaseService.instance.database;

    usuario = await banco.insert('usuarios', {
      'nome': 'Paciente Teste',
      'email': 'v15@teste.invalid',
      'senha': 'hash_ficticio',
      'salt': 'salt_teste',
      'criado_em': data,
      'tipo_usuario': 'paciente',
    });

    Future<int> criarCheckin() {
      return DatabaseService.instance.inserirCheckin(
        usuarioId: usuario,
        dataIso: '2026-11-07',
        dataFormatada: '07/11/2026',
        sentimento: 'Bem',
        emoji: '🙂',
        cansaco: 20,
        ansiedade: 10,
        sono: 80,
        bemEstar: 90,
        principalPonto: 'Teste v15',
        corValor: 123456,
      );
    }

    checkinProtegido = await criarCheckin();
    checkinLivre = await criarCheckin();

    Future<int> criarAvaliacao() {
      return banco.insert('avaliacoes', {
        'usuario_id': usuario,
        'instrumento': 'GAD7',
        'versao': '1',
        'pontuacao': 5,
        'criado_em': data,
      });
    }

    avaliacaoProtegida = await criarAvaliacao();
    avaliacaoLivre = await criarAvaliacao();

    await banco.insert('identidades_registros', {
      'usuario_id': usuario,
      'tipo': 'checkin',
      'registro_local_id': checkinProtegido,
      'global_id': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'criado_em': data,
    });

    await banco.insert('identidades_registros', {
      'usuario_id': usuario,
      'tipo': 'avaliacao',
      'registro_local_id': avaliacaoProtegida,
      'global_id': 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'criado_em': data,
    });
  });

  tearDownAll(() async {
    await banco.close();

    if (await pasta.exists()) {
      await pasta.delete(recursive: true);
    }
  });

  test('banco utiliza SQLite v15', () async {
    expect(await banco.getVersion(), 15);
  });

  test('mantem 13 gatilhos de protecao', () async {
    final gatilhos = await banco.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'trigger'
        AND (
          name LIKE 'v14_%'
          OR name LIKE 'v15_%'
        )
    ''');

    expect(gatilhos, hasLength(13));
  });

  test('bloqueia alteracao de conteudo do checkin', () async {
    await expectLater(
      banco.update(
        'checkins',
        {'bem_estar': 50},
        where: 'id = ?',
        whereArgs: [checkinProtegido],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('bloqueia alteracao de sentimento', () async {
    await expectLater(
      banco.update(
        'checkins',
        {'sentimento': 'Triste'},
        where: 'id = ?',
        whereArgs: [checkinProtegido],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('bloqueia alteracao da avaliacao', () async {
    await expectLater(
      banco.update(
        'avaliacoes',
        {'pontuacao': 15},
        where: 'id = ?',
        whereArgs: [avaliacaoProtegida],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('permite editar checkin sem identidade', () async {
    final alterados = await banco.update(
      'checkins',
      {'bem_estar': 70},
      where: 'id = ?',
      whereArgs: [checkinLivre],
    );

    expect(alterados, 1);
  });

  test('permite editar avaliacao sem identidade', () async {
    final alterados = await banco.update(
      'avaliacoes',
      {'pontuacao': 10},
      where: 'id = ?',
      whereArgs: [avaliacaoLivre],
    );

    expect(alterados, 1);
  });

  test('preserva dados do checkin protegido', () async {
    final registro = (await banco.query(
      'checkins',
      where: 'id = ?',
      whereArgs: [checkinProtegido],
    ))
        .single;

    expect(registro['bem_estar'], 90);
    expect(registro['sentimento'], 'Bem');
  });

  test('preserva dados da avaliacao protegida', () async {
    final registro = (await banco.query(
      'avaliacoes',
      where: 'id = ?',
      whereArgs: [avaliacaoProtegida],
    ))
        .single;

    expect(registro['pontuacao'], 5);
  });

  test('mantem integridade referencial', () async {
    final problemas = await banco.rawQuery(
      'PRAGMA foreign_key_check',
    );

    expect(problemas, isEmpty);
  });
}
