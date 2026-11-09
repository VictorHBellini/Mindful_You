import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mindful_you/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory pasta;
  late Database banco;
  late int usuarioA;
  late int usuarioB;
  late int checkinProtegido;
  late int checkinLivre;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    pasta = await Directory.systemTemp.createTemp(
      'mindful_limpeza_v15_',
    );

    await databaseFactoryFfi.setDatabasesPath(pasta.path);

    banco = await DatabaseService.instance.database;

    Future<int> criarUsuario(String email) {
      return banco.insert('usuarios', {
        'nome': email,
        'email': email,
        'senha': 'hash_ficticio',
        'salt': 'salt_teste',
        'criado_em': '2026-11-09T12:00:00',
        'tipo_usuario': 'paciente',
      });
    }

    usuarioA = await criarUsuario('limpeza-a@teste.invalid');
    usuarioB = await criarUsuario('limpeza-b@teste.invalid');

    Future<int> criarCheckin(int usuarioId) {
      return DatabaseService.instance.inserirCheckin(
        usuarioId: usuarioId,
        dataIso: '2026-11-09',
        dataFormatada: '09/11/2026',
        sentimento: 'Bem',
        emoji: '🙂',
        cansaco: 20,
        ansiedade: 10,
        sono: 80,
        bemEstar: 90,
        principalPonto: 'Teste limpeza',
        corValor: 123456,
      );
    }

    checkinProtegido = await criarCheckin(usuarioA);
    checkinLivre = await criarCheckin(usuarioA);
    await criarCheckin(usuarioB);

    await banco.insert('identidades_registros', {
      'usuario_id': usuarioA,
      'tipo': 'checkin',
      'registro_local_id': checkinProtegido,
      'global_id': 'cccccccccccccccccccccccccccccccc',
      'criado_em': '2026-11-09T12:00:00',
    });
  });

  tearDownAll(() async {
    await banco.close();

    if (await pasta.exists()) {
      await pasta.delete(recursive: true);
    }
  });

  test('bloqueia limpeza quando existe checkin protegido', () async {
    await expectLater(
      DatabaseService.instance.limparCheckins(usuarioA),
      throwsStateError,
    );
  });

  test('preserva todos os checkins apos bloqueio', () async {
    final registros = await DatabaseService.instance.listarCheckins(usuarioA);

    expect(registros, hasLength(2));

    final ids = registros.map((r) => r['id']).toSet();

    expect(ids, contains(checkinProtegido));
    expect(ids, contains(checkinLivre));
  });

  test('permite limpar usuario sem identidades', () async {
    final removidos = await DatabaseService.instance.limparCheckins(usuarioB);

    expect(removidos, 1);

    expect(
      await DatabaseService.instance.listarCheckins(usuarioB),
      isEmpty,
    );
  });

  test('nao altera historicos de outro usuario', () async {
    final registros = await DatabaseService.instance.listarCheckins(usuarioA);

    expect(registros, hasLength(2));
  });

  test('rejeita usuario com ID invalido', () async {
    await expectLater(
      DatabaseService.instance.limparCheckins(0),
      throwsArgumentError,
    );
  });

  test('mantem integridade referencial', () async {
    final problemas = await banco.rawQuery(
      'PRAGMA foreign_key_check',
    );

    expect(problemas, isEmpty);
  });
}
