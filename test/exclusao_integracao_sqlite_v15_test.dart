import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory pasta;
  late Database banco;
  late DatabaseService servico;
  var sequencia = 0;
  const data = '2026-11-09T12:00:00';

  Future<int> criarUsuario() async {
    final numero = ++sequencia;
    return banco.insert('usuarios', {
      'nome': 'Usuario de teste $numero',
      'email': 'exclusao-v15-$numero@teste.invalid',
      'senha': 'hash_ficticio',
      'salt': 'salt_teste',
      'criado_em': data,
      'tipo_usuario': 'paciente',
    });
  }

  Future<int> criarCheckin(int usuarioId) {
    return servico.inserirCheckin(
      usuarioId: usuarioId,
      dataIso: '2026-11-09',
      dataFormatada: '09/11/2026',
      sentimento: 'Bem',
      emoji: '🙂',
      cansaco: 20,
      ansiedade: 10,
      sono: 80,
      bemEstar: 90,
      principalPonto: 'Teste de exclusao v15',
      corValor: 123456,
    );
  }

  Future<void> verificarIntegridade() async {
    expect(await banco.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  }

  Future<void> verificarUsuarioPreservado(int usuarioId) async {
    expect(
      await banco.query('usuarios', where: 'id = ?', whereArgs: [usuarioId]),
      hasLength(1),
    );
  }

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    pasta = await Directory.systemTemp.createTemp('mindful_exclusao_v15_');
    await databaseFactoryFfi.setDatabasesPath(pasta.path);
    // Abre o esquema real v15 e instala os gatilhos de producao.
    banco = await DatabaseService.instance.database;
    servico = DatabaseService.instance;
    expect(await banco.getVersion(), 15);
    expect(await banco.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  tearDownAll(() async {
    await banco.close();
    if (await pasta.exists()) {
      await pasta.delete(recursive: true);
    }
  });

  test('exclui conta local comum e preserva outro usuario', () async {
    final alvo = await criarUsuario();
    final outro = await criarUsuario();
    await criarCheckin(alvo);
    final checkinOutro = await criarCheckin(outro);

    expect(await servico.deletarUsuarioLocalSemVinculo(alvo), 1);
    expect(await banco.query('usuarios', where: 'id = ?', whereArgs: [alvo]),
        isEmpty);
    expect(
        await banco
            .query('checkins', where: 'usuario_id = ?', whereArgs: [alvo]),
        isEmpty);
    await verificarUsuarioPreservado(outro);
    expect(
        await banco
            .query('checkins', where: 'id = ?', whereArgs: [checkinOutro]),
        hasLength(1));
    await verificarIntegridade();
  });

  for (final estado in ['pendente', 'confirmado', 'revogado']) {
    test('bloqueia conta com vinculo Firebase $estado', () async {
      final alvo = await criarUsuario();
      final checkin = await criarCheckin(alvo);
      await banco.insert('vinculos_contas_firebase', {
        'usuario_id': alvo,
        'firebase_uid': 'uid-exclusao-$estado-$alvo',
        'estado': estado,
        'criado_em': data,
        'confirmado_em': estado == 'confirmado' ? data : null,
        'revogado_em': estado == 'revogado' ? data : null,
      });

      await expectLater(
        servico.deletarUsuarioLocalSemVinculo(alvo),
        throwsA(isA<StateError>()),
      );
      await verificarUsuarioPreservado(alvo);
      expect(
          await banco.query('checkins', where: 'id = ?', whereArgs: [checkin]),
          hasLength(1));
      expect(
          await banco.query('vinculos_contas_firebase',
              where: 'usuario_id = ?', whereArgs: [alvo]),
          hasLength(1));
      await verificarIntegridade();
    });
  }

  test('bloqueia conta com check-in identificado', () async {
    final alvo = await criarUsuario();
    final checkin = await criarCheckin(alvo);
    await banco.insert('identidades_registros', {
      'usuario_id': alvo,
      'tipo': 'checkin',
      'registro_local_id': checkin,
      'global_id': alvo.toRadixString(16).padLeft(32, '0'),
      'criado_em': data,
    });

    await expectLater(servico.deletarUsuarioLocalSemVinculo(alvo),
        throwsA(isA<StateError>()));
    await verificarUsuarioPreservado(alvo);
    expect(await banco.query('checkins', where: 'id = ?', whereArgs: [checkin]),
        hasLength(1));
    expect(
        await banco.query('identidades_registros',
            where: 'usuario_id = ?', whereArgs: [alvo]),
        hasLength(1));
    await verificarIntegridade();
  });

  test('bloqueia conta com lote de migracao', () async {
    final alvo = await criarUsuario();
    await banco.insert('lotes_migracao', {
      'id': 'lote-exclusao-v15-$alvo',
      'usuario_id': alvo,
      'estado': 'preparacao',
      'criado_em': data,
      'atualizado_em': data,
    });

    await expectLater(servico.deletarUsuarioLocalSemVinculo(alvo),
        throwsA(isA<StateError>()));
    await verificarUsuarioPreservado(alvo);
    expect(
        await banco.query('lotes_migracao',
            where: 'usuario_id = ?', whereArgs: [alvo]),
        hasLength(1));
    await verificarIntegridade();
  });

  test('reverte toda a exclusao se um gatilho causar falha', () async {
    final alvo = await criarUsuario();
    final checkin = await criarCheckin(alvo);
    final outro = await criarUsuario();
    final checkinOutro = await criarCheckin(outro);
    const gatilho = 'teste_exclusao_v15_rollback';
    await banco.execute('''
      CREATE TRIGGER $gatilho BEFORE DELETE ON usuarios
      WHEN OLD.id = $alvo
      BEGIN
        SELECT RAISE(ABORT, 'falha simulada de exclusao');
      END
    ''');
    try {
      await expectLater(
        servico.deletarUsuarioLocalSemVinculo(alvo),
        throwsA(isA<DatabaseException>()),
      );
      await verificarUsuarioPreservado(alvo);
      expect(
          await banco.query('checkins', where: 'id = ?', whereArgs: [checkin]),
          hasLength(1));
      await verificarUsuarioPreservado(outro);
      expect(
          await banco
              .query('checkins', where: 'id = ?', whereArgs: [checkinOutro]),
          hasLength(1));
      await verificarIntegridade();
    } finally {
      await banco.execute('DROP TRIGGER IF EXISTS $gatilho');
    }
  });

  test('usuario inexistente retorna zero sem afetar outros dados', () async {
    final outro = await criarUsuario();
    expect(await servico.deletarUsuarioLocalSemVinculo(99999999), 0);
    await verificarUsuarioPreservado(outro);
    await verificarIntegridade();
  });
  for (final estado in ['pendente', 'confirmado', 'revogado']) {
    test('exclusao administrativa bloqueia vinculo Firebase $estado', () async {
      final alvo = await criarUsuario();
      final checkin = await criarCheckin(alvo);
      await banco.insert('vinculos_contas_firebase', {
        'usuario_id': alvo,
        'firebase_uid': 'uid-admin-$estado-$alvo',
        'estado': estado,
        'criado_em': data,
        'confirmado_em': estado == 'confirmado' ? data : null,
        'revogado_em': estado == 'revogado' ? data : null,
      });
      await expectLater(
          servico.deletarUsuario(alvo), throwsA(isA<StateError>()));
      await verificarUsuarioPreservado(alvo);
      expect(
          await banco.query('checkins', where: 'id = ?', whereArgs: [checkin]),
          hasLength(1));
      expect(
          await banco.query('vinculos_contas_firebase',
              where: 'usuario_id = ?', whereArgs: [alvo]),
          hasLength(1));
      await verificarIntegridade();
    });
  }

  test('exclusao administrativa preserva conta sem vinculos', () async {
    final alvo = await criarUsuario();
    final outro = await criarUsuario();
    await criarCheckin(alvo);
    final checkinOutro = await criarCheckin(outro);
    expect(await servico.deletarUsuario(alvo), 1);
    expect(await banco.query('usuarios', where: 'id = ?', whereArgs: [alvo]),
        isEmpty);
    await verificarUsuarioPreservado(outro);
    expect(
        await banco
            .query('checkins', where: 'id = ?', whereArgs: [checkinOutro]),
        hasLength(1));
    await verificarIntegridade();
  });
}
