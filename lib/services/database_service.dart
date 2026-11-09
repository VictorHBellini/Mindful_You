import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:mindful_you/core/utils/crypto_utils.dart';

class DatabaseService {
  DatabaseService._internal();

  DatabaseService.paraTeste(Database banco) : _db = banco;

  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

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
      version: 15,
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
        await _criarTabelaVinculosFirebase(db);
        await _criarTabelasMigracaoV13(db);
        await _instalarProtecoesV14(db);
        await _instalarProtecoesV15(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE usuarios ADD COLUMN foto_path TEXT',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE usuarios ADD COLUMN salt TEXT',
          );
        }
        if (oldVersion < 4) {
          await _criarTabelaCheckins(db);
        }
        if (oldVersion < 5) {
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
        if (oldVersion < 11) {
          await _criarTabelaVinculosFirebase(db);
        }
        if (oldVersion < 12) {
          await db
              .execute('ALTER TABLE checkins RENAME TO checkins_legado_v11');
          await db.execute('DROP INDEX IF EXISTS idx_checkins_usuario_id');
          await db.execute('DROP INDEX IF EXISTS idx_checkins_operacao');
          await _criarTabelaCheckins(db);
          await db.execute('''
            INSERT INTO checkins (
              id, usuario_id, data_iso, data_formatada, sentimento, emoji,
              cansaco, ansiedade, sono, produtividade, bem_estar,
              principal_ponto, cor_valor, humor_frequencia,
              interesse_frequencia, exaustao_burnout, distanciamento_burnout,
              criado_em, operacao_id
            ) SELECT
              id, usuario_id, data_iso, data_formatada, sentimento, emoji,
              cansaco, ansiedade, sono, produtividade, bem_estar,
              principal_ponto, cor_valor, humor_frequencia,
              interesse_frequencia, exaustao_burnout, distanciamento_burnout,
              criado_em, operacao_id FROM checkins_legado_v11
          ''');
          await db.execute('DROP TABLE checkins_legado_v11');
          await _criarIndicesOperacao(db);
        }
        if (oldVersion < 13) {
          await _criarTabelasMigracaoV13(db);
        }
        if (oldVersion < 14) {
          await _instalarProtecoesV14(db);
        }

        if (oldVersion < 15) {
          await _instalarProtecoesV15(db);
        }
      },
    );
  }

  // SQLite v14: toda a instalação ocorre dentro da transação de abertura
  // gerenciada pelo sqflite. Qualquer erro aborta a atualização.
  Future<void> _instalarProtecoesV14(Database db) async {
    Future<void> exigirVazio(String sql, String mensagem) async {
      final resultado = await db.rawQuery(sql);
      if (resultado.isNotEmpty) {
        throw StateError('SQLite v14: $mensagem');
      }
    }

    // Auditar ANTES de instalar gatilhos; nunca reparar dados automaticamente.
    await exigirVazio('''
      SELECT i.id FROM identidades_registros i
      LEFT JOIN usuarios u ON u.id = i.usuario_id
      LEFT JOIN checkins c ON i.tipo = 'checkin'
        AND c.id = i.registro_local_id AND c.usuario_id = i.usuario_id
      LEFT JOIN avaliacoes a ON i.tipo = 'avaliacao'
        AND a.id = i.registro_local_id AND a.usuario_id = i.usuario_id
      WHERE u.id IS NULL OR (i.tipo = 'checkin' AND c.id IS NULL)
        OR (i.tipo = 'avaliacao' AND a.id IS NULL)
    ''', 'identidade órfã ou com proprietário divergente');
    await exigirVazio('''
      SELECT it.lote_id FROM itens_migracao it
      LEFT JOIN lotes_migracao l ON l.id = it.lote_id
      LEFT JOIN identidades_registros i ON i.id = it.identidade_id
      WHERE l.id IS NULL OR i.id IS NULL OR l.usuario_id != i.usuario_id
    ''', 'item de migração órfão ou vinculado a outro usuário');
    await exigirVazio('''
      SELECT l.id FROM lotes_migracao l
      LEFT JOIN usuarios u ON u.id = l.usuario_id
      WHERE u.id IS NULL
    ''', 'lote de migração sem usuário');
    await exigirVazio('''
      SELECT c.id FROM checkins c LEFT JOIN usuarios u ON u.id = c.usuario_id
      WHERE u.id IS NULL
      UNION ALL
      SELECT a.id FROM avaliacoes a LEFT JOIN usuarios u ON u.id = a.usuario_id
      WHERE u.id IS NULL
    ''', 'histórico sem usuário');
    await exigirVazio('PRAGMA foreign_key_check',
        'violação de chave estrangeira no banco existente');

    final gatilhos = <String>[
      // Identidades só podem referenciar histórico do mesmo proprietário.
      '''CREATE TRIGGER v14_identidade_insert BEFORE INSERT ON identidades_registros
      BEGIN
        SELECT RAISE(ABORT, 'v14: identidade sem historico do proprietario')
        WHERE NOT EXISTS (
          SELECT 1 FROM checkins c WHERE NEW.tipo = 'checkin'
            AND c.id = NEW.registro_local_id AND c.usuario_id = NEW.usuario_id
          UNION ALL
          SELECT 1 FROM avaliacoes a WHERE NEW.tipo = 'avaliacao'
            AND a.id = NEW.registro_local_id AND a.usuario_id = NEW.usuario_id
        );
      END''',
      '''CREATE TRIGGER v14_identidade_update BEFORE UPDATE ON identidades_registros
      BEGIN SELECT RAISE(ABORT, 'v14: identidade imutavel'); END''',
      '''CREATE TRIGGER v14_identidade_delete BEFORE DELETE ON identidades_registros
      BEGIN SELECT RAISE(ABORT, 'v14: identidade protegida'); END''',
      '''CREATE TRIGGER v14_checkin_owner BEFORE UPDATE OF usuario_id, id ON checkins
      WHEN EXISTS (SELECT 1 FROM identidades_registros i
        WHERE i.tipo = 'checkin' AND i.registro_local_id = OLD.id)
      BEGIN SELECT RAISE(ABORT, 'v14: proprietario de checkin protegido'); END''',
      '''CREATE TRIGGER v14_checkin_delete BEFORE DELETE ON checkins
      WHEN EXISTS (SELECT 1 FROM identidades_registros i
        WHERE i.tipo = 'checkin' AND i.registro_local_id = OLD.id)
      BEGIN SELECT RAISE(ABORT, 'v14: checkin com identidade protegida'); END''',
      '''CREATE TRIGGER v14_avaliacao_owner BEFORE UPDATE OF usuario_id, id ON avaliacoes
      WHEN EXISTS (SELECT 1 FROM identidades_registros i
        WHERE i.tipo = 'avaliacao' AND i.registro_local_id = OLD.id)
      BEGIN SELECT RAISE(ABORT, 'v14: proprietario de avaliacao protegido'); END''',
      '''CREATE TRIGGER v14_avaliacao_delete BEFORE DELETE ON avaliacoes
      WHEN EXISTS (SELECT 1 FROM identidades_registros i
        WHERE i.tipo = 'avaliacao' AND i.registro_local_id = OLD.id)
      BEGIN SELECT RAISE(ABORT, 'v14: avaliacao com identidade protegida'); END''',
      '''CREATE TRIGGER v14_lote_owner BEFORE UPDATE OF usuario_id, id ON lotes_migracao
      BEGIN SELECT RAISE(ABORT, 'v14: proprietario ou id de lote imutavel'); END''',
      '''CREATE TRIGGER v14_lote_delete BEFORE DELETE ON lotes_migracao
      WHEN EXISTS (SELECT 1 FROM itens_migracao WHERE lote_id = OLD.id)
      BEGIN SELECT RAISE(ABORT, 'v14: lote com itens protegido'); END''',
      '''CREATE TRIGGER v14_item_insert BEFORE INSERT ON itens_migracao
      BEGIN
        SELECT RAISE(ABORT, 'v14: item de outro proprietario')
        WHERE NOT EXISTS (
          SELECT 1 FROM lotes_migracao l JOIN identidades_registros i
            ON i.usuario_id = l.usuario_id
          WHERE l.id = NEW.lote_id AND i.id = NEW.identidade_id
        );
      END''',
      '''CREATE TRIGGER v14_item_update BEFORE UPDATE OF lote_id, identidade_id ON itens_migracao
      BEGIN SELECT RAISE(ABORT, 'v14: associacao de item imutavel'); END''',
      '''CREATE TRIGGER v14_item_delete BEFORE DELETE ON itens_migracao
      BEGIN SELECT RAISE(ABORT, 'v14: associacao de item protegida'); END''',
      '''CREATE TRIGGER v14_usuario_delete BEFORE DELETE ON usuarios
      WHEN EXISTS (SELECT 1 FROM identidades_registros WHERE usuario_id = OLD.id)
        OR EXISTS (SELECT 1 FROM lotes_migracao WHERE usuario_id = OLD.id)
      BEGIN SELECT RAISE(ABORT, 'v14: usuario com migracao protegida'); END''',
    ];
    for (final gatilho in gatilhos) {
      await db.execute(gatilho);
    }
  }

  // SQLite v15: impede qualquer alteracao em historicos identificados.
  // A instalacao e atomica durante onCreate/onUpgrade do sqflite.
  Future<void> _instalarProtecoesV15(Database db) async {
    final existentes = await db.rawQuery('''
      SELECT name FROM sqlite_master
      WHERE type = 'trigger'
        AND name IN ('v14_checkin_owner', 'v14_avaliacao_owner')
    ''');

    if (existentes.length != 2) {
      throw StateError('SQLite v15: gatilhos de propriedade v14 ausentes');
    }

    await db.execute('DROP TRIGGER v14_checkin_owner');
    await db.execute('DROP TRIGGER v14_avaliacao_owner');

    await db.execute('''
      CREATE TRIGGER v15_checkin_immutable
      BEFORE UPDATE ON checkins
      WHEN EXISTS (
        SELECT 1 FROM identidades_registros i
        WHERE i.tipo = 'checkin'
          AND i.registro_local_id = OLD.id
      )
      BEGIN
        SELECT RAISE(ABORT, 'v15: checkin identificado imutavel');
      END
    ''');

    await db.execute('''
      CREATE TRIGGER v15_avaliacao_immutable
      BEFORE UPDATE ON avaliacoes
      WHEN EXISTS (
        SELECT 1 FROM identidades_registros i
        WHERE i.tipo = 'avaliacao'
          AND i.registro_local_id = OLD.id
      )
      BEGIN
        SELECT RAISE(ABORT, 'v15: avaliacao identificada imutavel');
      END
    ''');
  }

  Future<void> _criarTabelasMigracaoV13(Database db) async {
    await db.execute('''
      CREATE TABLE identidades_registros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
        tipo TEXT NOT NULL CHECK(tipo IN ('checkin', 'avaliacao')),
        registro_local_id INTEGER NOT NULL CHECK(registro_local_id > 0),
        global_id TEXT NOT NULL UNIQUE
          CHECK(length(global_id) = 32 AND global_id NOT GLOB '*[^0-9a-f]*'),
        criado_em TEXT NOT NULL,
        UNIQUE(usuario_id, tipo, registro_local_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE lotes_migracao (
        id TEXT PRIMARY KEY,
        usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
        estado TEXT NOT NULL DEFAULT 'preparacao'
          CHECK(estado IN (
            'preparacao', 'aguardando_consentimento', 'pronto',
            'em_andamento', 'concluido', 'falhou', 'cancelado'
          )),
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        consentido_em TEXT,
        CHECK(estado != 'concluido' OR consentido_em IS NOT NULL)
      )
    ''');

    await db.execute('''
      CREATE TABLE itens_migracao (
        lote_id TEXT NOT NULL REFERENCES lotes_migracao(id) ON DELETE CASCADE,
        identidade_id INTEGER NOT NULL
          REFERENCES identidades_registros(id) ON DELETE CASCADE,
        estado TEXT NOT NULL DEFAULT 'pendente'
          CHECK(estado IN ('pendente', 'enviando', 'confirmado', 'falhou')),
        atualizado_em TEXT NOT NULL,
        PRIMARY KEY(lote_id, identidade_id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_identidades_usuario_tipo
      ON identidades_registros(usuario_id, tipo)
    ''');
    await db.execute('''
      CREATE INDEX idx_lotes_usuario_estado
      ON lotes_migracao(usuario_id, estado)
    ''');
    await db.execute('''
      CREATE INDEX idx_itens_estado ON itens_migracao(estado)
    ''');
  }

  Future<void> _criarTabelaVinculosFirebase(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vinculos_contas_firebase (
        usuario_id INTEGER PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
        firebase_uid TEXT NOT NULL CHECK(length(firebase_uid) > 0),
        estado TEXT NOT NULL DEFAULT 'pendente'
          CHECK(estado IN ('pendente', 'confirmado', 'revogado')),
        criado_em TEXT NOT NULL,
        confirmado_em TEXT,
        revogado_em TEXT,
        CHECK (
          (estado = 'pendente' AND confirmado_em IS NULL AND revogado_em IS NULL)
          OR (estado = 'confirmado' AND confirmado_em IS NOT NULL AND revogado_em IS NULL)
          OR (estado = 'revogado' AND revogado_em IS NOT NULL)
        )
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_vinculos_firebase_uid_ativo
      ON vinculos_contas_firebase(firebase_uid)
      WHERE estado IN ('pendente', 'confirmado')
    ''');
  }

  Future<void> _criarIndicesOperacao(Database db) async {
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_checkins_operacao '
        'ON checkins(usuario_id, operacao_id) WHERE operacao_id IS NOT NULL');
    await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_avaliacoes_operacao '
        'ON avaliacoes(usuario_id, operacao_id) WHERE operacao_id IS NOT NULL');
  }

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
        produtividade   REAL,
        atividade_significativa TEXT,
        bem_estar       INTEGER NOT NULL,
        principal_ponto TEXT    NOT NULL DEFAULT '',
        cor_valor       INTEGER NOT NULL,
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

  String gerarSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static const int _iteracoesPbkdf2 = 120000;

  Future<Map<String, String>> _credenciaisNovas(String senha) async {
    final saltHex = gerarSalt();
    final hash = await compute(CryptoUtils.pbkdf2Derivar, {
      'senha': senha,
      'saltHex': saltHex,
      'iteracoes': _iteracoesPbkdf2,
    });
    return {
      'senha': hash,
      'salt': 'pbkdf2_sha256:$_iteracoesPbkdf2:$saltHex',
    };
  }

  Future<bool> senhaCorreta({
    required Map<String, dynamic> usuario,
    required String senhaDigitada,
  }) async {
    final senhaArmazenada = usuario['senha'] as String;
    final salt = usuario['salt'] as String? ?? '';
    final id = usuario['id'] as int;

    if (salt.startsWith('pbkdf2_sha256:')) {
      final partes = salt.split(':');
      if (partes.length != 3) return false;
      final iteracoes = int.tryParse(partes[1]);
      if (iteracoes == null || iteracoes < 10000 || iteracoes > 1000000) {
        return false;
      }
      final hash = await compute(CryptoUtils.pbkdf2Derivar, {
        'senha': senhaDigitada,
        'saltHex': partes[2],
        'iteracoes': iteracoes,
      });
      if (!CryptoUtils.hashesIguais(senhaArmazenada, hash)) return false;
      if (iteracoes < _iteracoesPbkdf2) {
        await _migrarSenhaSeInalterada(
            id, senhaArmazenada, salt, senhaDigitada);
      }
      return true;
    }

    final hashLegado = salt.isEmpty
        ? CryptoUtils.sha256Hex(senhaDigitada)
        : CryptoUtils.sha256Hex('$salt:$senhaDigitada');
    if (!CryptoUtils.hashesIguais(senhaArmazenada, hashLegado)) {
      return false;
    }
    await _migrarSenhaSeInalterada(id, senhaArmazenada, salt, senhaDigitada);
    return true;
  }

  Future<void> _migrarSenhaSeInalterada(
      int id, String hashAntigo, String saltAntigo, String senha) async {
    final novos = await _credenciaisNovas(senha);
    final db = await database;
    await db.update(
      'usuarios',
      novos,
      where: saltAntigo.isEmpty
          ? "id = ? AND senha = ? AND (salt = ? OR salt IS NULL)"
          : 'id = ? AND senha = ? AND salt = ?',
      whereArgs: [id, hashAntigo, saltAntigo],
    );
  }

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
    final credenciais = await _credenciaisNovas(senha);
    return db.insert(
      'usuarios',
      {
        'nome': nome.trim(),
        'email': email.trim().toLowerCase(),
        ...credenciais,
        'foto_path': null,
        'tipo_usuario': tipoUsuario,
        'criado_em': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

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

  Future<List<Map<String, dynamic>>> listarTodos() async {
    final db = await database;
    return db.query('usuarios', orderBy: 'id DESC');
  }

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

  Future<int> atualizarSenha({
    required int id,
    required String novaSenha,
  }) async {
    final db = await database;
    final credenciais = await _credenciaisNovas(novaSenha);
    return db.update(
      'usuarios',
      credenciais,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Validação preventiva. Os gatilhos SQLite continuam sendo a proteção final.
  Future<void> _validarExclusaoUsuario(
    Transaction txn,
    int usuarioId,
  ) async {
    if (usuarioId <= 0) {
      throw ArgumentError.value(
        usuarioId,
        'usuarioId',
        'ID de usuário inválido',
      );
    }

    final identidades = await txn.query(
      'identidades_registros',
      columns: ['id'],
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      limit: 1,
    );
    if (identidades.isNotEmpty) {
      throw StateError(
        'Exclusão bloqueada: usuário possui históricos identificados.',
      );
    }

    final lotes = await txn.query(
      'lotes_migracao',
      columns: ['id'],
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      limit: 1,
    );
    if (lotes.isNotEmpty) {
      throw StateError(
        'Exclusão bloqueada: usuário possui lotes de migração.',
      );
    }
  }

  Future<int> deletarUsuario(int id) async {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', 'ID de usuário inválido');
    }

    final db = await database;
    return db.transaction((txn) async {
      final usuarios = await txn.query(
        'usuarios',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (usuarios.isEmpty) return 0;

      await _validarExclusaoUsuario(txn, id);

      await txn.delete(
        'vinculos_contas_firebase',
        where: 'usuario_id = ?',
        whereArgs: [id],
      );
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

  Future<int> deletarUsuarioLocalSemVinculo(int id) async {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', 'ID de usuário inválido');
    }

    final db = await database;
    return db.transaction((txn) async {
      final vinculos = await txn.query(
        'vinculos_contas_firebase',
        columns: ['usuario_id'],
        where: 'usuario_id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (vinculos.isNotEmpty) {
        throw StateError(
          'Exclusão bloqueada: existe um registro de vínculo Firebase.',
        );
      }

      final usuarios = await txn.query(
        'usuarios',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (usuarios.isEmpty) return 0;

      await _validarExclusaoUsuario(txn, id);

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

  Future<int> inserirCheckin({
    required int usuarioId,
    required String dataIso,
    required String dataFormatada,
    required String sentimento,
    required String emoji,
    required double cansaco,
    required double ansiedade,
    required double sono,
    double? produtividade,
    String? atividadeSignificativa,
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
      'atividade_significativa': atividadeSignificativa,
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

  Future<List<Map<String, dynamic>>> listarCheckins(int usuarioId) async {
    final db = await database;
    return db.query(
      'checkins',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'id ASC',
    );
  }

  Future<int> limparCheckins(int usuarioId) async {
    if (usuarioId <= 0) {
      throw ArgumentError.value(
        usuarioId,
        'usuarioId',
        'ID de usuário inválido',
      );
    }

    final db = await database;
    return db.transaction((txn) async {
      final protegidos = await txn.rawQuery('''
        SELECT 1
        FROM checkins c
        INNER JOIN identidades_registros i
          ON i.tipo = 'checkin'
          AND i.registro_local_id = c.id
          AND i.usuario_id = c.usuario_id
        WHERE c.usuario_id = ?
        LIMIT 1
      ''', [usuarioId]);

      if (protegidos.isNotEmpty) {
        throw StateError(
          'Limpeza bloqueada: existem check-ins identificados.',
        );
      }

      return txn.delete(
        'checkins',
        where: 'usuario_id = ?',
        whereArgs: [usuarioId],
      );
    });
  }
}
