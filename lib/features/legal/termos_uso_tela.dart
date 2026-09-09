import 'package:flutter/material.dart';
import 'package:mindful_you/widgets/tela_legal_base.dart';

// ======================================================================
// TELA - TERMOS DE USO
// ======================================================================
//
// Exibe o texto dos Termos de Uso do Mindful You, reaproveitando o
// layout compartilhado em `widgets/tela_legal_base.dart` (mesma paleta
// e estrutura visual usadas em toda a aplicação).
//
// Ajuste o import acima caso o pacote do projeto não seja
// `mindful_you` ou caso este arquivo seja salvo fora de `features/`.
// ======================================================================

class TermosUsoTela extends StatelessWidget {
  const TermosUsoTela({super.key});

  static const String _ultimaAtualizacao = "Setembro de 2026";

  static const List<SecaoTextoLegal> _secoes = [
    SecaoTextoLegal(
      titulo: "1. Objetivo do aplicativo",
      corpo:
          "O Mindful You é uma ferramenta de acompanhamento emocional que "
          "permite registrar sentimentos, acompanhar o histórico de "
          "check-ins e visualizar informações relacionadas ao seu "
          "bem-estar.\n\n"
          "O aplicativo tem finalidade exclusivamente informativa e de "
          "autocuidado, não substituindo acompanhamento médico, "
          "psicológico ou psiquiátrico.",
    ),
    SecaoTextoLegal(
      titulo: "2. Cadastro e acesso",
      corpo:
          "Para utilizar determinadas funcionalidades, o usuário poderá "
          "fornecer informações básicas de identificação, como nome e "
          "e-mail.\n\n"
          "O usuário é responsável pela veracidade das informações "
          "fornecidas.",
    ),
    SecaoTextoLegal(
      titulo: "3. Uso adequado",
      corpo:
          "O usuário compromete-se a utilizar o aplicativo de forma ética "
          "e responsável, não realizando atividades que possam "
          "comprometer a segurança, integridade ou funcionamento da "
          "plataforma.",
    ),
    SecaoTextoLegal(
      titulo: "4. Disponibilidade",
      corpo:
          "Embora busquemos manter o aplicativo disponível continuamente, "
          "não garantimos funcionamento ininterrupto, podendo ocorrer "
          "manutenções, atualizações ou falhas técnicas.",
    ),
    SecaoTextoLegal(
      titulo: "5. Limitação de responsabilidade",
      corpo:
          "As informações e sugestões apresentadas pelo aplicativo "
          "possuem caráter orientativo.\n\n"
          "O Mindful You não realiza diagnósticos médicos nem oferece "
          "tratamento psicológico.",
    ),
    SecaoTextoLegal(
      titulo: "6. Alterações dos termos",
      corpo:
          "Estes Termos de Uso poderão ser atualizados periodicamente. "
          "Sempre que houver alterações relevantes, a versão atualizada "
          "será disponibilizada dentro do aplicativo.",
    ),
    SecaoTextoLegal(
      titulo: "7. Contato",
      corpo:
          "Em caso de dúvidas, sugestões ou solicitações relacionadas ao "
          "aplicativo, entre em contato pelos canais oficiais "
          "disponibilizados pelo desenvolvedor.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const TelaLegalBase(
      titulo: "Termos de Uso",
      subtitulo: "Mindful You",
      ultimaAtualizacao: _ultimaAtualizacao,
      icone: Icons.description_outlined,
      introducao: "Bem-vindo ao Mindful You.\n\n"
          "Ao utilizar este aplicativo, você concorda com os presentes "
          "Termos de Uso. Caso não concorde com qualquer condição aqui "
          "descrita, recomendamos que não utilize o aplicativo.",
      secoes: _secoes,
    );
  }
}
