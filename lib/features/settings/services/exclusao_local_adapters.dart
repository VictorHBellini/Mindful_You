import 'package:mindful_you/features/auth/services/account_link_proof_adapters.dart';
import 'package:mindful_you/features/auth/services/session_service.dart';
import 'package:mindful_you/features/settings/services/exclusao_local_coordinator.dart';
import 'package:mindful_you/services/database_service.dart';

class SessaoLocalAdapter implements ExclusaoLocalSessao {
  @override
  Future<int?> usuarioAtualId() async {
    final sessao = await SessionService.validar();
    return sessao?.id;
  }
}

class SenhaLocalAdapter implements ExclusaoLocalSenha {
  SenhaLocalAdapter({DatabaseService? database})
      : _database = database ?? DatabaseService.instance;

  final DatabaseService _database;

  @override
  Future<bool> verificar(int usuarioId, String senha) {
    return SqlitePasswordProof(
      password: senha,
      database: _database,
    ).verifyLocalUser(usuarioId);
  }
}

class RepositorioExclusaoLocalAdapter implements ExclusaoLocalRepositorio {
  RepositorioExclusaoLocalAdapter({DatabaseService? database})
      : _database = database ?? DatabaseService.instance;

  final DatabaseService _database;

  @override
  Future<int> excluirSemVinculo(int usuarioId) {
    return _database.deletarUsuarioLocalSemVinculo(usuarioId);
  }
}
