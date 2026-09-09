import 'package:flutter/material.dart';
import 'package:mindful_you/widgets/tela_legal_base.dart';

// ======================================================================
// TELA - POLÍTICA DE PRIVACIDADE
// ======================================================================
//
// Exibe o texto da Política de Privacidade do Mindful You, reaproveitando
// o layout compartilhado em `widgets/tela_legal_base.dart` (mesma paleta
// e estrutura visual usadas em toda a aplicação).
//
// Ajuste o import acima caso o pacote do projeto não seja
// `mindful_you` ou caso este arquivo seja salvo fora de `features/`.
// ======================================================================

class PoliticaPrivacidadeTela extends StatelessWidget {
  const PoliticaPrivacidadeTela({super.key});

  static const String _ultimaAtualizacao = "Setembro de 2026";

  static const List<SecaoTextoLegal> _secoes = [
    SecaoTextoLegal(
      titulo: "1. Informações coletadas",
      corpo: "O aplicativo poderá armazenar:\n\n"
          "• Nome do usuário;\n"
          "• Endereço de e-mail;\n"
          "• Foto de perfil;\n"
          "• Registros de check-ins emocionais;\n"
          "• Histórico de utilização do aplicativo.",
    ),
    SecaoTextoLegal(
      titulo: "2. Finalidade do uso dos dados",
      corpo: "Os dados são utilizados para:\n\n"
          "• Personalizar a experiência do usuário;\n"
          "• Exibir histórico emocional;\n"
          "• Gerar estatísticas e relatórios pessoais;\n"
          "• Melhorar o funcionamento do aplicativo.",
    ),
    SecaoTextoLegal(
      titulo: "3. Armazenamento das informações",
      corpo:
          "As informações são armazenadas de forma segura e utilizadas "
          "apenas para as finalidades descritas nesta política.",
    ),
    SecaoTextoLegal(
      titulo: "4. Compartilhamento de dados",
      corpo:
          "O Mindful You não vende nem comercializa informações pessoais "
          "dos usuários.\n\n"
          "Os dados não serão compartilhados com terceiros, exceto "
          "quando exigido por obrigação legal.",
    ),
    SecaoTextoLegal(
      titulo: "5. Exclusão de dados",
      corpo:
          "O usuário pode solicitar a exclusão de seus dados ou remover "
          "suas informações utilizando as opções disponíveis no "
          "aplicativo, quando aplicável.",
    ),
    SecaoTextoLegal(
      titulo: "6. Segurança",
      corpo:
          "São adotadas medidas razoáveis para proteger as informações "
          "armazenadas contra acessos não autorizados, perda ou "
          "alteração indevida.",
    ),
    SecaoTextoLegal(
      titulo: "7. Direitos do usuário",
      corpo:
          "O usuário poderá solicitar informações sobre seus dados "
          "armazenados, bem como solicitar correção ou exclusão quando "
          "permitido pela legislação aplicável.",
    ),
    SecaoTextoLegal(
      titulo: "8. Alterações desta política",
      corpo:
          "Esta Política de Privacidade poderá ser atualizada "
          "periodicamente para refletir melhorias e mudanças no "
          "aplicativo.",
    ),
    SecaoTextoLegal(
      titulo: "9. Contato",
      corpo:
          "Dúvidas relacionadas à privacidade e proteção de dados podem "
          "ser encaminhadas pelos canais oficiais do desenvolvedor.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const TelaLegalBase(
      titulo: "Política de Privacidade",
      subtitulo: "Mindful You",
      ultimaAtualizacao: _ultimaAtualizacao,
      icone: Icons.lock_outline_rounded,
      introducao: "Sua privacidade é importante para nós.\n\n"
          "Esta Política de Privacidade explica como o Mindful You "
          "coleta, utiliza e protege as informações fornecidas pelos "
          "usuários.",
      secoes: _secoes,
    );
  }
}
