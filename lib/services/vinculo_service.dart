import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindful_you/services/database_service.dart';

/// Fluxo acadêmico LOCAL. A autorização deve migrar para o servidor
/// antes de utilizar dados reais ou sincronizar dispositivos.
class VinculoService {
  static final instance = VinculoService._();
  VinculoService._();

  Future<int> _idLogado(String papel) async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('usuarioId');
    if (id == null) throw StateError('Faça login novamente.');
    final db = await DatabaseService.instance.database;
    final u = await db.query('usuarios', columns: ['tipo_usuario'], where: 'id = ?', whereArgs: [id], limit: 1);
    if (u.isEmpty || u.first['tipo_usuario'] != papel) {
      throw StateError('Operação não permitida para esta conta.');
    }
    return id;
  }

  Future<void> solicitar(String emailPaciente) async {
    final terapeutaId = await _idLogado('terapeuta');
    final db = await DatabaseService.instance.database;
    final email = emailPaciente.trim().toLowerCase();
    final pacientes = await db.query('usuarios', columns: ['id'], where: 'email = ? AND tipo_usuario = ?', whereArgs: [email, 'paciente'], limit: 1);
    if (pacientes.isEmpty) throw StateError('Nenhuma conta de paciente encontrada com esse e-mail.');
    final pacienteId = pacientes.first['id'] as int;
    final antigos = await db.query('vinculos_terapeuticos', columns: ['id','status'], where: 'terapeuta_id = ? AND paciente_id = ?', whereArgs: [terapeutaId, pacienteId], limit: 1);
    if (antigos.isNotEmpty) {
      if (antigos.first['status'] == 'pendente' || antigos.first['status'] == 'aceito') {
        throw StateError('Já existe uma solicitação ou vínculo ativo.');
      }
      await db.update('vinculos_terapeuticos', {'status':'pendente','criado_em':DateTime.now().toIso8601String(),'decidido_em':null}, where:'id = ?',whereArgs:[antigos.first['id']]);
    } else {
      await db.insert('vinculos_terapeuticos', {'terapeuta_id':terapeutaId,'paciente_id':pacienteId,'status':'pendente','criado_em':DateTime.now().toIso8601String()});
    }
  }

  Future<List<Map<String,dynamic>>> listarParaTerapeuta() async {
    final id = await _idLogado('terapeuta');
    final db = await DatabaseService.instance.database;
    return db.rawQuery('''SELECT v.id, v.status, u.nome, u.email FROM vinculos_terapeuticos v
      JOIN usuarios u ON u.id = v.paciente_id WHERE v.terapeuta_id = ? ORDER BY v.id DESC''',[id]);
  }

  Future<List<Map<String,dynamic>>> listarParaPaciente() async {
    final id = await _idLogado('paciente');
    final db = await DatabaseService.instance.database;
    return db.rawQuery('''SELECT v.id, v.status, u.nome, u.email FROM vinculos_terapeuticos v
      JOIN usuarios u ON u.id = v.terapeuta_id WHERE v.paciente_id = ? ORDER BY v.id DESC''',[id]);
  }

  Future<void> decidir(int vinculoId, String decisao) async {
    if (!['aceito','recusado','revogado'].contains(decisao)) throw ArgumentError('Decisão inválida');
    final id = await _idLogado('paciente');
    final db = await DatabaseService.instance.database;
    final alterados = await db.update('vinculos_terapeuticos', {'status':decisao,'decidido_em':DateTime.now().toIso8601String()},
      where: 'id = ? AND paciente_id = ? AND status = ?',
      whereArgs: [vinculoId,id,decisao == 'revogado' ? 'aceito' : 'pendente']);
    if (alterados != 1) throw StateError('Solicitação indisponível ou já alterada.');
  }

  /// Não fornece histórico nesta etapa: apenas verifica consentimento.
  Future<bool> temConsentimento(int pacienteId) async {
    final terapeutaId = await _idLogado('terapeuta');
    final db = await DatabaseService.instance.database;
    final vinculo = await db.query('vinculos_terapeuticos', columns: ['id'],
      where: 'terapeuta_id = ? AND paciente_id = ? AND status = ?',
      whereArgs: [terapeutaId,pacienteId,'aceito'],limit:1);
    return vinculo.isNotEmpty;
  }
}
