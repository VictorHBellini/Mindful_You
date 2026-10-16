import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindful_you/services/database_service.dart';

/// Apenas motor de pontuação e armazenamento para demonstração acadêmica.
/// Não realiza diagnóstico, nem valida o texto de instrumentos clínicos.
class AvaliacaoService {
  AvaliacaoService._();
  static final instance = AvaliacaoService._();

  static int pontuar(String instrumento, List<int> respostas) {
    final tamanho = switch (instrumento) {
      'GAD7' => 7,
      'PHQ9' => 9,
      _ => throw ArgumentError('Instrumento não suportado'),
    };
    if (respostas.length != tamanho ||
        respostas.any((valor) => valor < 0 || valor > 3)) {
      throw ArgumentError('Respostas inválidas para $instrumento');
    }
    return respostas.reduce((a, b) => a + b);
  }

  static bool itemSensivelPositivo(String instrumento, List<int> respostas) {
    pontuar(instrumento, respostas);
    return instrumento == 'PHQ9' && respostas[8] > 0;
  }

  Future<int> registrar({
    required String instrumento,
    required String versao,
    required List<int> respostas,
    String? operacaoId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuarioId');
    if (usuarioId == null) throw StateError('Sessão não encontrada');
    final db = await DatabaseService.instance.database;
    final usuarios = await db.query('usuarios',
        columns: ['tipo_usuario'],
        where: 'id = ?',
        whereArgs: [usuarioId],
        limit: 1);
    if (usuarios.isEmpty || usuarios.first['tipo_usuario'] != 'paciente') {
      throw StateError('Somente pacientes podem registrar avaliações');
    }
    if (versao.trim().isEmpty) throw ArgumentError('Versão obrigatória');
    final total = pontuar(instrumento, respostas);
    if (operacaoId != null && operacaoId.isEmpty) {
      throw ArgumentError('Identificador de operação vazio');
    }
    final dados = <String, Object?>{
      'usuario_id': usuarioId,
      'instrumento': instrumento,
      'versao': versao,
      'pontuacao': total,
      'criado_em': DateTime.now().toUtc().toIso8601String(),
      'operacao_id': operacaoId,
    };
    if (operacaoId == null) return db.insert('avaliacoes', dados);
    return db.transaction((txn) async {
      final existentes = await txn.query('avaliacoes',
          columns: ['id'],
          where: 'usuario_id = ? AND operacao_id = ?',
          whereArgs: [usuarioId, operacaoId],
          limit: 1);
      if (existentes.isNotEmpty) return existentes.first['id'] as int;
      return txn.insert('avaliacoes', dados);
    });
  }

  Future<List<Map<String, dynamic>>> listarMinhasAvaliacoes() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuarioId');
    if (usuarioId == null) throw StateError('Sessão não encontrada');
    final db = await DatabaseService.instance.database;
    return db.query('avaliacoes',
        columns: ['id', 'instrumento', 'versao', 'pontuacao', 'criado_em'],
        where: 'usuario_id = ?',
        whereArgs: [usuarioId],
        orderBy: 'criado_em DESC');
  }
}
