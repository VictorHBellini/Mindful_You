import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mindful_you/features/auth/services/session_service.dart';
import 'package:mindful_you/features/auth/firebase_teste_tela.dart';
import 'package:mindful_you/features/assessment/avaliacoes_tela.dart';
import 'package:mindful_you/features/patient/consentimentos_tela.dart';
import 'package:mindful_you/features/therapist/painel_terapeuta_tela.dart';
import 'package:mindful_you/features/checkin/screens/resultado_grafico_screen.dart';
import 'package:mindful_you/features/assessment/registros_tela.dart';
import 'package:mindful_you/features/auth/screens/cadastro_screen.dart';
import 'package:mindful_you/features/auth/screens/login_screen.dart';
import 'package:mindful_you/features/auth/screens/splash_screen.dart';
import 'package:mindful_you/features/auth/gerenciar_usuarios_tela.dart';
import 'package:mindful_you/features/history/screens/historico_screen.dart';
import 'package:mindful_you/features/home/inicial_tela.dart';
import 'package:mindful_you/features/profile/perfil_tela.dart';
import 'package:mindful_you/features/checkin/screens/questionario_screen.dart';
import 'package:mindful_you/features/settings/configuracoes_tela.dart';
import 'package:mindful_you/features/legal/termos_uso_tela.dart';
import 'package:mindful_you/features/legal/politica_privacidade_tela.dart';
import 'package:mindful_you/features/tips/screens/dicas_screen.dart';

class AppRoutes {
  static const firebaseTeste = '/firebase-teste';
  static const splash = '/splashscreen';
  static const home = '/inicial';
  static const painelTerapeuta = '/painel-terapeuta';
  static const consentimentos = '/consentimentos';
  static const avaliacoes = '/avaliacoes';
  static const login = '/login';
  static const cadastro = '/cadastro';
  static const questionario = '/questionario';
  static const grafico = '/grafico';
  static const historico = '/historico';
  static const registros = '/relatorio';
  static const perfil = '/perfil';
  static const configuracao = '/configuracao';
  static const usuarios = '/usuarios';
  static const dicas = '/dicas';
  static const termos = '/termos';
  static const privacidade = '/privacidade';

  static final Map<String, WidgetBuilder> _destinos = {
    firebaseTeste: (context) => const FirebaseTesteTela(),
    splash: (context) => const SplashScreenTela(),
    login: (context) => const LoginTela(),
    cadastro: (context) => const CadastroTela(),
    home: (context) => const InicialTela(),
    painelTerapeuta: (context) => const PainelTerapeutaTela(),
    consentimentos: (context) => const ConsentimentosTela(),
    avaliacoes: (context) => const AvaliacoesTela(),
    questionario: (context) => const QuestionarioTela(),
    grafico: (context) => const GraficoTela(),
    historico: (context) => HistoricoTela(),
    registros: (context) => const RegistrosTela(),
    perfil: (context) => PerfilTela(),
    configuracao: (context) => const ConfiguracaoTela(),
    dicas: (context) => const DicasTela(),
    usuarios: (context) => const GerenciarUsuariosTela(),
    termos: (context) => const TermosUsoTela(),
    privacidade: (context) => const PoliticaPrivacidadeTela(),
  };

  static final Map<String, WidgetBuilder> routes = {
    for (final entrada in _destinos.entries)
      entrada.key: (context) {
        // Web mantém autenticação Firebase própria; não misturar com SQLite.
        if (kIsWeb || _publicas.contains(entrada.key)) {
          return entrada.value(context);
        }
        return _RotaLocalProtegida(
          destino: entrada.value,
          somenteTerapeuta: entrada.key == painelTerapeuta,
        );
      },
  };

  static const _publicas = {
    firebaseTeste,
    splash,
    login,
    cadastro,
    termos,
    privacidade,
  };
}

class _RotaLocalProtegida extends StatefulWidget {
  const _RotaLocalProtegida({
    required this.destino,
    required this.somenteTerapeuta,
  });

  final WidgetBuilder destino;
  final bool somenteTerapeuta;

  @override
  State<_RotaLocalProtegida> createState() => _RotaLocalProtegidaState();
}

class _RotaLocalProtegidaState extends State<_RotaLocalProtegida> {
  late final Future<LocalSession?> _sessao = SessionService.validar();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LocalSession?>(
      future: _sessao,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final sessao = snapshot.data;
        if (snapshot.hasError ||
            sessao == null ||
            (widget.somenteTerapeuta && sessao.tipoUsuario != 'terapeuta')) {
          return Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false),
                child: const Text(
                    'Sessão inválida ou acesso não permitido. Voltar ao login'),
              ),
            ),
          );
        }
        return widget.destino(context);
      },
    );
  }
}
