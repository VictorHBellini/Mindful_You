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

  setUpAll(() async {
    sqfliteFfiInit();
    pastaTemporaria =
        await Directory.systemTemp.createTemp('mindful_sqlite_test_');
    databaseFactory = databaseFactoryFfi;
    await databaseFactoryFfi.setDatabasesPath(pastaTemporaria.path);

    // A inicialização real cria o esquema v12 apenas dentro da pasta temporária.
    banco = await DatabaseService.instance.database;
    final versao = await banco.getVersion();
    expect(versao, 12);

    Future<int> criarUsuarioTeste(String email) => banco.insert('usuarios', {
          'nome': email,
          'email': email,
          'senha': 'hash_ficticio_apenas_para_teste',
          'salt': 'salt_teste',
          'criado_em': '2026-10-17T12:00:00',
          'tipo_usuario': 'paciente',
        });

    usuarioA = await criarUsuarioTeste('a@teste.invalid');
    usuarioB = await criarUsuarioTeste('b@teste.invalid');
  });

  tearDownAll(() async {
    await banco.close();
    if (await pastaTemporaria.exists()) {
      await pastaTemporaria.delete(recursive: true);
    }
  });

  Future<int> salvar(int usuarioId, String operacaoId) {
    return DatabaseService.instance.inserirCheckin(
      usuarioId: usuarioId,
      dataIso: '2026-10-17T12:00:00',
      dataFormatada: '17/10/2026',
      sentimento: 'Bem',
      emoji: '🙂',
      cansaco: 30,
      ansiedade: 20,
      sono: 10,
      produtividade: null,
      atividadeSignificativa: 'Prefiro não responder',
      bemEstar: 80,
      principalPonto: 'Cansaço estimado',
      corValor: 0xFFE8DCD4,
      humorFrequencia: '',
      interesseFrequencia: '',
      exaustaoBurnout: '',
      distanciamentoBurnout: '',
      operacaoId: operacaoId,
    );
  }

  test('SQLite v12 salva e recupera um check-in do usuário correto', () async {
    await salvar(usuarioA, 'teste-usuario-a-1');
    final registros = await DatabaseService.instance.listarCheckins(usuarioA);
    expect(registros, hasLength(1));
    expect(registros.single['bem_estar'], 80);
    expect(
        registros.single['atividade_significativa'], 'Prefiro não responder');
  });

  test('SQLite mantém históricos separados por usuário', () async {
    await salvar(usuarioB, 'teste-usuario-b-1');
    final a = await DatabaseService.instance.listarCheckins(usuarioA);
    final b = await DatabaseService.instance.listarCheckins(usuarioB);
    expect(a, hasLength(1));
    expect(b, hasLength(1));
    expect(a.single['usuario_id'], usuarioA);
    expect(b.single['usuario_id'], usuarioB);
  });

  test('limpar check-ins de um usuário preserva os do outro', () async {
    await DatabaseService.instance.limparCheckins(usuarioA);
    expect(await DatabaseService.instance.listarCheckins(usuarioA), isEmpty);
    expect(
        await DatabaseService.instance.listarCheckins(usuarioB), hasLength(1));
  });
}
