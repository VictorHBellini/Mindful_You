import 'package:mindful_you/features/auth/services/session_operation_coordinator.dart';
import 'package:mindful_you/features/auth/services/session_service.dart';
import 'package:mindful_you/services/database_service.dart';

enum ResultadoAlteracaoSenha {
  sucesso,
  sessaoInvalida,
  sessaoAlterada,
  senhaAtualIncorreta,
  novaSenhaInvalida,
  senhaIgualAtual,
  conflitoCredenciais,
}

class AlteracaoSenhaService {
  AlteracaoSenhaService({DatabaseService? database})
      : _database = database ?? DatabaseService.instance;

  final DatabaseService _database;

  Future<ResultadoAlteracaoSenha> executar({
    required String senhaAtual,
    required String novaSenha,
  }) {
    return SessionOperationCoordinator.executar(() async {
      if (novaSenha.length < 8) {
        return ResultadoAlteracaoSenha.novaSenhaInvalida;
      }

      if (senhaAtual.isEmpty) {
        return ResultadoAlteracaoSenha.senhaAtualIncorreta;
      }

      if (senhaAtual == novaSenha) {
        return ResultadoAlteracaoSenha.senhaIgualAtual;
      }

      final sessaoInicial = await SessionService.validar();

      if (sessaoInicial == null) {
        return ResultadoAlteracaoSenha.sessaoInvalida;
      }

      final usuarioId = sessaoInicial.id;
      final db = await _database.database;

      final registros = await db.query(
        'usuarios',
        columns: ['id', 'senha', 'salt'],
        where: 'id = ?',
        whereArgs: [usuarioId],
        limit: 1,
      );

      if (registros.length != 1) {
        return ResultadoAlteracaoSenha.sessaoInvalida;
      }

      final credenciais = registros.single;

      // Verifica a senha atual sem migrar ou modificar o hash.
      final senhaValida = await _database.verificarSenhaSemMigrar(
        usuario: credenciais,
        senhaDigitada: senhaAtual,
      );

      if (!senhaValida) {
        return ResultadoAlteracaoSenha.senhaAtualIncorreta;
      }

      // Confirma que a mesma conta continua ativa.
      final sessaoFinal = await SessionService.validar();

      if (sessaoFinal == null || sessaoFinal.id != usuarioId) {
        return ResultadoAlteracaoSenha.sessaoAlterada;
      }

      // Atualiza somente se as credenciais verificadas
      // permanecerem iguais no SQLite.
      final alterados = await _database.atualizarSenhaSeInalterada(
        id: usuarioId,
        novaSenha: novaSenha,
        hashAnterior: credenciais['senha'] as String,
        saltAnterior: credenciais['salt'] as String? ?? '',
      );

      if (alterados != 1) {
        return ResultadoAlteracaoSenha.conflitoCredenciais;
      }

      return ResultadoAlteracaoSenha.sucesso;
    });
  }
}
