import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/auth/services/session_service.dart';
import 'package:mindful_you/features/settings/services/alteracao_senha_service.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseControlado extends DatabaseService {
  DatabaseControlado(super.banco) : super.paraTeste();

  final iniciouAtualizacao = Completer<void>();
  final liberarAtualizacao = Completer<void>();

  @override
  Future<int> atualizarSenhaSeInalterada({
    required int id,
    required String novaSenha,
    required String hashAnterior,
    required String saltAnterior,
  }) async {
    iniciouAtualizacao.complete();
    await liberarAtualizacao.future;

    return super.atualizarSenhaSeInalterada(
      id: id,
      novaSenha: novaSenha,
      hashAnterior: hashAnterior,
      saltAnterior: saltAnterior,
    );
  }
}

class DatabaseVerificacaoControlada extends DatabaseService {
  DatabaseVerificacaoControlada(super.banco) : super.paraTeste();

  final iniciouVerificacao = Completer<void>();
  final liberarVerificacao = Completer<void>();

  @override
  Future<bool> verificarSenhaSemMigrar({
    required Map<String, dynamic> usuario,
    required String senhaDigitada,
  }) async {
    iniciouVerificacao.complete();
    await liberarVerificacao.future;

    return super.verificarSenhaSemMigrar(
      usuario: usuario,
      senhaDigitada: senhaDigitada,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory pasta;
  late Database banco;
  late DatabaseService database;

  var sequencia = 0;

  Future<int> criarUsuario() async {
    final numero = ++sequencia;

    return database.criarUsuario(
      nome: 'Concorrencia $numero',
      email: 'concorrencia-$numero@teste.invalid',
      senha: 'SenhaAtual123',
    );
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
      'mindful_senha_concorrencia_',
    );

    await databaseFactoryFfi.setDatabasesPath(pasta.path);

    database = DatabaseService.instance;
    banco = await database.database;

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

  test('bloqueia sobrescrita de senha alterada durante a operacao', () async {
    final id = await criarUsuario();

    SharedPreferences.setMockInitialValues({
      'usuarioId': id,
      'tipoUsuario': 'paciente',
    });

    final controlado = DatabaseControlado(banco);
    final servico = AlteracaoSenhaService(database: controlado);

    final operacao = servico.executar(
      senhaAtual: 'SenhaAtual123',
      novaSenha: 'SenhaIndevida789',
    );

    await controlado.iniciouAtualizacao.future;

    try {
      await database.atualizarSenha(
        id: id,
        novaSenha: 'SenhaConcorrente456',
      );
    } finally {
      controlado.liberarAtualizacao.complete();
    }

    final resultado = await operacao;

    expect(
      resultado,
      ResultadoAlteracaoSenha.conflitoCredenciais,
    );

    final usuario = await consultarUsuario(id);

    expect(
      await database.verificarSenhaSemMigrar(
        usuario: usuario,
        senhaDigitada: 'SenhaConcorrente456',
      ),
      isTrue,
    );

    expect(
      await database.verificarSenhaSemMigrar(
        usuario: usuario,
        senhaDigitada: 'SenhaIndevida789',
      ),
      isFalse,
    );
  });

  test('bloqueia alteracao quando a sessao muda durante a verificacao',
      () async {
    final contaA = await criarUsuario();
    final contaB = await criarUsuario();

    SharedPreferences.setMockInitialValues({
      'usuarioId': contaA,
      'tipoUsuario': 'paciente',
    });

    final controlado = DatabaseVerificacaoControlada(banco);
    final servico = AlteracaoSenhaService(database: controlado);

    final operacao = servico.executar(
      senhaAtual: 'SenhaAtual123',
      novaSenha: 'SenhaIndevida789',
    );

    await controlado.iniciouVerificacao.future;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('usuarioId', contaB);
    } finally {
      controlado.liberarVerificacao.complete();
    }

    final resultado = await operacao;

    expect(
      resultado,
      ResultadoAlteracaoSenha.sessaoAlterada,
    );

    final usuarioA = await consultarUsuario(contaA);
    final usuarioB = await consultarUsuario(contaB);

    for (final usuario in [usuarioA, usuarioB]) {
      expect(
        await database.verificarSenhaSemMigrar(
          usuario: usuario,
          senhaDigitada: 'SenhaAtual123',
        ),
        isTrue,
      );

      expect(
        await database.verificarSenhaSemMigrar(
          usuario: usuario,
          senhaDigitada: 'SenhaIndevida789',
        ),
        isFalse,
      );
    }
  });

  test('troca oficial de sessao aguarda gravacao de senha', () async {
    final contaA = await criarUsuario();
    final contaB = await criarUsuario();

    SharedPreferences.setMockInitialValues({
      'usuarioId': contaA,
      'tipoUsuario': 'paciente',
    });

    final controlado = DatabaseControlado(banco);
    final servico = AlteracaoSenhaService(database: controlado);

    final operacao = servico.executar(
      senhaAtual: 'SenhaAtual123',
      novaSenha: 'SenhaNova789',
    );

    // O coordenador esta ocupado e a atualizacao ainda nao foi gravada.
    await controlado.iniciouAtualizacao.future;

    var trocaConcluida = false;
    final troca = SessionService.iniciar(
      usuarioId: contaB,
      nome: 'Conta B',
      email: 'conta-b@teste.invalid',
      tipoUsuario: 'paciente',
    ).then((_) {
      trocaConcluida = true;
    });

    // Aguarda um ciclo do event loop para detectar troca prematura.
    await Future<void>.delayed(Duration.zero);
    expect(trocaConcluida, isFalse);
    final prefsAntes = await SharedPreferences.getInstance();
    expect(prefsAntes.getInt('usuarioId'), contaA);

    // Libera a operacao antes de aguardar a troca: evita deadlock no teste.
    controlado.liberarAtualizacao.complete();
    final resultado = await operacao;
    await troca;

    expect(resultado, ResultadoAlteracaoSenha.sucesso);
    expect(trocaConcluida, isTrue);

    final prefsDepois = await SharedPreferences.getInstance();
    expect(prefsDepois.getInt('usuarioId'), contaB);

    final usuarioA = await consultarUsuario(contaA);
    final usuarioB = await consultarUsuario(contaB);

    expect(
      await database.verificarSenhaSemMigrar(
        usuario: usuarioA,
        senhaDigitada: 'SenhaNova789',
      ),
      isTrue,
    );
    expect(
      await database.verificarSenhaSemMigrar(
        usuario: usuarioA,
        senhaDigitada: 'SenhaAtual123',
      ),
      isFalse,
    );
    expect(
      await database.verificarSenhaSemMigrar(
        usuario: usuarioB,
        senhaDigitada: 'SenhaAtual123',
      ),
      isTrue,
    );
    expect(
      await database.verificarSenhaSemMigrar(
        usuario: usuarioB,
        senhaDigitada: 'SenhaNova789',
      ),
      isFalse,
    );
  });
}
