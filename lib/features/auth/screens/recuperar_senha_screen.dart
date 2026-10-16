import 'package:flutter/material.dart';

/// Etapa 1 (MVP acadêmico): a redefinição por e-mail foi suspensa.
/// A versão anterior permitia trocar a senha conhecendo apenas o e-mail.
/// Reativar somente após implementar verificação de posse da conta
/// (por exemplo, token de uso único, prazo de expiração e backend).
class RecuperarSenhaTela extends StatelessWidget {
  const RecuperarSenhaTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperação de acesso')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 56),
                  const SizedBox(height: 20),
                  const Text(
                    'Recuperação temporariamente indisponível',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Para proteger sua conta, a redefinição de senha '
                    'por e-mail está desativada nesta demonstração. '
                    'Não é possível comprovar a titularidade do e-mail '
                    'sem um mecanismo de verificação.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Voltar ao login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
