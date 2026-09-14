import 'dart:convert';
import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            nome      TEXT    NOT NULL,
            email     TEXT    NOT NULL UNIQUE,
            senha     TEXT    NOT NULL,
            salt      TEXT    NOT NULL DEFAULT '',
            foto_path TEXT,
            criado_em TEXT    NOT NULL
          )
        ''');
        await _criarTabelaCheckins(db);
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
      },
    );
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
        criado_em       TEXT    NOT NULL,
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
    final bytes = utf8.encode('$salt:$senha');
    return _sha256hex(bytes);
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
      return _hashesIguais(senhaArmazenada, hashSenha(senhaDigitada, salt));
    }

    // Conta antiga: ainda usa o hash sem salt (SHA-256 puro da senha).
    final String hashAntigo = _sha256hex(utf8.encode(senhaDigitada));
    if (!_hashesIguais(senhaArmazenada, hashAntigo)) {
      return false;
    }

    // Senha correta: migra a conta para o novo formato com salt.
    final int id = usuario['id'] as int;
    final String novoSalt = gerarSalt();
    final String novoHash = hashSenha(senhaDigitada, novoSalt);
    await _atualizarSenhaComSalt(id: id, senhaHash: novoHash, salt: novoSalt);

    return true;
  }

  /// Compara dois hashes em tempo constante (não retorna assim que
  /// encontra a primeira diferença), para que o tempo de resposta do
  /// login não vaze informação sobre em qual posição a senha digitada
  /// diverge da senha correta (proteção contra timing attacks).
  bool _hashesIguais(String a, String b) {
    if (a.length != b.length) return false;

    var diferenca = 0;
    for (var i = 0; i < a.length; i++) {
      diferenca |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return diferenca == 0;
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

  String _sha256hex(List<int> input) {
    // Constantes SHA-256
    final k = [
      0x428a2f98,
      0x71374491,
      0xb5c0fbcf,
      0xe9b5dba5,
      0x3956c25b,
      0x59f111f1,
      0x923f82a4,
      0xab1c5ed5,
      0xd807aa98,
      0x12835b01,
      0x243185be,
      0x550c7dc3,
      0x72be5d74,
      0x80deb1fe,
      0x9bdc06a7,
      0xc19bf174,
      0xe49b69c1,
      0xefbe4786,
      0x0fc19dc6,
      0x240ca1cc,
      0x2de92c6f,
      0x4a7484aa,
      0x5cb0a9dc,
      0x76f988da,
      0x983e5152,
      0xa831c66d,
      0xb00327c8,
      0xbf597fc7,
      0xc6e00bf3,
      0xd5a79147,
      0x06ca6351,
      0x14292967,
      0x27b70a85,
      0x2e1b2138,
      0x4d2c6dfc,
      0x53380d13,
      0x650a7354,
      0x766a0abb,
      0x81c2c92e,
      0x92722c85,
      0xa2bfe8a1,
      0xa81a664b,
      0xc24b8b70,
      0xc76c51a3,
      0xd192e819,
      0xd6990624,
      0xf40e3585,
      0x106aa070,
      0x19a4c116,
      0x1e376c08,
      0x2748774c,
      0x34b0bcb5,
      0x391c0cb3,
      0x4ed8aa4a,
      0x5b9cca4f,
      0x682e6ff3,
      0x748f82ee,
      0x78a5636f,
      0x84c87814,
      0x8cc70208,
      0x90befffa,
      0xa4506ceb,
      0xbef9a3f7,
      0xc67178f2,
    ];

    int rotr(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xFFFFFFFF;
    int add(int a, int b) => (a + b) & 0xFFFFFFFF;

    // Pré-processamento: padding
    final msg = List<int>.from(input);
    final bitLen = input.length * 8;
    msg.add(0x80);
    while (msg.length % 64 != 56) {
      msg.add(0x00);
    }
    for (int i = 7; i >= 0; i--) {
      msg.add((bitLen >> (8 * i)) & 0xFF);
    }

    // Valores iniciais de hash (H0..H7)
    var h0 = 0x6a09e667;
    var h1 = 0xbb67ae85;
    var h2 = 0x3c6ef372;
    var h3 = 0xa54ff53a;
    var h4 = 0x510e527f;
    var h5 = 0x9b05688c;
    var h6 = 0x1f83d9ab;
    var h7 = 0x5be0cd19;

    for (int i = 0; i < msg.length; i += 64) {
      final chunk = msg.sublist(i, i + 64);
      final w = List<int>.filled(64, 0);

      for (int j = 0; j < 16; j++) {
        w[j] = ((chunk[j * 4] << 24) |
                (chunk[j * 4 + 1] << 16) |
                (chunk[j * 4 + 2] << 8) |
                chunk[j * 4 + 3]) &
            0xFFFFFFFF;
      }

      for (int j = 16; j < 64; j++) {
        final s0 = rotr(w[j - 15], 7) ^ rotr(w[j - 15], 18) ^ (w[j - 15] >>> 3);
        final s1 = rotr(w[j - 2], 17) ^ rotr(w[j - 2], 19) ^ (w[j - 2] >>> 10);
        w[j] = add(add(add(w[j - 16], s0), w[j - 7]), s1);
      }

      var a = h0, b = h1, c = h2, d = h3;
      var e = h4, f = h5, g = h6, h = h7;

      for (int j = 0; j < 64; j++) {
        final s1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
        final ch = (e & f) ^ ((~e & 0xFFFFFFFF) & g);
        final temp1 = add(add(add(add(h, s1), ch), k[j]), w[j]);
        final s0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = add(s0, maj);

        h = g;
        g = f;
        f = e;
        e = add(d, temp1);
        d = c;
        c = b;
        b = a;
        a = add(temp1, temp2);
      }

      h0 = add(h0, a);
      h1 = add(h1, b);
      h2 = add(h2, c);
      h3 = add(h3, d);
      h4 = add(h4, e);
      h5 = add(h5, f);
      h6 = add(h6, g);
      h7 = add(h7, h);
    }

    final parts = [h0, h1, h2, h3, h4, h5, h6, h7];
    return parts.map((v) => v.toRadixString(16).padLeft(8, '0')).join();
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
  }) async {
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
    await db.delete('checkins', where: 'usuario_id = ?', whereArgs: [id]);
    return db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
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
  }) async {
    final db = await database;
    return db.insert('checkins', {
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
      'criado_em': DateTime.now().toIso8601String(),
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
