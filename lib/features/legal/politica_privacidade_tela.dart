import 'package:flutter/material.dart';

import '../../widgets/tela_legal_base.dart';

/// Política de Privacidade do Mindful You 1.0 (Android).
///
/// Manter este texto consistente com a política pública no GitHub.
/// Revisar novamente antes da publicação, especialmente os fluxos
/// efetivos de exclusão, retenção e os serviços externos utilizados.
class PoliticaPrivacidadeTela extends StatelessWidget {
  const PoliticaPrivacidadeTela({super.key});

  static const String _ultimaAtualizacao = 'Novembro de 2026';
  static const String _emailContato = 'victorhfbellini.dev@gmail.com';

  static const String _introducao =
      'Sua privacidade é importante para o Mindful You.\n\n'
      'Esta Política de Privacidade explica quais informações podem ser '
      'tratadas pelo aplicativo, para quais finalidades são utilizadas, '
      'como são armazenadas e quais direitos você possui em relação '
      'aos seus dados pessoais.\n\n'
      'O Mindful You 1.0 é destinado exclusivamente a pessoas com '
      '18 anos ou mais. O aplicativo oferece recursos de acompanhamento '
      'emocional e organização de registros pessoais. Algumas informações '
      'podem revelar aspectos sensíveis da vida privada e exigem '
      'cuidados adicionais de proteção.';

  static const List<SecaoTextoLegal> _secoes = [
    SecaoTextoLegal(
      titulo: '1. Dados pessoais tratados',
      corpo: 'Dependendo das funcionalidades utilizadas, '
          'o Mindful You poderá tratar:\n\n'
          '• Nome e endereço de e-mail;\n'
          '• Informações de cadastro e autenticação;\n'
          '• Foto de perfil, quando fornecida;\n'
          '• Check-ins emocionais e respectivos históricos;\n'
          '• Avaliações e registros pessoais;\n'
          '• Preferências do aplicativo, como o tema visual;\n'
          '• Informações técnicas necessárias ao funcionamento '
          'e à segurança dos serviços utilizados.\n\n'
          'Registros emocionais podem conter dados pessoais sensíveis, '
          'inclusive informações relacionadas à saúde, conforme seu conteúdo.',
    ),
    SecaoTextoLegal(
      titulo: '2. Finalidades do tratamento',
      corpo: 'Os dados podem ser utilizados para:\n\n'
          '• Permitir cadastro, autenticação e acesso à conta;\n'
          '• Disponibilizar check-ins e avaliações;\n'
          '• Apresentar históricos e informações pessoais;\n'
          '• Manter preferências de utilização;\n'
          '• Proteger a integridade dos registros;\n'
          '• Corrigir falhas e manter o funcionamento do aplicativo;\n'
          '• Atender solicitações de suporte e privacidade.\n\n'
          'Cada operação de tratamento deve observar uma base legal '
          'aplicável, inclusive as regras específicas da Lei Geral '
          'de Proteção de Dados Pessoais (LGPD) para dados sensíveis. '
          'A aceitação dos Termos de Uso não equivale, por si só, '
          'a consentimento para todos os tratamentos.',
    ),
    SecaoTextoLegal(
      titulo: '3. Armazenamento local e serviços externos',
      corpo: 'Na versão Android 1.0, o Mindful You utiliza armazenamento '
          'local SQLite para manter informações de conta e históricos '
          'no dispositivo do usuário.\n\n'
          'O aplicativo inicializa serviços Firebase, do Google. '
          'Existem também funcionalidades Firebase de laboratório, '
          'não disponibilizadas pela interface normal do Android '
          'em modo release.\n\n'
          'A inicialização dos serviços e eventuais operações de rede '
          'podem envolver informações técnicas. Os dados efetivamente '
          'processados dependem dos serviços ativados e das operações '
          'realizadas pela versão instalada.\n\n'
          'O armazenamento local não representa uma cópia de segurança '
          'recuperável em outro aparelho.',
    ),
    SecaoTextoLegal(
      titulo: '4. Compartilhamento e prestadores de serviços',
      corpo: 'O Mindful You não comercializa dados pessoais dos usuários.\n\n'
          'Determinadas informações podem ser processadas por prestadores '
          'de serviços tecnológicos, como o Google Firebase, conforme '
          'os recursos efetivamente utilizados.\n\n'
          'Também poderá ocorrer tratamento ou fornecimento de '
          'informações quando exigido por obrigação legal ou outra '
          'hipótese prevista na legislação.\n\n'
          'Os serviços externos devem ser utilizados de acordo com '
          'as finalidades informadas e as medidas de proteção aplicáveis.',
    ),
    SecaoTextoLegal(
      titulo: '5. Retenção e exclusão de dados',
      corpo: 'Os dados devem ser mantidos apenas pelo período necessário '
          'às finalidades informadas, ressalvadas as hipóteses legais '
          'de conservação.\n\n'
          'Na versão 1.0, os registros locais podem permanecer no '
          'dispositivo enquanto os dados do aplicativo forem mantidos. '
          'A remoção dos dados do aplicativo ou sua desinstalação '
          'pode ocasionar perda definitiva dos registros locais.\n\n'
          'Alguns registros identificados possuem mecanismos de '
          'integridade que podem impedir sua exclusão por operações '
          'diretas no banco de dados. Por isso, não é garantido que '
          'a exclusão de todos os registros possa ser realizada '
          'individualmente pela interface atual.\n\n'
          'Para solicitar análise de acesso, correção ou exclusão '
          'de dados, entre em contato pelo e-mail indicado nesta '
          'política. O atendimento observará os direitos aplicáveis '
          'e as limitações técnicas efetivamente existentes.\n\n'
          'A remoção de informações locais não implica necessariamente '
          'a exclusão de informações eventualmente mantidas por '
          'serviços externos.',
    ),
    SecaoTextoLegal(
      titulo: '6. Segurança e proteção',
      corpo: 'O Mindful You utiliza mecanismos destinados a reduzir '
          'riscos de acesso não autorizado, alteração indevida '
          'e perda de informações.\n\n'
          'Entre as medidas implementadas estão controles de sessão '
          'e mecanismos de integridade dos registros locais.\n\n'
          'Nenhum sistema oferece proteção absoluta. Recomendamos '
          'manter o dispositivo protegido e atualizado e não '
          'compartilhar credenciais de acesso.',
    ),
    SecaoTextoLegal(
      titulo: '7. Backup e recuperação',
      corpo: 'A versão Android 1.0 do Mindful You foi configurada '
          'para desabilitar o backup automático padrão do aplicativo.\n\n'
          'Essa configuração não garante o bloqueio de todas as '
          'formas de transferência de dados oferecidas por '
          'dispositivos e fabricantes.\n\n'
          'Como os históricos pessoais são mantidos localmente, '
          'a desinstalação do aplicativo, a perda do aparelho ou '
          'a remoção dos dados podem resultar na perda definitiva '
          'dessas informações.\n\n'
          'Não é garantida a recuperação automática dos históricos '
          'em outro dispositivo.',
    ),
    SecaoTextoLegal(
      titulo: '8. Direitos dos titulares',
      corpo: 'Nos termos da LGPD e conforme as hipóteses aplicáveis, '
          'o usuário poderá solicitar:\n\n'
          '• Confirmação da existência de tratamento;\n'
          '• Acesso aos seus dados pessoais;\n'
          '• Correção de dados incompletos ou incorretos;\n'
          '• Informações sobre compartilhamento de dados;\n'
          '• Anonimização, bloqueio ou eliminação, quando cabíveis;\n'
          '• Portabilidade, quando aplicável;\n'
          '• Informações sobre consentimento, revogação e demais '
          'direitos previstos em lei.\n\n'
          'As solicitações podem ser encaminhadas ao contato '
          'indicado ao final desta política.',
    ),
    SecaoTextoLegal(
      titulo: '9. Restrição etária: maiores de 18 anos',
      corpo: 'O Mindful You 1.0 é destinado exclusivamente a '
          'pessoas com 18 anos ou mais. O cadastro exige que '
          'a pessoa declare ser maior de idade.\n\n'
          'O aplicativo não realiza, nesta versão, verificação '
          'documental ou independente da idade informada.\n\n'
          'O uso por crianças e adolescentes não é autorizado '
          'nesta versão. Caso uma pessoa menor de 18 anos tenha '
          'criado uma conta ou utilizado o aplicativo, o responsável '
          'poderá entrar em contato pelo canal de privacidade '
          'para solicitar orientação e análise da situação, '
          'inclusive quanto aos dados eventualmente registrados.\n\n'
          'A confirmação de maioridade no cadastro não valida '
          'automaticamente a idade de contas criadas anteriormente.',
    ),
    SecaoTextoLegal(
      titulo: '10. Alterações desta política',
      corpo: 'Esta Política de Privacidade poderá ser atualizada '
          'para refletir mudanças nas funcionalidades, nos serviços '
          'utilizados ou nas exigências legais.\n\n'
          'A data da última atualização será apresentada neste '
          'documento. Alterações relevantes deverão ser '
          'comunicadas de forma adequada.',
    ),
    SecaoTextoLegal(
      titulo: '11. Contato e responsável pelo tratamento',
      corpo: 'O Mindful You é desenvolvido e mantido de forma '
          'independente por Victor Hugo Ferreira Bellini, '
          'pessoa física responsável pelas decisões relativas '
          'ao tratamento de dados pessoais realizado no '
          'âmbito do aplicativo.\n\n'
          'Para dúvidas, solicitações de acesso, correção ou '
          'exclusão de dados pessoais e outras questões '
          'relacionadas à privacidade, entre em contato pelo e-mail:\n\n'
          '$_emailContato\n\n'
          'As solicitações serão analisadas conforme a LGPD '
          'e demais disposições legais aplicáveis.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const TelaLegalBase(
      titulo: 'Política de Privacidade',
      subtitulo: 'Mindful You',
      ultimaAtualizacao: _ultimaAtualizacao,
      icone: Icons.lock_outline_rounded,
      introducao: _introducao,
      secoes: _secoes,
    );
  }
}
