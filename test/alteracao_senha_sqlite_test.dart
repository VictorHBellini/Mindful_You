import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory pasta;
  late Database banco;
  late DatabaseService servico;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    pasta = await Directory.systemTemp.createTemp(
      'mindful_alteracao_senha_',
    );

    await databaseFactoryFfi.setDatabasesPath(pasta.path);

    banco = await DatabaseService.instance.database;
    servico = DatabaseService.instance;

    expect(await banco.getVersion(), 15);
  });

  tearDownAll(() async {
    await banco.close();

    if (await pasta.exists()) {
      await pasta.delete(recursive: true);
    }
  });

  test('altera senha quando credenciais anteriores conferem', () async {
    final id = await servico.criarUsuario(
      nome: 'Teste Senha',
      email: 'alteracao1@teste.invalid',
      senha: 'SenhaAntiga123',
    );

    final antes = (await banco.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    ))
        .single;

    final alterados = await servico.atualizarSenhaSeInalterada(
      id: id,
      novaSenha: 'SenhaNova456',
      hashAnterior: antes['senha'] as String,
      saltAnterior: antes['salt'] as String,
    );

    expect(alterados, 1);

    final depois = (await banco.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    ))
        .single;

    expect(
      await servico.senhaCorreta(
        usuario: depois,
        senhaDigitada: 'SenhaNova456',
      ),
      isTrue,
    );

    expect(
      await servico.senhaCorreta(
        usuario: depois,
        senhaDigitada: 'SenhaAntiga123',
      ),
      isFalse,
    );
  });

  test('bloqueia sobrescrita quando credenciais mudaram', () async {
    final id = await servico.criarUsuario(
      nome: 'Teste Concorrencia',
      email: 'alteracao2@teste.invalid',
      senha: 'SenhaOriginal123',
    );

    final antes = (await banco.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    ))
        .single;

    await servico.atualizarSenha(
      id: id,
      novaSenha: 'SenhaIntermediaria456',
    );

    final alterados = await servico.atualizarSenhaSeInalterada(
      id: id,
      novaSenha: 'SenhaIndevida789',
      hashAnterior: antes['senha'] as String,
      saltAnterior: antes['salt'] as String,
    );

    expect(alterados, 0);

    final depois = (await banco.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    ))
        .single;

    expect(
      await servico.senhaCorreta(
        usuario: depois,
        senhaDigitada: 'SenhaIntermediaria456',
      ),
      isTrue,
    );

    expect(
      await servico.senhaCorreta(
        usuario: depois,
        senhaDigitada: 'SenhaIndevida789',
      ),
      isFalse,
    );
  });

  test('rejeita nova senha curta', () async {
    expect(
      () => servico.atualizarSenhaSeInalterada(
        id: 1,
        novaSenha: '123',
        hashAnterior: 'hash',
        saltAnterior: 'salt',
      ),
      throwsArgumentError,
    );
  });
}
