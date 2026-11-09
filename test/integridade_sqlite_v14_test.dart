import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mindful_you/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory pastaTemporaria;
  late Database banco;
  late int usuarioA;
  late int usuarioB;
  late int checkinA;
  late int avaliacaoA;
  late int identidadeCheckin;
  late int identidadeAvaliacao;

  const data = '2026-11-05T12:00:00';

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    pastaTemporaria = await Directory.systemTemp.createTemp(
      'mindful_integridade_v14_',
    );

    await databaseFactoryFfi.setDatabasesPath(
      pastaTemporaria.path,
    );

    banco = await DatabaseService.instance.database;

    expect(await banco.getVersion(), 15);

    Future<int> criarUsuario(String email) {
      return banco.insert('usuarios', {
        'nome': email,
        'email': email,
        'senha': 'hash_ficticio',
        'salt': 'salt_teste',
        'criado_em': data,
        'tipo_usuario': 'paciente',
      });
    }

    usuarioA = await criarUsuario('integridade-a@teste.invalid');
    usuarioB = await criarUsuario('integridade-b@teste.invalid');

    checkinA = await DatabaseService.instance.inserirCheckin(
      usuarioId: usuarioA,
      dataIso: '2026-11-05',
      dataFormatada: '05/11/2026',
      sentimento: 'Bem',
      emoji: '🙂',
      cansaco: 20,
      ansiedade: 10,
      sono: 80,
      bemEstar: 90,
      principalPonto: 'Teste de integridade',
      corValor: 0xFFE8DCD4,
    );

    avaliacaoA = await banco.insert('avaliacoes', {
      'usuario_id': usuarioA,
      'instrumento': 'GAD7',
      'versao': '1',
      'pontuacao': 5,
      'criado_em': data,
    });

    identidadeCheckin = await banco.insert(
      'identidades_registros',
      {
        'usuario_id': usuarioA,
        'tipo': 'checkin',
        'registro_local_id': checkinA,
        'global_id': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'criado_em': data,
      },
    );

    identidadeAvaliacao = await banco.insert(
      'identidades_registros',
      {
        'usuario_id': usuarioA,
        'tipo': 'avaliacao',
        'registro_local_id': avaliacaoA,
        'global_id': 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        'criado_em': data,
      },
    );

    await banco.insert('lotes_migracao', {
      'id': 'lote-usuario-a',
      'usuario_id': usuarioA,
      'estado': 'preparacao',
      'criado_em': data,
      'atualizado_em': data,
    });

    await banco.insert('lotes_migracao', {
      'id': 'lote-usuario-b',
      'usuario_id': usuarioB,
      'estado': 'preparacao',
      'criado_em': data,
      'atualizado_em': data,
    });

    await banco.insert('itens_migracao', {
      'lote_id': 'lote-usuario-a',
      'identidade_id': identidadeCheckin,
      'estado': 'pendente',
      'atualizado_em': data,
    });
  });

  tearDownAll(() async {
    await banco.close();

    if (await pastaTemporaria.exists()) {
      await pastaTemporaria.delete(recursive: true);
    }
  });

  test('SQLite v15 preserva as protecoes de integridade v14', () async {
    expect(await banco.getVersion(), 15);
  });

  test('rejeita identidade de outro proprietario', () async {
    await expectLater(
      banco.insert('identidades_registros', {
        'usuario_id': usuarioB,
        'tipo': 'checkin',
        'registro_local_id': checkinA,
        'global_id': 'cccccccccccccccccccccccccccccccc',
        'criado_em': data,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('bloqueia alteracao do proprietario do checkin', () async {
    await expectLater(
      banco.update(
        'checkins',
        {'usuario_id': usuarioB},
        where: 'id = ?',
        whereArgs: [checkinA],
      ),
      throwsA(isA<DatabaseException>()),
    );

    final registro = (await banco.query(
      'checkins',
      where: 'id = ?',
      whereArgs: [checkinA],
    ))
        .single;

    expect(registro['usuario_id'], usuarioA);
  });

  test('bloqueia exclusao de checkin identificado', () async {
    await expectLater(
      banco.delete(
        'checkins',
        where: 'id = ?',
        whereArgs: [checkinA],
      ),
      throwsA(isA<DatabaseException>()),
    );

    expect(
      await banco.query(
        'checkins',
        where: 'id = ?',
        whereArgs: [checkinA],
      ),
      hasLength(1),
    );
  });

  test('bloqueia alteracao do proprietario da avaliacao', () async {
    await expectLater(
      banco.update(
        'avaliacoes',
        {'usuario_id': usuarioB},
        where: 'id = ?',
        whereArgs: [avaliacaoA],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('bloqueia exclusao de avaliacao identificada', () async {
    await expectLater(
      banco.delete(
        'avaliacoes',
        where: 'id = ?',
        whereArgs: [avaliacaoA],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('bloqueia alteracao de identidade existente', () async {
    await expectLater(
      banco.update(
        'identidades_registros',
        {'usuario_id': usuarioB},
        where: 'id = ?',
        whereArgs: [identidadeCheckin],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('bloqueia exclusao de identidade', () async {
    await expectLater(
      banco.delete(
        'identidades_registros',
        where: 'id = ?',
        whereArgs: [identidadeAvaliacao],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('rejeita item associado a usuario diferente', () async {
    await expectLater(
      banco.insert('itens_migracao', {
        'lote_id': 'lote-usuario-b',
        'identidade_id': identidadeAvaliacao,
        'estado': 'pendente',
        'atualizado_em': data,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('bloqueia troca de proprietario do lote', () async {
    await expectLater(
      banco.update(
        'lotes_migracao',
        {'usuario_id': usuarioB},
        where: 'id = ?',
        whereArgs: ['lote-usuario-a'],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('bloqueia exclusao de lote com itens', () async {
    await expectLater(
      banco.delete(
        'lotes_migracao',
        where: 'id = ?',
        whereArgs: ['lote-usuario-a'],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('bloqueia alteracao da associacao do item', () async {
    await expectLater(
      banco.update(
        'itens_migracao',
        {'lote_id': 'lote-usuario-b'},
        where: 'lote_id = ? AND identidade_id = ?',
        whereArgs: ['lote-usuario-a', identidadeCheckin],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('bloqueia exclusao de item protegido', () async {
    await expectLater(
      banco.delete(
        'itens_migracao',
        where: 'lote_id = ? AND identidade_id = ?',
        whereArgs: ['lote-usuario-a', identidadeCheckin],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('bloqueia exclusao de usuario com migracao', () async {
    await expectLater(
      banco.delete(
        'usuarios',
        where: 'id = ?',
        whereArgs: [usuarioA],
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('mantem integridade das chaves estrangeiras', () async {
    final problemas = await banco.rawQuery(
      'PRAGMA foreign_key_check',
    );

    expect(problemas, isEmpty);
  });

  test('preserva registros apos operacoes bloqueadas', () async {
    expect(
      await banco.query(
        'identidades_registros',
        where: 'usuario_id = ?',
        whereArgs: [usuarioA],
      ),
      hasLength(2),
    );

    expect(
      await banco.query(
        'itens_migracao',
        where: 'lote_id = ?',
        whereArgs: ['lote-usuario-a'],
      ),
      hasLength(1),
    );
  });

  test('rollback preserva lote e item apos falha na transacao', () async {
    final loteAntes = (await banco.query(
      'lotes_migracao',
      where: 'id = ?',
      whereArgs: ['lote-usuario-a'],
    ))
        .single;

    final itensAntes = await banco.query(
      'itens_migracao',
      where: 'lote_id = ?',
      whereArgs: ['lote-usuario-a'],
    );

    expect(itensAntes, hasLength(1));

    await expectLater(
      banco.transaction((txn) async {
        // Alteracao inicialmente permitida.
        await txn.update(
          'lotes_migracao',
          {'estado': 'em_andamento'},
          where: 'id = ?',
          whereArgs: ['lote-usuario-a'],
        );

        // Operacao proibida pelo gatilho de integridade.
        await txn.delete(
          'itens_migracao',
          where: 'lote_id = ? AND identidade_id = ?',
          whereArgs: ['lote-usuario-a', identidadeCheckin],
        );
      }),
      throwsA(isA<DatabaseException>()),
    );

    final loteDepois = (await banco.query(
      'lotes_migracao',
      where: 'id = ?',
      whereArgs: ['lote-usuario-a'],
    ))
        .single;

    final itensDepois = await banco.query(
      'itens_migracao',
      where: 'lote_id = ?',
      whereArgs: ['lote-usuario-a'],
    );

    // A alteracao anterior deve ter sido revertida.
    expect(loteDepois['estado'], loteAntes['estado']);

    // Nenhuma associacao pode ser perdida.
    expect(itensDepois, hasLength(itensAntes.length));
    expect(
      itensDepois.single['identidade_id'],
      identidadeCheckin,
    );

    // A identidade original continua preservada.
    expect(
      await banco.query(
        'identidades_registros',
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [identidadeCheckin, usuarioA],
      ),
      hasLength(1),
    );

    // O banco permanece consistente.
    expect(
      await banco.rawQuery('PRAGMA foreign_key_check'),
      isEmpty,
    );
  });
}
