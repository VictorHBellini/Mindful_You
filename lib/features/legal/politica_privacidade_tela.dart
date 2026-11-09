import 'package:flutter/material.dart';

import '../../widgets/tela_legal_base.dart';

/// Política de Privacidade do Mindful You.
///
/// Este documento informa como os dados pessoais são tratados
/// na versão 1.0 do aplicativo.
///
/// A política deve ser mantida consistente com a versão
/// pública disponibilizada no GitHub.
class PoliticaPrivacidadeTela extends StatelessWidget {
  const PoliticaPrivacidadeTela({super.key});

  static const String _ultimaAtualizacao = 'Novembro de 2026';

  static const String _emailContato = 'suporte@mindful.com';

  static const String _introducao =
      'Sua privacidade é importante para o Mindful You.\n\n'
      'Esta Política de Privacidade explica quais informações '
      'podem ser tratadas pelo aplicativo, para quais finalidades '
      'são utilizadas, como são armazenadas e quais direitos '
      'você possui em relação aos seus dados pessoais.\n\n'
      'O Mindful You oferece funcionalidades de acompanhamento '
      'emocional e organização de registros pessoais. '
      'Algumas informações podem revelar aspectos sensíveis '
      'da vida privada do usuário e, por isso, exigem '
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
          'Os registros emocionais podem conter informações '
          'relacionadas à saúde ou ao bem-estar e recebem '
          'tratamento compatível com sua natureza sensível.',
    ),
    SecaoTextoLegal(
      titulo: '2. Finalidades do tratamento',
      corpo: 'Os dados são utilizados para:\n\n'
          '• Permitir cadastro, autenticação e acesso à conta;\n'
          '• Disponibilizar check-ins e avaliações;\n'
          '• Apresentar históricos e informações pessoais;\n'
          '• Manter preferências de utilização;\n'
          '• Proteger a integridade dos registros;\n'
          '• Corrigir falhas e manter o funcionamento '
          'do aplicativo;\n'
          '• Atender solicitações de suporte e privacidade.\n\n'
          'O tratamento deve observar as bases legais '
          'aplicáveis da Lei Geral de Proteção de Dados '
          'Pessoais (LGPD).',
    ),
    SecaoTextoLegal(
      titulo: '3. Armazenamento local e serviços externos',
      corpo: 'O Mindful You utiliza armazenamento local SQLite '
          'para manter informações e históricos no dispositivo '
          'do usuário.\n\n'
          'O aplicativo também possui integração com serviços '
          'Firebase, do Google, incluindo recursos de '
          'autenticação e infraestrutura de dados.\n\n'
          'Os dados efetivamente processados por esses serviços '
          'dependem das funcionalidades utilizadas e das '
          'configurações da versão instalada.\n\n'
          'O armazenamento local não representa, por si só, '
          'uma cópia de segurança recuperável em outro aparelho.',
    ),
    SecaoTextoLegal(
      titulo: '4. Compartilhamento e prestadores de serviços',
      corpo: 'O Mindful You não comercializa dados pessoais '
          'dos usuários.\n\n'
          'Determinadas informações podem ser processadas '
          'por prestadores de serviços tecnológicos, '
          'como o Google Firebase, quando necessário '
          'para disponibilizar funcionalidades habilitadas.\n\n'
          'Também poderá ocorrer tratamento ou fornecimento '
          'de informações quando exigido por obrigação legal '
          'ou outra hipótese prevista na legislação.\n\n'
          'O uso desses serviços deve respeitar as finalidades '
          'informadas nesta política e as medidas de '
          'proteção aplicáveis.',
    ),
    SecaoTextoLegal(
      titulo: '5. Retenção e exclusão de dados',
      corpo: 'Os dados poderão ser mantidos enquanto forem '
          'necessários às finalidades informadas, observadas '
          'as hipóteses legais de conservação.\n\n'
          'O usuário poderá utilizar as funcionalidades '
          'disponíveis no aplicativo para solicitar ou '
          'realizar a exclusão de sua conta e de seus dados, '
          'conforme as condições técnicas aplicáveis.\n\n'
          'Alguns registros identificados possuem mecanismos '
          'de integridade que podem impedir sua remoção '
          'direta por determinadas operações do aplicativo.\n\n'
          'Quando a exclusão não puder ser concluída pela '
          'interface, o usuário poderá entrar em contato '
          'pelo canal indicado nesta política para receber '
          'orientações e solicitar a análise de seus direitos.\n\n'
          'A exclusão de informações locais não implica '
          'necessariamente a exclusão automática de dados '
          'eventualmente mantidos por serviços externos.',
    ),
    SecaoTextoLegal(
      titulo: '6. Segurança e proteção',
      corpo: 'O Mindful You adota mecanismos destinados '
          'a reduzir riscos de acesso não autorizado, '
          'alteração indevida e perda de informações.\n\n'
          'Entre as medidas implementadas estão controles '
          'de sessão e mecanismos de integridade '
          'dos registros locais.\n\n'
          'Nenhum sistema oferece proteção absoluta. '
          'Recomendamos que o usuário mantenha seu '
          'dispositivo protegido e atualizado, '
          'evitando compartilhar credenciais de acesso.',
    ),
    SecaoTextoLegal(
      titulo: '7. Backup e recuperação',
      corpo: 'A versão Android 1.0 do Mindful You foi '
          'configurada para desabilitar o backup '
          'automático padrão do aplicativo.\n\n'
          'Essa configuração não garante o bloqueio '
          'de todas as formas de transferência de dados '
          'oferecidas por dispositivos e fabricantes.\n\n'
          'Como os históricos pessoais são mantidos '
          'localmente, a desinstalação do aplicativo, '
          'a perda do aparelho ou a remoção dos dados '
          'podem resultar na perda definitiva '
          'dessas informações.\n\n'
          'Não é garantida a recuperação automática '
          'dos históricos em outro dispositivo.',
    ),
    SecaoTextoLegal(
      titulo: '8. Direitos dos titulares',
      corpo: 'Nos termos da LGPD e conforme as hipóteses '
          'aplicáveis, o usuário poderá solicitar:\n\n'
          '• Confirmação da existência de tratamento;\n'
          '• Acesso aos seus dados pessoais;\n'
          '• Correção de dados incompletos ou incorretos;\n'
          '• Informações sobre compartilhamento de dados;\n'
          '• Anonimização, bloqueio ou eliminação '
          'quando legalmente cabíveis;\n'
          '• Portabilidade, quando aplicável;\n'
          '• Informações sobre consentimento, '
          'revogação e demais direitos previstos em lei.\n\n'
          'As solicitações podem ser encaminhadas '
          'ao contato indicado ao final desta política.',
    ),
    SecaoTextoLegal(
      titulo: '9. Crianças e adolescentes',
      corpo: 'O tratamento de dados pessoais de crianças '
          'e adolescentes exige cuidados específicos '
          'e observância de seu melhor interesse.\n\n'
          'A utilização do aplicativo por esse público '
          'deve observar as condições de uso, '
          'as funcionalidades disponibilizadas '
          'e os requisitos legais aplicáveis.',
    ),
    SecaoTextoLegal(
      titulo: '10. Alterações desta política',
      corpo: 'Esta Política de Privacidade poderá ser '
          'atualizada para refletir alterações '
          'nas funcionalidades, nos serviços utilizados '
          'ou nas exigências legais.\n\n'
          'A data da última atualização será apresentada '
          'neste documento. Alterações relevantes '
          'deverão ser comunicadas de forma adequada.',
    ),
    SecaoTextoLegal(
      titulo: '11. Contato',
      corpo: 'Para dúvidas, solicitações ou questões '
          'relacionadas à privacidade e à proteção '
          'de dados pessoais, entre em contato pelo e-mail:\n\n'
          '$_emailContato\n\n'
          'As solicitações serão analisadas conforme '
          'a legislação aplicável.',
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
