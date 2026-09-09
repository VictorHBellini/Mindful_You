import 'package:flutter/material.dart';
import 'package:mindful_you/features/assessment/grafico_tela.dart';
import 'package:mindful_you/features/assessment/registros_tela.dart';
import 'package:mindful_you/features/auth/cadastro_tela.dart';
import 'package:mindful_you/features/auth/login_tela.dart';
import 'package:mindful_you/features/auth/splashscreen_tela.dart';
import 'package:mindful_you/features/auth/gerenciar_usuarios_tela.dart';
import 'package:mindful_you/features/history/historico_tela.dart';
import 'package:mindful_you/features/home/inicial_tela.dart';
import 'package:mindful_you/features/profile/perfil_tela.dart';
import 'package:mindful_you/features/questionnaire/questionario_tela.dart';
import 'package:mindful_you/features/settings/configuracoes_tela.dart';
import 'package:mindful_you/features/legal/termos_uso_tela.dart';
import 'package:mindful_you/features/legal/politica_privacidade_tela.dart';
import 'package:mindful_you/widgets/dicas_page.dart';

class AppRoutes {
  static const splash = '/splashscreen';
  static const home = '/inicial';
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

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreenTela(),
    login: (context) => const LoginTela(),
    cadastro: (context) => const CadastroTela(),
    home: (context) => const InicialTela(),
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
}
