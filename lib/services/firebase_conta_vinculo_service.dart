import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'session_service.dart';

/// Fluxo de DEMONSTRAÇÃO: não confirma identidade local no backend nem autoriza sync.
class FirebaseContaVinculoService {
  static const _chaveInstalacao = 'firebase_demo_installation_id';

  static String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0,8)}-${h.substring(8,12)}-${h.substring(12,16)}-${h.substring(16,20)}-${h.substring(20)}';
  }

  static Future<String> _instalacao() async {
    final prefs = await SharedPreferences.getInstance();
    final atual = prefs.getString(_chaveInstalacao);
    if (atual != null && atual.isNotEmpty) return atual;
    final novo = _uuidV4();
    await prefs.setString(_chaveInstalacao, novo);
    return novo;
  }

  static Future<String> solicitarPendente({required String email, required String senha}) async {
    const habilitado = bool.fromEnvironment('MINDFUL_FIREBASE_EMULATORS', defaultValue: false);
    if (!habilitado) throw StateError('Disponível somente no ambiente demonstrativo com emuladores.');
    final inicial = await SessionService.validar();
    if (inicial == null) throw StateError('Entre na conta local antes de solicitar a vinculação.');
    final auth = FirebaseAuth.instance;
    try {
      // Exige autenticação explícita na conta Firebase de teste.
      await auth.signOut();
      final cred = await auth.signInWithEmailAndPassword(email: email.trim(), password: senha);
      final uid = cred.user?.uid;
      if (uid == null) throw StateError('Firebase não retornou UID.');
      final antes = await SessionService.validar();
      if (antes == null || antes.id != inicial.id) throw StateError('A sessão local mudou. Solicitação cancelada.');
      // Evita chamar o backend quando este UID já pertence a outra conta local.
      // A checagem dentro da transação, abaixo, continua sendo obrigatória.
      final dbPre = await DatabaseService.instance.database;
      final donoPre = await dbPre.query(
        'vinculos_contas_firebase',
        columns: ['usuario_id'],
        where: 'firebase_uid = ?',
        whereArgs: [uid],
        limit: 1,
      );
      if (donoPre.isNotEmpty && donoPre.first['usuario_id'] != inicial.id) {
        throw StateError('Esta conta Firebase já possui uma solicitação de vínculo em outra conta local deste dispositivo.');
      }
      final idInstalacao = await _instalacao();
      final callable = FirebaseFunctions.instanceFor(region: 'southamerica-east1').httpsCallable('solicitarVinculoDemo');
      final resposta = await callable.call<Map<String, dynamic>>({'installationId': idInstalacao});
      if (resposta.data['estado'] != 'pendente' || resposta.data['uid'] != uid) {
        throw StateError('Resposta inesperada do backend.');
      }
      final atual = await SessionService.validar();
      if (atual == null || atual.id != inicial.id || auth.currentUser?.uid != uid) {
        throw StateError('Sessão alterada durante a solicitação.');
      }
      final db = await DatabaseService.instance.database;
      try {
      await db.transaction((txn) async {
        // Verificação adicional contra troca de usuário entre chamadas assíncronas.
        // Nunca chamar SessionService.validar() dentro de db.transaction:
        // ele executa db.query fora da transação e pode bloquear o SQLite.
        final prefsTransacao = await SharedPreferences.getInstance();
        if (prefsTransacao.getInt('usuarioId') != inicial.id ||
            auth.currentUser?.uid != uid) {
          throw StateError('Sessão alterada antes da gravação.');
        }
        final usuarios = await txn.query(
          'usuarios',
          columns: ['id', 'tipo_usuario'],
          where: 'id = ?',
          whereArgs: [inicial.id],
          limit: 1,
        );
        if (usuarios.isEmpty ||
            !['paciente', 'terapeuta'].contains(usuarios.first['tipo_usuario'])) {
          throw StateError('Conta local inválida.');
        }
        // Impede o mesmo UID em duas contas locais, inclusive sob concorrência.
        final donoUid = await txn.query(
          'vinculos_contas_firebase',
          columns: ['usuario_id'],
          where: 'firebase_uid = ?',
          whereArgs: [uid],
          limit: 1,
        );
        if (donoUid.isNotEmpty && donoUid.first['usuario_id'] != inicial.id) {
          throw StateError('Esta conta Firebase já possui uma solicitação de vínculo em outra conta local deste dispositivo.');
        }
        final existente = await txn.query('vinculos_contas_firebase', where: 'usuario_id = ?', whereArgs: [inicial.id], limit: 1);
        if (existente.isNotEmpty) {
          if (existente.first['firebase_uid'] != uid || existente.first['estado'] != 'pendente') {
            throw StateError('A conta local já possui outro vínculo. Nenhuma alteração realizada.');
          }
        } else {
          await txn.insert('vinculos_contas_firebase', {
            'usuario_id': inicial.id,
            'firebase_uid': uid,
            'estado': 'pendente',
            'criado_em': DateTime.now().toUtc().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.abort);
        }
      });
      } on DatabaseException catch (e) {
        if (e.isUniqueConstraintError()) {
          throw StateError('Conflito de vínculo: esta conta Firebase ou conta local já possui uma solicitação neste dispositivo.');
        }
        rethrow;
      }
      return 'Solicitação pendente registrada. Sincronização desativada.';
    } finally {
      await auth.signOut();
    }
  }
}
