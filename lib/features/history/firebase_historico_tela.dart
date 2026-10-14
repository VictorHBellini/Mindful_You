import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindful_you/services/firebase_registros_service.dart';

/// Histórico Web F3.2: somente dados agregados da conta Firebase atual.
class FirebaseHistoricoTela extends StatefulWidget {
  const FirebaseHistoricoTela({super.key});
  @override
  State<FirebaseHistoricoTela> createState() => _FirebaseHistoricoTelaState();
}

class _FirebaseHistoricoTelaState extends State<FirebaseHistoricoTela> {
  late final String? _uidInicial;
  late Future<List<Map<String, dynamic>>> _checkins;
  @override
  void initState() {
    super.initState();
    _uidInicial = FirebaseAuth.instance.currentUser?.uid;
    _atualizar();
  }

  void _atualizar() {
    _checkins = FirebaseRegistrosService.instance.meusCheckins();
  }

  @override
  Widget build(BuildContext context) {
    if (_uidInicial == null ||
        FirebaseAuth.instance.currentUser?.uid != _uidInicial) {
      return const Scaffold(
          body: Center(child: Text('Sessão alterada. Volte ao login.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico Firestore • F3.2'), actions: [
        IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_atualizar)),
      ]),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _checkins,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (FirebaseAuth.instance.currentUser?.uid != _uidInicial) {
            return const Center(child: Text('Sessão alterada.'));
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Falha ao consultar os registros.'));
          }
          final registros = snapshot.data ?? [];
          if (registros.isEmpty) {
            return const Center(child: Text('Nenhum check-in na nuvem.'));
          }
          return ListView.builder(
            itemCount: registros.length,
            itemBuilder: (context, index) {
              final item = registros[index];
              final criado = item['criado_em'];
              final data =
                  criado != null ? criado.toString() : 'Data indisponível';
              return Card(
                  child: ListTile(
                title: Text(
                    'Bem-estar: ${item['bem_estar']}% • ${item['sentimento'] ?? ''}'),
                subtitle: Text(
                    'Ansiedade: ${item['ansiedade']}% | Cansaço: ${item['cansaco']}% | Sono: ${item['sono']}% | Produtividade: ${item['produtividade']}%\n$data'),
              ));
            },
          );
        },
      ),
    );
  }
}
