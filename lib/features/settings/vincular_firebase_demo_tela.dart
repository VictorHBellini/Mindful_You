import 'package:flutter/material.dart';
import 'package:mindful_you/services/firebase_conta_vinculo_service.dart';

class VincularFirebaseDemoTela extends StatefulWidget {
  const VincularFirebaseDemoTela({super.key});
  @override
  State<VincularFirebaseDemoTela> createState() => _VincularFirebaseDemoTelaState();
}

class _VincularFirebaseDemoTelaState extends State<VincularFirebaseDemoTela> {
  final email = TextEditingController();
  final senha = TextEditingController();
  bool carregando = false;
  String? mensagem;
  @override
  void dispose() { email.dispose(); senha.dispose(); super.dispose(); }
  Future<void> solicitar() async {
    setState(() { carregando = true; mensagem = null; });
    try {
      final retorno = await FirebaseContaVinculoService.solicitarPendente(email: email.text, senha: senha.text);
      if (mounted) setState(() => mensagem = retorno);
    } catch (e) {
      if (mounted) setState(() => mensagem = 'Solicitação não concluída: $e');
    } finally {
      senha.clear();
      if (mounted) setState(() => carregando = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vinculação Firebase — Demo')),
    body: Padding(padding: const EdgeInsets.all(20), child: ListView(children: [
      const Text('Ambiente de testes. A solicitação permanece pendente e não autoriza sincronização.'),
      const SizedBox(height: 18),
      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail Firebase de teste')),
      TextField(controller: senha, obscureText: true, decoration: const InputDecoration(labelText: 'Senha Firebase de teste')),
      const SizedBox(height: 18),
      ElevatedButton(onPressed: carregando ? null : solicitar, child: Text(carregando ? 'Enviando...' : 'Solicitar vínculo pendente')),
      if (mensagem != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(mensagem!)),
    ])),
  );
}
