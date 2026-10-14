import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindful_you/features/auth/firebase_registros_teste_tela.dart';
import 'package:flutter/material.dart';
import 'package:mindful_you/features/checkin/questionario_tela.dart';
import 'package:mindful_you/features/assessment/avaliacoes_tela.dart';
import 'package:mindful_you/features/history/firebase_historico_tela.dart';
import 'package:mindful_you/services/firebase_perfil_service.dart';

/// Laboratório F2.3 isolado: somente contas e perfis fictícios.
/// Não acessa SQLite, check-ins, avaliações ou consentimentos.
class FirebaseTesteTela extends StatefulWidget {
  const FirebaseTesteTela({super.key});

  @override
  State<FirebaseTesteTela> createState() => _FirebaseTesteTelaState();
}

class _FirebaseTesteTelaState extends State<FirebaseTesteTela> {
  final _email = TextEditingController();
  final _nome = TextEditingController();
  final _senha = TextEditingController();
  late final StreamSubscription<User?> _assinatura;
  String _tipo = 'paciente';
  Map<String, dynamic>? _perfil;
  bool _ocupado = false;
  bool _consultandoPerfil = false;
  String? _mensagem;
  String? _uidExibido;

  @override
  void initState() {
    super.initState();
    _assinatura = FirebaseAuth.instance.authStateChanges().listen((usuario) {
      if (!mounted) return;
      setState(() {
        _perfil = null;
        _uidExibido = usuario?.uid;
        _mensagem = null;
        _consultandoPerfil = usuario != null;
      });
      if (usuario != null) {
        _carregarPerfil(usuario.uid);
      }
    });
  }

  Future<void> _carregarPerfil(String uid) async {
    try {
      final perfil = await FirebasePerfilService.instance.meuPerfil();
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
      setState(() {
        _perfil = perfil;
        _consultandoPerfil = false;
      });
    } catch (_) {
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) return;
      setState(() {
        _perfil = null;
        _consultandoPerfil = false;
        _mensagem = 'Não foi possível consultar o perfil. Tente novamente.';
      });
    }
  }

  @override
  void dispose() {
    _assinatura.cancel();
    _email.dispose();
    _nome.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _executar(
    Future<void> Function() acao, {
    String sucesso = 'Operação concluída.',
  }) async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _mensagem = null;
    });
    try {
      await acao();
      if (!mounted) return;
      setState(() => _mensagem = sucesso);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _mensagem = switch (e.code) {
            'email-already-in-use' => 'E-mail já cadastrado.',
            'weak-password' => 'Senha fraca. Use uma senha mais forte.',
            'invalid-email' => 'E-mail inválido.',
            'operation-not-allowed' =>
              'Ative Email/Password no Firebase Console.',
            'network-request-failed' => 'Verifique a conexão com a internet.',
            'too-many-requests' =>
              'Muitas tentativas. Aguarde e tente novamente.',
            'invalid-credential' ||
            'wrong-password' ||
            'user-not-found' =>
              'Não foi possível entrar. Verifique o e-mail e a senha.',
            _ => 'Não foi possível concluir a operação. Tente novamente.',
          });
    } catch (_) {
      if (!mounted) return;
      setState(() => _mensagem = 'Não foi possível concluir a operação.');
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
      }
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
      _senha.clear();
    });
  }

  Future<void> _salvarPerfil() async {
    await _executar(() async {
      await FirebasePerfilService.instance.criarPerfil(
        nome: _nome.text,
        tipo: _tipo,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) await _carregarPerfil(uid);
    });
  }

  Future<void> _consultarPerfil() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _mensagem = 'Entre na sua conta primeiro.');
      return;
    }
    await _executar(() => _carregarPerfil(uid));
  }

  Future<void> _entrar() async {
    await _executar(() async {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _senha.text,
      );
      _senha.clear();
    });
  }

  Future<void> _sair() async {
    await _executar(() async {
      setState(() {
        _perfil = null;
        _uidExibido = null;
        _consultandoPerfil = false;
      });
      await FirebaseAuth.instance.signOut();
      _senha.clear();
    });
  }

  Future<void> _recuperarSenha() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _mensagem = 'Informe um e-mail válido para recuperação.');
      return;
    }
    await _executar(
      () => FirebaseAuth.instance.sendPasswordResetEmail(email: email),
      sucesso: 'Se a conta puder receber a recuperação, '
          'você receberá um e-mail com as instruções. '
          'Verifique também a caixa de spam.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mindful You • Firebase F2.3')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Laboratório com contas fictícias. '
                'Este login não libera dados de pacientes.',
              ),
              const SizedBox(height: 20),
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Falha ao consultar sessão Firebase.');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Verificando sessão Firebase...');
                  }
                  final usuario = snapshot.data;
                  if (usuario == null) {
                    return const Text('Firebase: não autenticado');
                  }
                  return Text(
                    'Firebase: autenticado como '
                    '${usuario.email ?? "conta de teste"}',
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
                decoration: const InputDecoration(
                  labelText: 'Nome fictício para perfil',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                items: const [
                  DropdownMenuItem(value: 'paciente', child: Text('Paciente')),
                  DropdownMenuItem(
                    value: 'terapeuta',
                    child: Text('Terapeuta (demonstração)'),
                  ),
                ],
                onChanged: _ocupado
                    ? null
                    : (valor) {
                        if (valor != null) {
                          setState(() => _tipo = valor);
                        }
                      },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _ocupado ? null : _cadastrar,
                child: const Text('Criar conta Firebase de teste'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _ocupado ? null : _entrar,
                child: const Text('Entrar no Firebase'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _ocupado ? null : _recuperarSenha,
                child: const Text('Esqueci minha senha'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _ocupado ? null : _sair,
                child: const Text('Sair do Firebase'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _ocupado ? null : _salvarPerfil,
                child: const Text('Criar meu perfil no Firestore'),
              ),
              OutlinedButton(
                onPressed: _ocupado ? null : _consultarPerfil,
                child: const Text('Consultar meu perfil'),
              ),
              if (_consultandoPerfil)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
              if (_uidExibido != null && !_consultandoPerfil && _perfil == null)
                const Text(
                  'Conta autenticada sem perfil no Firestore. '
                  'Crie um perfil fictício para continuar os testes.',
                ),
              if (_uidExibido != null && _perfil != null)
                Text(
                  'Perfil: ${_perfil!['nome']} • ${_perfil!['tipo_usuario']}',
                ),
              if (_ocupado) const LinearProgressIndicator(),
              if (_mensagem != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_mensagem!),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.cloud_outlined),
                label: const Text('Laboratório Firestore F3.1'),
                onPressed: _ocupado
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const FirebaseRegistrosTesteTela(),
                          ),
                        );
                      },
              ),
              const SizedBox(height: 12),
              const Text(
                  'F3.2 • Formulários fictícios integrados ao Firestore'),
              OutlinedButton(
                onPressed: _ocupado || _perfil?['tipo_usuario'] != 'paciente'
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const QuestionarioTela())),
                child: const Text('Responder check-in F3.2'),
              ),
              OutlinedButton(
                onPressed: _ocupado || _perfil?['tipo_usuario'] != 'paciente'
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const AvaliacoesTela())),
                child: const Text('Avaliações demonstrativas F3.2'),
              ),
              OutlinedButton(
                onPressed: _ocupado || _perfil?['tipo_usuario'] != 'paciente'
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const FirebaseHistoricoTela())),
                child: const Text('Histórico Firestore F3.2'),
              ),
              const SizedBox(height: 24),
              const Text(
                'F2.3: recuperação de senha e sessão Firebase. '
                'SQLite, avaliações e consentimentos continuam locais. '
                'Não use dados reais.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
