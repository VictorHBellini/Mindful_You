import 'package:flutter/material.dart';
import 'package:mindful_you/services/firebase_conta_vinculo_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';

class VincularFirebaseDemoTela extends StatefulWidget {
  const VincularFirebaseDemoTela({super.key});
  @override
  State<VincularFirebaseDemoTela> createState() =>
      _VincularFirebaseDemoTelaState();
}

class _VincularFirebaseDemoTelaState extends State<VincularFirebaseDemoTela> {
  final email = TextEditingController();
  final senha = TextEditingController();
  bool carregando = false;
  String? mensagem;
  @override
  void dispose() {
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  String mensagemAmigavel(Object erro) {
    if (erro is FirebaseAuthException) {
      switch (erro.code) {
        case 'user-not-found':
        case 'invalid-credential':
          return 'Conta de teste não encontrada ou credenciais inválidas no Firebase Emulator.';

        case 'wrong-password':
        case 'invalid-email':
          return 'E-mail ou senha inválidos.';

        case 'network-request-failed':
          return 'Não foi possível conectar ao Firebase Emulator. Verifique se ele está funcionando.';

        case 'too-many-requests':
          return 'Muitas tentativas de acesso. Aguarde antes de tentar novamente.';
      }
    }

    if (erro is FirebaseFunctionsException) {
      switch (erro.code) {
        case 'unavailable':
        case 'deadline-exceeded':
          return 'O serviço Firebase está indisponível. Tente novamente mais tarde.';

        case 'unauthenticated':
          return 'Sua sessão Firebase não é válida. Entre novamente.';

        case 'already-exists':
          return 'Esta conta Firebase já possui uma solicitação em outra instalação.';

        case 'not-found':
          return 'A função de vinculação não foi encontrada. Verifique a configuração do Firebase Emulator.';
      }
    }

    if (erro is PlatformException) {
      return 'Ocorreu uma falha na comunicação com o Android. Tente novamente.';
    }

    if (erro is StateError) {
      final texto = erro.message.toString();

      if (texto.contains('outra conta local')) {
        return 'Esta conta Firebase já possui uma solicitação de vínculo em outra conta local deste dispositivo.';
      }

      if (texto.contains('sessão local mudou')) {
        return 'A sessão local foi alterada. Entre novamente para continuar.';
      }
    }

    return 'Não foi possível concluir a solicitação. Verifique sua conexão e tente novamente.';
  }

  Future<void> consultarVinculoLocal() async {
    if (carregando) return;

    setState(() {
      carregando = true;
      mensagem = null;
    });

    try {
      final resultado =
          await FirebaseContaVinculoService.diagnosticarVinculoLocal();

      if (!mounted) return;

      setState(() {
        mensagem = resultado;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        mensagem = 'Não foi possível consultar o vínculo local.';
      });
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  Future<void> solicitar() async {
    if (carregando) return;

    if (email.text.trim().isEmpty || senha.text.isEmpty) {
      setState(() {
        mensagem = 'Informe o e-mail e a senha da conta Firebase de teste.';
      });
      return;
    }

    setState(() {
      carregando = true;
      mensagem = null;
    });

    try {
      final retorno = await FirebaseContaVinculoService.solicitarPendente(
        email: email.text.trim(),
        senha: senha.text,
      );

      if (!mounted) return;

      setState(() {
        mensagem = retorno;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        mensagem = mensagemAmigavel(erro);
      });
    } finally {
      senha.clear();

      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Vinculação Firebase — Demo')),
        body: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(children: [
              const Text(
                  'Ambiente de testes. A solicitação permanece pendente e não autoriza sincronização.'),
              const SizedBox(height: 18),
              TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'E-mail Firebase de teste')),
              TextField(
                  controller: senha,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Senha Firebase de teste')),
              const SizedBox(height: 18),
              ElevatedButton(
                  onPressed: carregando ? null : solicitar,
                  child: Text(carregando
                      ? 'Enviando...'
                      : 'Solicitar vínculo pendente')),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: carregando ? null : consultarVinculoLocal,
                child: const Text('Consultar vínculo local'),
              ),
              if (mensagem != null)
                Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(mensagem!)),
            ])),
      );
}
