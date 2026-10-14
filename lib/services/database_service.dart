import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:mindful_you/services/crypto_utils.dart';

/// Serviço singleton para gerenciar o banco de dados SQLite local.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  /// Retorna a instância do banco, inicializando-o se necessário.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mindful_you.db');

    return openDatabase(
      path,
      version: 10,
      // A configuração precisa ocorrer antes das migrações/transações.
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            nome      TEXT    NOT NULL,
            email     TEXT    NOT NULL UNIQUE,
            senha     TEXT    NOT NULL,
            salt      TEXT    NOT NULL DEFAULT '',
            foto_path TEXT,
            criado_em TEXT    NOT NULL,
            tipo_usuario TEXT NOT NULL DEFAULT 'paciente' CHECK(tipo_usuario IN ('paciente','terapeuta'))
          )
        ''');
        await _criarTabelaCheckins(db);
        await _criarTabelaVinculos(db);
        await _criarTabelaAvaliacoes(db);
        await _criarIndicesOperacao(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Adiciona coluna foto_path para bancos criados na versão 1
          await db.execute(
            'ALTER TABLE usuarios ADD COLUMN foto_path TEXT',
          );
        }
        if (oldVersion < 3) {
          // Contas existentes ficam com salt = NULL. `senhaCorreta()`
          // reconhece isso, valida contra o hash antigo (sem salt) e
          // migra a conta para o novo formato automaticamente no
          // próximo login bem-sucedido.
          await db.execute(
            'ALTER TABLE usuarios ADD COLUMN salt TEXT',
          );
        }
        if (oldVersion < 4) {
          // TABELA NOVA: antes, o histórico de check-ins do questionário
          // (e os campos "último sentimento/emoji/data") ficavam apenas
          // em SharedPreferences, sob chaves globais iguais para
          // qualquer conta usada no aparelho — então, ao trocar de
          // usuário (logout + login com outra conta), cada pessoa via o
          // histórico de quem tivesse usado o app antes dela no mesmo
          // celular. Agora cada check-in é salvo aqui, vinculado ao
          // `usuario_id` de quem respondeu (ver `historico_global.dart`).
          await _criarTabelaCheckins(db);
        }
        if (oldVersion < 5) {
          // NOVAS COLUNAS: sinais de humor e energia (rastreio de
          // afeto deprimido/anedonia e de exaustão/distanciamento
          // ligados a burnout), adicionados ao questionário. Contas
          // com check-ins salvos antes desta versão simplesmente
          // ficam com essas colunas em branco ('') nesses registros
          // antigos — `historico_global.dart` trata isso como "sem
          // dado informado".
          await db.execute(
            "ALTER TABLE checkins ADD COLUMN humor_frequencia TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE checkins ADD COLUMN interesse_frequencia TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE checkins ADD COLUMN exaustao_burnout TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE checkins ADD COLUMN distanciamento_burnout TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            "ALTER TABLE usuarios ADD COLUMN tipo_usuario TEXT NOT NULL DEFAULT 'paciente'",
          );
        }
        if (oldVersion < 7) {
          await _criarTabelaVinculos(db);
        }
        if (oldVersion < 8) {
          await _criarTabelaAvaliacoes(db);
        }
        if (oldVersion < 9) {
          await db.execute('ALTER TABLE checkins ADD COLUMN operacao_id TEXT');
          await db
              .execute('ALTER TABLE avaliacoes ADD COLUMN operacao_id TEXT');
          await _criarIndicesOperacao(db);
        }
        if (oldVersion < 10) {
          // Migração de privacidade: remove respostas individuais e o
          // indicador do item sensível, mantendo somente os agregados.
          // O onUpgrade do sqflite é executado em transação.
          await db.execute('''
            CREATE TABLE avaliacoes_minimizadas (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
              instrumento TEXT NOT NULL CHECK(instrumento IN ('GAD7', 'PHQ9')),
              versao TEXT NOT NULL,
              pontuacao INTEGER NOT NULL,
              criado_em TEXT NOT NULL,
              operacao_id TEXT
            )
          ''');
          await db.execute('''
            INSERT INTO avaliacoes_minimizadas
              (id, usuario_id, instrumento, versao, pontuacao,
               criado_em, operacao_id)
            SELECT id, usuario_id, instrumento, versao, pontuacao,
                   criado_em, operacao_id FROM avaliacoes
          ''');
          await db.execute('DROP TABLE avaliacoes');
          await db.execute(
              'ALTER TABLE avaliacoes_minimizadas RENAME TO avaliacoes');
          await db.execute('CREATE INDEX idx_avaliacoes_usuario_data '
              'ON avaliacoes(usuario_id, criado_em DESC)');
          await db.execute('CREATE UNIQUE INDEX idx_avaliacoes_operacao '
              'ON avaliacoes(usuario_id, operacao_id) '
              'WHERE operacao_id IS NOT NULL');
        }
      },
    );
  }

  Future<void> _criarIndicesOperacao(Database db) async {
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_checkins_operacao '
        'ON checkins(usuario_id, operacao_id) WHERE operacao_id IS NOT NULL');
    await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_avaliacoes_operacao '
        'ON avaliacoes(usuario_id, operacao_id) WHERE operacao_id IS NOT NULL');
  }

  /// Avaliações estruturadas de demonstração, separadas dos check-ins.
  /// Itens e interpretações devem ser validados antes do uso de instrumentos.
  Future<void> _criarTabelaAvaliacoes(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avaliacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
        instrumento TEXT NOT NULL CHECK(instrumento IN ('GAD7', 'PHQ9')),
        versao TEXT NOT NULL,
        pontuacao INTEGER NOT NULL,
        criado_em TEXT NOT NULL,
        operacao_id TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_avaliacoes_usuario_data '
      'ON avaliacoes(usuario_id, criado_em DESC)',
    );
  }

  /// Vínculos locais de demonstração. Não usar para dados clínicos reais.
  Future<void> _criarTabelaVinculos(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vinculos_terapeuticos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        terapeuta_id INTEGER NOT NULL REFERENCES usuarios(id),
        paciente_id INTEGER NOT NULL REFERENCES usuarios(id),
        status TEXT NOT NULL DEFAULT 'pendente'
          CHECK(status IN ('pendente','aceito','recusado','revogado')),
        criado_em TEXT NOT NULL,
        decidido_em TEXT,
        UNIQUE(terapeuta_id, paciente_id),
        CHECK(terapeuta_id != paciente_id)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_vinculos_paciente ON vinculos_terapeuticos(paciente_id, status)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_vinculos_terapeuta ON vinculos_terapeuticos(terapeuta_id, status)');
  }

  /// Cria a tabela `checkins` (e seu índice) se ainda não existirem.
  /// Usada tanto em `onCreate` (instalação nova) quanto em `onUpgrade`
  /// (bancos já existentes na versão anterior).
  Future<void> _criarTabelaCheckins(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS checkins (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id      INTEGER NOT NULL,
        data_iso        TEXT    NOT NULL,
        data_formatada  TEXT    NOT NULL,
        sentimento      TEXT    NOT NULL DEFAULT '',
        emoji           TEXT    NOT NULL DEFAULT '',
        cansaco         REAL    NOT NULL,
        ansiedade       REAL    NOT NULL,
        sono            REAL    NOT NULL,
        produtividade   REAL    NOT NULL,
        bem_estar       INTEGER NOT NULL,
        principal_ponto TEXT    NOT NULL DEFAULT '',
        cor_valor       INTEGER NOT NULL,
        -- Sinais de humor e energia (rastreio de afeto deprimido/
        -- anedonia e de exaustão/distanciamento ligados a burnout).
        -- Cada campo guarda uma das opções de frequência do
        -- questionário ('Nunca', 'Raramente', 'Às vezes',
        -- 'Frequentemente', 'Quase sempre') ou '' se não informado.
        humor_frequencia        TEXT NOT NULL DEFAULT '',
        interesse_frequencia    TEXT NOT NULL DEFAULT '',
        exaustao_burnout        TEXT NOT NULL DEFAULT '',
        distanciamento_burnout  TEXT NOT NULL DEFAULT '',
        criado_em       TEXT    NOT NULL,
        operacao_id     TEXT,
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_checkins_usuario_id '
      'ON checkins (usuario_id)',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Utilitários
  // ─────────────────────────────────────────────────────────────

  /// Gera um salt aleatório e único (16 bytes, em hexadecimal) para uma
  /// nova senha. Usa `Random.secure()`, que é um gerador criptograficamente
  /// seguro (ao contrário de `Random()` comum).
  String gerarSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Retorna o hash SHA-256 (hexadecimal) da senha combinada com o [salt].
  /// Cada usuário tem um salt diferente, então duas contas com a mesma
  /// senha nunca geram o mesmo hash — isso protege contra ataques de
  /// rainbow table.
  String hashSenha(String senha, String salt) {
    return CryptoUtils.sha256Hex('$salt:$senha');
  }

  /// Confere se [senhaDigitada] corresponde à senha salva em [usuario]
  /// (registro vindo de `buscarPorEmail`/`listarTodos`).
  ///
  /// Contas criadas antes da migração de segurança (sem salt) ainda são
  /// validadas contra o hash antigo (sem salt); se a senha estiver
  /// correta, a conta é automaticamente migrada para o novo formato com
  /// salt nesse mesmo login, sem exigir nenhuma ação do usuário.
  Future<bool> senhaCorreta({
    required Map<String, dynamic> usuario,
    required String senhaDigitada,
  }) async {
    final String senhaArmazenada = usuario['senha'] as String;
    final String? salt = usuario['salt'] as String?;

    if (salt != null && salt.isNotEmpty) {
      return CryptoUtils.hashesIguais(
        senhaArmazenada,
        hashSenha(senhaDigitada, salt),
      );
    }

    // Conta antiga: ainda usa o hash sem salt (SHA-256 puro da senha).
    final String hashAntigo = CryptoUtils.sha256Hex(senhaDigitada);
    if (!CryptoUtils.hashesIguais(senhaArmazenada, hashAntigo)) {
      return false;
    }

    // Senha correta: migra a conta para o novo formato com salt.
    final int id = usuario['id'] as int;
    final String novoSalt = gerarSalt();
    final String novoHash = hashSenha(senhaDigitada, novoSalt);
    await _atualizarSenhaComSalt(id: id, senhaHash: novoHash, salt: novoSalt);

    return true;
  }

  /// Atualiza senha (já com hash) e salt de um usuário. Usado apenas
  /// internamente pela migração automática em [senhaCorreta].
  Future<int> _atualizarSenhaComSalt({
    required int id,
    required String senhaHash,
    required String salt,
  }) async {
    final db = await database;
    return db.update(
      'usuarios',
      {'senha': senhaHash, 'salt': salt},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────

  /// Cria um novo usuário. Retorna o ID inserido.
  /// Lança [DatabaseException] se o e-mail já existir.
  Future<int> criarUsuario({
    required String nome,
    required String email,
    required String senha,
    String tipoUsuario = 'paciente',
  }) async {
    if (tipoUsuario != 'paciente' && tipoUsuario != 'terapeuta') {
      throw ArgumentError.value(tipoUsuario, 'tipoUsuario', 'Perfil inválido');
    }
    final db = await database;
    final salt = gerarSalt();
    return db.insert(
      'usuarios',
      {
        'nome': nome.trim(),
        'email': email.trim().toLowerCase(),
        'senha': hashSenha(senha, salt),
        'salt': salt,
        'foto_path': null,
        'tipo_usuario': tipoUsuario,
        'criado_em': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────────────────────

  /// Busca usuário pelo e-mail. Retorna null se não encontrado.
  Future<Map<String, dynamic>?> buscarPorEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return result.isEmpty ? null : result.first;
  }

  /// Retorna todos os usuários cadastrados.
  Future<List<Map<String, dynamic>>> listarTodos() async {
    final db = await database;
    return db.query('usuarios', orderBy: 'id DESC');
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────

  /// Atualiza nome e e-mail do usuário com o [id] fornecido.
  Future<int> atualizarUsuario({
    required int id,
    required String nome,
    required String email,
  }) async {
    final db = await database;
    return db.update(
      'usuarios',
      {
        'nome': nome.trim(),
        'email': email.trim().toLowerCase(),
      },
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  /// Atualiza apenas o caminho da foto de perfil do usuário com o [id] fornecido.
  Future<int> atualizarFoto({
    required int id,
    required String? fotoPath,
  }) async {
    final db = await database;
    return db.update(
      'usuarios',
      {'foto_path': fotoPath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Atualiza a senha do usuário com o [id] fornecido, gerando um novo
  /// salt e hash para ela — mesmo esquema usado em `criarUsuario`. Não
  /// confere a senha atual: quem chama este método (tela de Editar
  /// Perfil) já é responsável por validar a senha atual antes, usando
  /// `senhaCorreta`.
  Future<int> atualizarSenha({
    required int id,
    required String novaSenha,
  }) async {
    final db = await database;
    final salt = gerarSalt();
    return db.update(
      'usuarios',
      {
        'senha': hashSenha(novaSenha, salt),
        'salt': salt,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────

  /// Remove o usuário com o [id] fornecido, junto com todo o seu
  /// histórico de check-ins (tabela `checkins`). Sem isso, apagar um
  /// usuário deixaria registros órfãos apontando para um `usuario_id`
  /// que não existe mais.
  Future<int> deletarUsuario(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      await txn.delete('checkins', where: 'usuario_id = ?', whereArgs: [id]);
      await txn.delete('avaliacoes', where: 'usuario_id = ?', whereArgs: [id]);
      await txn.delete(
        'vinculos_terapeuticos',
        where: 'terapeuta_id = ? OR paciente_id = ?',
        whereArgs: [id, id],
      );
      return txn.delete('usuarios', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // CHECK-INS (histórico do questionário)
  // ─────────────────────────────────────────────────────────────
  //
  // Fonte única de armazenamento do histórico de check-ins, consumida
  // por `historico_global.dart`. Cada linha pertence a um único
  // usuário (`usuario_id`), o que resolve o problema de históricos
  // "vazando" entre contas diferentes no mesmo aparelho.

  /// Salva um novo check-in do questionário para o usuário [usuarioId].
  /// Retorna o id inserido.
  Future<int> inserirCheckin({
    required int usuarioId,
    required String dataIso,
    required String dataFormatada,
    required String sentimento,
    required String emoji,
    required double cansaco,
    required double ansiedade,
    required double sono,
    required double produtividade,
    required int bemEstar,
    required String principalPonto,
    required int corValor,
    String humorFrequencia = '',
    String interesseFrequencia = '',
    String exaustaoBurnout = '',
    String distanciamentoBurnout = '',
    String? operacaoId,
  }) async {
    final db = await database;
    if (operacaoId != null && operacaoId.isEmpty) {
      throw ArgumentError('Identificador de operação vazio');
    }
    final dados = <String, Object?>{
      'usuario_id': usuarioId,
      'data_iso': dataIso,
      'data_formatada': dataFormatada,
      'sentimento': sentimento,
      'emoji': emoji,
      'cansaco': cansaco,
      'ansiedade': ansiedade,
      'sono': sono,
      'produtividade': produtividade,
      'bem_estar': bemEstar,
      'principal_ponto': principalPonto,
      'cor_valor': corValor,
      'humor_frequencia': humorFrequencia,
      'interesse_frequencia': interesseFrequencia,
      'exaustao_burnout': exaustaoBurnout,
      'distanciamento_burnout': distanciamentoBurnout,
      'criado_em': DateTime.now().toIso8601String(),
      'operacao_id': operacaoId,
    };
    if (operacaoId == null) return db.insert('checkins', dados);
    return db.transaction((txn) async {
      final existentes = await txn.query('checkins',
          columns: ['id'],
          where: 'usuario_id = ? AND operacao_id = ?',
          whereArgs: [usuarioId, operacaoId],
          limit: 1);
      if (existentes.isNotEmpty) return existentes.first['id'] as int;
      return txn.insert('checkins', dados);
    });
  }

  /// Retorna todos os check-ins do usuário [usuarioId], do mais antigo
  /// para o mais recente.
  Future<List<Map<String, dynamic>>> listarCheckins(int usuarioId) async {
    final db = await database;
    return db.query(
      'checkins',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'id ASC',
    );
  }

  /// Remove todos os check-ins salvos do usuário [usuarioId].
  Future<int> limparCheckins(int usuarioId) async {
    final db = await database;
    return db.delete(
      'checkins',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
    );
  }
}
