import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindful_you/services/firebase_perfil_service.dart';

/// Laboratório isolado F2.1. Não usa nem altera sessão SQLite.
/// Somente contas fictícias; nenhuma rota de paciente é liberada aqui.
class FirebaseTesteTela extends StatefulWidget {
  const FirebaseTesteTela({super.key});

  @override
  State<FirebaseTesteTela> createState() => _FirebaseTesteTelaState();
}

class _FirebaseTesteTelaState extends State<FirebaseTesteTela> {
  final _email = TextEditingController();
  final _nome = TextEditingController();
  String _tipo = 'paciente';
  Map<String, dynamic>? _perfil;
  final _senha = TextEditingController();
  bool _ocupado = false;
  String? _mensagem;

  @override
  void dispose() {
    _email.dispose();
    _nome.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() acao) async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _mensagem = null;
    });
    try {
      await acao();
      if (!mounted) return;
      setState(() => _mensagem = 'Operação concluída.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _mensagem = switch (e.code) {
            'email-already-in-use' => 'E-mail já cadastrado.',
            'weak-password' => 'Senha fraca. Use uma senha mais forte.',
            'invalid-email' => 'E-mail inválido.',
            'operation-not-allowed' =>
              'Ative Email/Password no Firebase Console.',
            'network-request-failed' => 'Verifique a conexão com a internet.',
            _ =>
              'Não foi possível autenticar. Verifique os dados e tente novamente.',
          });
    } catch (_) {
      if (!mounted) return;
      setState(() => _mensagem = 'Ocorreu um erro. Tente novamente.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _cadastrar() async {
    final email = _email.text.trim();
    final senha = _senha.text;
    if (email.isEmpty || senha.length < 8) {
      setState(() =>
          _mensagem = 'Informe e-mail e senha de pelo menos 8 caracteres.');
      return;
    }
    await _executar(() async {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );
    });
  }

  Future<void> _salvarPerfil() async {
    await _executar(() async {
      await FirebasePerfilService.instance.criarPerfil(
        nome: _nome.text,
        tipo: _tipo,
      );
      _perfil = await FirebasePerfilService.instance.meuPerfil();
    });
  }

  Future<void> _consultarPerfil() async {
    await _executar(() async {
      _perfil = await FirebasePerfilService.instance.meuPerfil();
    });
  }

  Future<void> _entrar() async {
    await _executar(() async {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _senha.text,
      );
    });
  }

  Future<void> _sair() async {
    await _executar(() async {
      await FirebaseAuth.instance.signOut();
      _perfil = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mindful You • Teste Firebase F2.1')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const Text(
                'Ambiente de teste com contas fictícias. Este login não abre o aplicativo nem dá acesso a dados de pacientes.'),
            const SizedBox(height: 20),
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Falha ao consultar sessão Firebase.');
                }

                if (!snapshot.hasData) {
                  return const Text('Firebase: não autenticado');
                }

                return Text(
                  'Firebase: autenticado como ${snapshot.data!.email ?? "conta de teste"}',
                );
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail fictício'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senha,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha de teste'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nome,
              decoration:
                  const InputDecoration(labelText: 'Nome fictício para perfil'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              items: const [
                DropdownMenuItem(value: 'paciente', child: Text('Paciente')),
                DropdownMenuItem(
                    value: 'terapeuta',
                    child: Text('Terapeuta (demonstração)')),
              ],
              onChanged: _ocupado
                  ? null
                  : (valor) {
                      if (valor != null) setState(() => _tipo = valor);
                    },
            ),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: _ocupado ? null : _cadastrar,
                child: const Text('Criar conta Firebase de teste')),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: _ocupado ? null : _entrar,
                child: const Text('Entrar no Firebase')),
            const SizedBox(height: 8),
            TextButton(
                onPressed: _ocupado ? null : _sair,
                child: const Text('Sair do Firebase')),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _ocupado ? null : _salvarPerfil,
              child: const Text('Criar meu perfil no Firestore'),
            ),
            OutlinedButton(
              onPressed: _ocupado ? null : _consultarPerfil,
              child: const Text('Consultar meu perfil'),
            ),
            if (_perfil != null)
              Text('Perfil: ${_perfil!['nome']} • ${_perfil!['tipo_usuario']}'),
            if (_ocupado) const LinearProgressIndicator(),
            if (_mensagem != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_mensagem!),
              ),
            const SizedBox(height: 24),
            const Text(
                'F2.2: laboratório de perfis fictícios no Firestore. SQLite e consentimentos continuam locais. Não use dados reais.'),
          ]),
        ),
      ),
    );
  }
}
