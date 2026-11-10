import 'package:flutter/material.dart';
import 'package:mindful_you/widgets/tela_legal_base.dart';

// ======================================================================
// TELA - TERMOS DE USO
// Mindful You 1.0 - destinado a pessoas com 18 anos ou mais.
// ======================================================================

class TermosUsoTela extends StatelessWidget {
  const TermosUsoTela({super.key});

  static const String _ultimaAtualizacao = 'Novembro de 2026';

  static const List<SecaoTextoLegal> _secoes = [
    SecaoTextoLegal(
      titulo: '1. Objetivo do aplicativo',
      corpo: 'O Mindful You é uma ferramenta de acompanhamento emocional que '
          'permite registrar sentimentos, acompanhar o histórico de '
          'check-ins e visualizar informações relacionadas ao bem-estar.\n\n'
          'O aplicativo tem finalidade informativa e de autocuidado. '
          'Não substitui acompanhamento médico, psicológico ou psiquiátrico, '
          'nem deve ser utilizado para diagnóstico ou atendimento de emergência.',
    ),
    SecaoTextoLegal(
      titulo: '2. Cadastro, acesso e idade mínima',
      corpo: 'O Mindful You 1.0 é destinado exclusivamente a pessoas com '
          '18 anos ou mais. O cadastro e o uso por menores de 18 anos '
          'não são autorizados nesta versão.\n\n'
          'Ao criar uma conta, o usuário deve declarar que tem pelo menos '
          '18 anos e aceitar os Termos de Uso e a Política de Privacidade. '
          'A confirmação de maioridade é uma autodeclaração; o aplicativo '
          'não realiza verificação documental da idade.\n\n'
          'Para utilizar determinadas funcionalidades, o usuário fornece '
          'informações de identificação, como nome e e-mail, e define uma '
          'senha. O usuário deve prestar informações verdadeiras e proteger '
          'suas credenciais.\n\n'
          'Caso uma pessoa menor de 18 anos tenha criado ou esteja utilizando '
          'uma conta, ela ou seu responsável poderá comunicar a situação '
          'pelo canal de contato indicado na seção 7, para análise das '
          'medidas cabíveis, inclusive restrição de acesso e tratamento '
          'dos dados conforme a legislação aplicável.',
    ),
    SecaoTextoLegal(
      titulo: '3. Uso adequado',
      corpo: 'O usuário compromete-se a utilizar o aplicativo de forma ética '
          'e responsável, sem realizar atividades que comprometam a '
          'segurança, a integridade ou o funcionamento da plataforma.\n\n'
          'Os perfis e recursos identificados como demonstrativos, incluindo '
          'o perfil de terapeuta, destinam-se a demonstração e não '
          'comprovam habilitação profissional nem constituem prestação '
          'de serviços de saúde.',
    ),
    SecaoTextoLegal(
      titulo: '4. Disponibilidade',
      corpo: 'Embora busquemos manter o aplicativo disponível, não '
          'garantimos funcionamento ininterrupto. Poderão ocorrer '
          'manutenções, atualizações ou falhas técnicas.\n\n'
          'Determinadas funcionalidades podem depender do dispositivo, '
          'do armazenamento local ou de serviços externos informados '
          'na Política de Privacidade.',
    ),
    SecaoTextoLegal(
      titulo: '5. Limitações e situações de emergência',
      corpo: 'As informações, questionários, resultados e sugestões '
          'apresentados pelo Mindful You têm caráter informativo '
          'ou demonstrativo e não constituem diagnóstico, prescrição '
          'ou tratamento médico ou psicológico.\n\n'
          'O aplicativo não oferece monitoramento clínico contínuo, '
          'atendimento profissional nem resposta a emergências em tempo real. '
          'Em situação de risco imediato, procure os serviços de '
          'emergência da sua região.',
    ),
    SecaoTextoLegal(
      titulo: '6. Alterações dos termos',
      corpo: 'Estes Termos de Uso poderão ser atualizados para refletir '
          'mudanças no aplicativo ou nas exigências aplicáveis. '
          'A versão atualizada será disponibilizada no aplicativo.\n\n'
          'Quando uma alteração exigir nova manifestação do usuário, '
          'serão adotadas as providências pertinentes antes da '
          'continuidade do tratamento ou da funcionalidade afetada.',
    ),
    SecaoTextoLegal(
      titulo: '7. Responsável e contato',
      corpo: 'O Mindful You é desenvolvido por Victor Hugo Ferreira Bellini, '
          'desenvolvedor independente.\n\n'
          'Para dúvidas, suporte, questões sobre idade mínima ou '
          'solicitações relacionadas à privacidade, entre em contato '
          'pelo e-mail:\n\n'
          'victorhfbellini.dev@gmail.com\n\n'
          'O tratamento de dados pessoais e os direitos dos titulares '
          'são descritos na Política de Privacidade.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const TelaLegalBase(
      titulo: 'Termos de Uso',
      subtitulo: 'Mindful You',
      ultimaAtualizacao: _ultimaAtualizacao,
      icone: Icons.description_outlined,
      introducao: 'Bem-vindo ao Mindful You.\n\n'
          'Esta versão é destinada exclusivamente a pessoas com '
          '18 anos ou mais. Ao utilizar o aplicativo, você concorda '
          'com estes Termos de Uso. Caso não concorde com as condições '
          'descritas, não utilize o aplicativo.',
      secoes: _secoes,
    );
  }
}
