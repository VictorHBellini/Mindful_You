import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/core/utils/crypto_utils.dart';
import 'package:mindful_you/features/settings/services/alteracao_senha_service.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory pasta;
  late Database banco;
  late DatabaseService database;
  late AlteracaoSenhaService servico;

  var sequencia = 0;

  Future<int> criarUsuario() async {
    final numero = ++sequencia;

    return database.criarUsuario(
      nome: 'Usuario $numero',
      email: 'senha-servico-$numero@teste.invalid',
      senha: 'SenhaAtual123',
    );
  }

  Future<void> iniciarSessao(int usuarioId) async {
    SharedPreferences.setMockInitialValues({
      'usuarioId': usuarioId,
      'tipoUsuario': 'paciente',
    });
  }

  Future<Map<String, dynamic>> consultarUsuario(int id) async {
    final registros = await banco.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return registros.single;
  }

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    pasta = await Directory.systemTemp.createTemp(
      'mindful_senha_servico_',
    );

    await databaseFactoryFfi.setDatabasesPath(pasta.path);

    database = DatabaseService.instance;
    banco = await database.database;
    servico = AlteracaoSenhaService(database: database);

    expect(await banco.getVersion(), 15);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() async {
    await banco.close();

    if (await pasta.exists()) {
      await pasta.delete(recursive: true);
    }
  });

  test('rejeita alteracao sem sessao', () async {
    final resultado = await servico.executar(
      senhaAtual: 'SenhaAtual123',
      novaSenha: 'SenhaNova456',
    );

    expect(resultado, ResultadoAlteracaoSenha.sessaoInvalida);
  });

  test('rejeita senha atual incorreta', () async {
    final id = await criarUsuario();
    await iniciarSessao(id);

    final resultado = await servico.executar(
      senhaAtual: 'SenhaErrada123',
      novaSenha: 'SenhaNova456',
    );

    expect(resultado, ResultadoAlteracaoSenha.senhaAtualIncorreta);

    final usuario = await consultarUsuario(id);

    expect(
      await database.senhaCorreta(
        usuario: usuario,
        senhaDigitada: 'SenhaAtual123',
      ),
      isTrue,
    );
  });

  test('rejeita nova senha curta', () async {
    final id = await criarUsuario();
    await iniciarSessao(id);

    final resultado = await servico.executar(
      senhaAtual: 'SenhaAtual123',
      novaSenha: '123',
    );

    expect(resultado, ResultadoAlteracaoSenha.novaSenhaInvalida);
  });

  test('rejeita nova senha igual a atual', () async {
    final id = await criarUsuario();
    await iniciarSessao(id);

    final resultado = await servico.executar(
      senhaAtual: 'SenhaAtual123',
      novaSenha: 'SenhaAtual123',
    );

    expect(resultado, ResultadoAlteracaoSenha.senhaIgualAtual);
  });

  test('altera senha com sessao e senha atual validas', () async {
    final id = await criarUsuario();
    await iniciarSessao(id);

    final resultado = await servico.executar(
      senhaAtual: 'SenhaAtual123',
      novaSenha: 'SenhaNova456',
    );

    expect(resultado, ResultadoAlteracaoSenha.sucesso);

    final usuario = await consultarUsuario(id);

    expect(
      await database.senhaCorreta(
        usuario: usuario,
        senhaDigitada: 'SenhaNova456',
      ),
      isTrue,
    );

    expect(
      await database.senhaCorreta(
        usuario: usuario,
        senhaDigitada: 'SenhaAtual123',
      ),
      isFalse,
    );
  });

  test('nao altera senha de outra conta', () async {
    final contaA = await criarUsuario();
    final contaB = await criarUsuario();

    await iniciarSessao(contaA);

    final resultado = await servico.executar(
      senhaAtual: 'SenhaAtual123',
      novaSenha: 'SenhaNova456',
    );

    expect(resultado, ResultadoAlteracaoSenha.sucesso);

    final usuarioB = await consultarUsuario(contaB);

    expect(
      await database.senhaCorreta(
        usuario: usuarioB,
        senhaDigitada: 'SenhaAtual123',
      ),
      isTrue,
    );

    expect(
      await database.senhaCorreta(
        usuario: usuarioB,
        senhaDigitada: 'SenhaNova456',
      ),
      isFalse,
    );
  });

  test('altera senha legada SHA-256 sem salt', () async {
    final id = await criarUsuario();
    await iniciarSessao(id);

    await banco.update(
      'usuarios',
      {
        'senha': CryptoUtils.sha256Hex('SenhaAtual123'),
        'salt': '',
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    final resultado = await servico.executar(
      senhaAtual: 'SenhaAtual123',
      novaSenha: 'SenhaNova456',
    );

    expect(resultado, ResultadoAlteracaoSenha.sucesso);

    final usuario = await consultarUsuario(id);

    expect(
      (usuario['salt'] as String).startsWith('pbkdf2_sha256:120000:'),
      isTrue,
    );

    expect(
      await database.verificarSenhaSemMigrar(
        usuario: usuario,
        senhaDigitada: 'SenhaNova456',
      ),
      isTrue,
    );

    expect(
      await database.verificarSenhaSemMigrar(
        usuario: usuario,
        senhaDigitada: 'SenhaAtual123',
      ),
      isFalse,
    );
  });

  test('altera senha legada SHA-256 com salt', () async {
    final id = await criarUsuario();
    await iniciarSessao(id);

    const saltLegado = 'salt_legado_teste';

    await banco.update(
      'usuarios',
      {
        'senha': CryptoUtils.sha256Hex(
          '$saltLegado:SenhaAtual123',
        ),
        'salt': saltLegado,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    final resultado = await servico.executar(
      senhaAtual: 'SenhaAtual123',
      novaSenha: 'SenhaNova456',
    );

    expect(resultado, ResultadoAlteracaoSenha.sucesso);

    final usuario = await consultarUsuario(id);

    expect(
      (usuario['salt'] as String).startsWith('pbkdf2_sha256:120000:'),
      isTrue,
    );

    expect(
      await database.verificarSenhaSemMigrar(
        usuario: usuario,
        senhaDigitada: 'SenhaNova456',
      ),
      isTrue,
    );

    expect(
      await database.verificarSenhaSemMigrar(
        usuario: usuario,
        senhaDigitada: 'SenhaAtual123',
      ),
      isFalse,
    );
  });
}
