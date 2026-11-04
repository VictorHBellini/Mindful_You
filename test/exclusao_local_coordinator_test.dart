import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_you/features/settings/services/exclusao_local_coordinator.dart';

class SessaoFake implements ExclusaoLocalSessao {
  SessaoFake(this.ids);

  final List<int?> ids;
  int chamadas = 0;

  @override
  Future<int?> usuarioAtualId() async {
    final indice = chamadas++;
    return ids[indice < ids.length ? indice : ids.length - 1];
  }
}

class SenhaFake implements ExclusaoLocalSenha {
  SenhaFake(this.correta);

  final bool correta;
  int chamadas = 0;

  @override
  Future<bool> verificar(int usuarioId, String senha) async {
    chamadas++;
    return correta;
  }
}

class RepositorioFake implements ExclusaoLocalRepositorio {
  RepositorioFake({this.resultado = 1, this.bloquear = false});

  final int resultado;
  final bool bloquear;
  int chamadas = 0;
  int? ultimoUsuarioId;

  @override
  Future<int> excluirSemVinculo(int usuarioId) async {
    chamadas++;
    ultimoUsuarioId = usuarioId;

    if (bloquear) {
      throw StateError('Vínculo Firebase registrado');
    }

    return resultado;
  }
}

void main() {
  group('ExclusaoLocalCoordinator', () {
    test('sessao invalida nao verifica senha nem exclui', () async {
      final sessao = SessaoFake([null]);
      final senha = SenhaFake(true);
      final repositorio = RepositorioFake();

      final resultado = await ExclusaoLocalCoordinator(
        sessao: sessao,
        senha: senha,
        repositorio: repositorio,
      ).executar(senhaDigitada: 'senha');

      expect(resultado, ResultadoExclusaoLocal.sessaoInvalida);
      expect(senha.chamadas, 0);
      expect(repositorio.chamadas, 0);
    });

    test('sessao diferente da conta esperada impede exclusao', () async {
      final sessao = SessaoFake([2, 2, 2]);
      final senha = SenhaFake(true);
      final repositorio = RepositorioFake();

      final resultado = await ExclusaoLocalCoordinator(
        sessao: sessao,
        senha: senha,
        repositorio: repositorio,
      ).executar(
        senhaDigitada: 'correta',
        usuarioEsperadoId: 1,
      );

      expect(resultado, ResultadoExclusaoLocal.sessaoAlterada);
      expect(sessao.chamadas, 1);
      expect(senha.chamadas, 0);
      expect(repositorio.chamadas, 0);
    });

    test('troca de sessao na terceira validacao impede exclusao', () async {
      final sessao = SessaoFake([1, 1, 2]);
      final senha = SenhaFake(true);
      final repositorio = RepositorioFake();

      final resultado = await ExclusaoLocalCoordinator(
        sessao: sessao,
        senha: senha,
        repositorio: repositorio,
      ).executar(senhaDigitada: 'correta');

      expect(resultado, ResultadoExclusaoLocal.sessaoAlterada);
      expect(sessao.chamadas, 3);
      expect(senha.chamadas, 1);
      expect(repositorio.chamadas, 0);
    });

    test('senha incorreta nao exclui', () async {
      final sessao = SessaoFake([1]);
      final senha = SenhaFake(false);
      final repositorio = RepositorioFake();

      final resultado = await ExclusaoLocalCoordinator(
        sessao: sessao,
        senha: senha,
        repositorio: repositorio,
      ).executar(senhaDigitada: 'incorreta');

      expect(resultado, ResultadoExclusaoLocal.senhaIncorreta);
      expect(repositorio.chamadas, 0);
    });

    test('senha vazia nao verifica nem exclui', () async {
      final sessao = SessaoFake([1]);
      final senha = SenhaFake(true);
      final repositorio = RepositorioFake();

      final resultado = await ExclusaoLocalCoordinator(
        sessao: sessao,
        senha: senha,
        repositorio: repositorio,
      ).executar(senhaDigitada: '');

      expect(resultado, ResultadoExclusaoLocal.senhaIncorreta);
      expect(senha.chamadas, 0);
      expect(repositorio.chamadas, 0);
    });

    test('troca de sessao impede exclusao', () async {
      final sessao = SessaoFake([1, 2]);
      final senha = SenhaFake(true);
      final repositorio = RepositorioFake();

      final resultado = await ExclusaoLocalCoordinator(
        sessao: sessao,
        senha: senha,
        repositorio: repositorio,
      ).executar(senhaDigitada: 'correta');

      expect(resultado, ResultadoExclusaoLocal.sessaoAlterada);
      expect(repositorio.chamadas, 0);
    });

    test('vinculo bloqueia exclusao', () async {
      final sessao = SessaoFake([1, 1]);
      final senha = SenhaFake(true);
      final repositorio = RepositorioFake(bloquear: true);

      final resultado = await ExclusaoLocalCoordinator(
        sessao: sessao,
        senha: senha,
        repositorio: repositorio,
      ).executar(senhaDigitada: 'correta');

      expect(
        resultado,
        ResultadoExclusaoLocal.vinculoOuOperacaoBloqueada,
      );
      expect(repositorio.chamadas, 1);
    });

    test('conta inexistente nao informa sucesso', () async {
      final sessao = SessaoFake([1, 1]);
      final senha = SenhaFake(true);
      final repositorio = RepositorioFake(resultado: 0);

      final resultado = await ExclusaoLocalCoordinator(
        sessao: sessao,
        senha: senha,
        repositorio: repositorio,
      ).executar(senhaDigitada: 'correta');

      expect(resultado, ResultadoExclusaoLocal.contaNaoEncontrada);
      expect(repositorio.chamadas, 1);
    });

    test('exclusao valida usa somente ID confirmado', () async {
      final sessao = SessaoFake([7, 7]);
      final senha = SenhaFake(true);
      final repositorio = RepositorioFake();

      final resultado = await ExclusaoLocalCoordinator(
        sessao: sessao,
        senha: senha,
        repositorio: repositorio,
      ).executar(senhaDigitada: 'correta');

      expect(resultado, ResultadoExclusaoLocal.excluido);
      expect(repositorio.chamadas, 1);
      expect(repositorio.ultimoUsuarioId, 7);
    });
  });
}
