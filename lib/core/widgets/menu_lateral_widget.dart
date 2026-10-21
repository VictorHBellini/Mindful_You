import 'package:mindful_you/features/auth/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mindful_you/services/admin_service.dart';
import 'package:mindful_you/widgets/avatar_perfil.dart';

class MenuLateral extends StatefulWidget {
  const MenuLateral({super.key});

  @override
  State<MenuLateral> createState() => _MenuLateralState();
}

class _MenuLateralState extends State<MenuLateral> {
  Color _cor(int claro, int escuro) =>
      Color(Theme.of(context).brightness == Brightness.dark ? escuro : claro);

  String nomeUsuario = "Usuário";
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  // ================================================================
  // CARREGAR DADOS DO USUÁRIO
  // ================================================================

  Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    final admin = await AdminService.statusAdminSalvo();

    if (!mounted) return;

    setState(() {
      nomeUsuario = prefs.getString('nomeUsuario') ?? "Usuário";
      isAdmin = admin;
    });
  }

  // ================================================================
  // FOTO DE PERFIL
  // ================================================================
  //
  // A leitura da foto salva (chave 'fotoPerfil') e o fallback para o
  // avatar padrão agora vivem em `AvatarPerfil` (widgets/avatar_perfil.dart),
  // compartilhado com `inicial_tela.dart`, `historico_tela.dart` e
  // `resultado_grafico_screen.dart`, para que todas as telas sempre mostrem a mesma
  // foto de perfil.

  // ================================================================
  // NAVEGAÇÃO
  // ================================================================

  void navegarPara(
    BuildContext context,
    String rota,
  ) {
    Navigator.pop(context);

    Future.delayed(
      Duration(milliseconds: 100),
      () {
        if (!context.mounted) return;

        Navigator.pushNamed(
          context,
          rota,
        );
      },
    );
  }

  // ================================================================
  // LOGOUT
  // ================================================================

  void mostrarDialogLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cor(0xFFFFFFFF, 0xFF292529),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            "Sair da conta",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _cor(0xFF40352F, 0xFFF4E9E6),
            ),
          ),
          content: Text(
            "Tem certeza que deseja encerrar sua sessão?",
            style: TextStyle(
              color: _cor(0xFF756A64, 0xFFC9B9B4),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                "Cancelar",
                style: TextStyle(
                  color: _cor(0xFF8D6E63, 0xFFD7A99D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await SessionService.encerrar();

                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _cor(0xFFB05C55, 0xFFC77973),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Sair",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: [MediaQuery.of(context).size.width * 0.82, 340.0]
          .reduce((a, b) => a < b ? a : b),
      backgroundColor: _cor(0xFFF8F5F2, 0xFF171719),
      child: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // CABEÇALHO
            // ======================================================

            _cabecalho(),

            SizedBox(height: 18),

            // ======================================================
            // MENU PRINCIPAL
            // ======================================================

            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: 8,
                        bottom: 8,
                      ),
                      child: Text(
                        "MENU PRINCIPAL",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: _cor(0xFF9A8C84, 0xFFB5A6A3),
                        ),
                      ),
                    ),

                    // INÍCIO
                    itemMenu(
                      context: context,
                      icon: Icons.home_rounded,
                      titulo: "Início",
                      descricao: "Veja seu resumo do dia",
                      rota: "/inicial",
                    ),

                    // CHECK-IN
                    itemMenu(
                      context: context,
                      icon: Icons.psychology_alt_outlined,
                      titulo: "Check-in emocional",
                      descricao: "Registre como você está",
                      rota: "/questionario",
                    ),

                    // HISTÓRICO
                    itemMenu(
                      context: context,
                      icon: Icons.bar_chart_rounded,
                      titulo: "Meu histórico",
                      descricao: "Acompanhe sua evolução",
                      rota: "/historico",
                    ),

                    SizedBox(height: 18),

                    _separador(),

                    SizedBox(height: 18),

                    // ==================================================
                    // CONTA
                    // ==================================================

                    Padding(
                      padding: EdgeInsets.only(
                        left: 8,
                        bottom: 8,
                      ),
                      child: Text(
                        "MINHA CONTA",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: _cor(0xFF9A8C84, 0xFFB5A6A3),
                        ),
                      ),
                    ),

                    // PERFIL
                    itemMenu(
                      context: context,
                      icon: Icons.person_outline_rounded,
                      titulo: "Meu perfil",
                      descricao: "Seus dados e progresso",
                      rota: "/perfil",
                    ),

                    // CONFIGURAÇÕES
                    itemMenu(
                      context: context,
                      icon: Icons.settings_outlined,
                      titulo: "Configurações",
                      descricao: "Preferências do aplicativo",
                      rota: '/configuracao',
                    ),

                    SizedBox(height: 18),

                    _separador(),

                    SizedBox(height: 18),

                    // ==================================================
                    // INFORMAÇÕES
                    // ==================================================

                    Padding(
                      padding: EdgeInsets.only(
                        left: 8,
                        bottom: 8,
                      ),
                      child: Text(
                        "INFORMAÇÕES",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: _cor(0xFF9A8C84, 0xFFB5A6A3),
                        ),
                      ),
                    ),

                    // TERMOS
                    itemMenu(
                      context: context,
                      icon: Icons.description_outlined,
                      titulo: "Termos de uso",
                      descricao: "Leia os termos do aplicativo",
                      rota: "/termos",
                    ),

                    // PRIVACIDADE
                    itemMenu(
                      context: context,
                      icon: Icons.lock_outline_rounded,
                      titulo: "Privacidade",
                      descricao: "Controle seus dados",
                      rota: "/privacidade",
                    ),

                    SizedBox(height: 18),

                    // ==================================================
                    // ADMINISTRAÇÃO (visível só para o admin)
                    // ==================================================

                    if (isAdmin) ...[
                      _separador(),
                      SizedBox(height: 18),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 8,
                          bottom: 8,
                        ),
                        child: Text(
                          "ADMINISTRAÇÃO",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: _cor(0xFF9A8C84, 0xFFB5A6A3),
                          ),
                        ),
                      ),
                      itemMenu(
                        context: context,
                        icon: Icons.admin_panel_settings_outlined,
                        titulo: "Gerenciar usuários",
                        descricao: "Veja e edite os cadastros",
                        rota: "/usuarios",
                      ),
                      SizedBox(height: 18),
                    ],

                    // ==================================================
                    // SAIR
                    // ==================================================

                    itemSair(
                      context,
                    ),

                    SizedBox(height: 25),
                  ],
                ),
              ),
            ),

            // ======================================================
            // RODAPÉ
            // ======================================================

            _rodape(),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // CABEÇALHO
  // ================================================================

  Widget _cabecalho() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        22,
        25,
        22,
        25,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _cor(0xFFE8DCD4, 0xFF342B30),
            _cor(0xFFF1E8E1, 0xFF272327),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FOTO
          Center(
            child: Stack(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: AvatarPerfil(radius: 40),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: _cor(0xFF8D6E63, 0xFFD7A99D),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 15),

          // NOME
          Center(
            child: Text(
              nomeUsuario,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: _cor(0xFF40352F, 0xFFF4E9E6),
              ),
            ),
          ),

          SizedBox(height: 5),

          // FRASE
          Center(
            child: Text(
              "Cuide de você todos os dias 🌱",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _cor(0xFF806F66, 0xFFC7B7B1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ITEM DO MENU
  // ================================================================

  Widget itemMenu({
    required BuildContext context,
    required IconData icon,
    required String titulo,
    required String descricao,
    String? rota,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap ??
              () {
                if (rota != null) {
                  navegarPara(
                    context,
                    rota,
                  );
                }
              },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 11,
            ),
            child: Row(
              children: [
                // ÍCONE
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _cor(0xFFF0E7E1, 0xFF352E32),
                    borderRadius: BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: _cor(0xFF80675C, 0xFFD8B5AA),
                  ),
                ),

                SizedBox(width: 13),

                // TEXTOS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _cor(0xFF4F4039, 0xFFF5EAE6),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        descricao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: _cor(0xFF95877F, 0xFFB9AAA5),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 5),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: _cor(0xFFB7AAA2, 0xFF9F908D),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // ITEM SAIR
  // ================================================================

  Widget itemSair(
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _cor(0xFFFFF4F2, 0xFF38282C),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _cor(0xFFF1D8D3, 0xFF634047),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () {
            mostrarDialogLogout(
              context,
            );
          },
          child: Padding(
            padding: EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: _cor(0xFFF5DFDC, 0xFF56343C),
                    borderRadius: BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 21,
                    color: _cor(0xFFB05C55, 0xFFC77973),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sair da conta",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _cor(0xFF9E4F49, 0xFFF4A9A4),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Encerrar sua sessão",
                        style: TextStyle(
                          fontSize: 11,
                          color: _cor(0xFFB7837D, 0xFFD5A5A2),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: _cor(0xFFBF8982, 0xFFD3A09D),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SEPARADOR
  // ================================================================

  Widget _separador() {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(
        horizontal: 8,
      ),
      color: _cor(0xFFE7DED8, 0xFF443B3E),
    );
  }

  // ================================================================
  // RODAPÉ
  // ================================================================

  Widget _rodape() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: _cor(0xFFFFFFFF, 0xFF252226),
        border: Border(
          top: BorderSide(
            color: _cor(0xFFE9E0DB, 0xFF40363A),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 13,
                color: _cor(0xFFC89494, 0xFFE1A2AC),
              ),
              SizedBox(width: 5),
              Text(
                "Mindful You",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _cor(0xFF80675C, 0xFFD8B5AA),
                ),
              ),
            ],
          ),
          SizedBox(height: 3),
          Text(
            "Versão 1.5.2",
            style: TextStyle(
              fontSize: 10,
              color: _cor(0xFFAAA09A, 0xFFAFA1A1),
            ),
          ),
        ],
      ),
    );
  }
}
