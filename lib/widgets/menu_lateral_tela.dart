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
  // `grafico_tela.dart`, para que todas as telas sempre mostrem a mesma
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
      const Duration(milliseconds: 100),
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            "Sair da conta",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF40352F),
            ),
          ),
          content: const Text(
            "Tem certeza que deseja encerrar sua sessão?",
            style: TextStyle(
              color: Color(0xFF756A64),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                "Cancelar",
                style: TextStyle(
                  color: Color(0xFF8D6E63),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                // Limpa dados da sessão antes de sair
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('nomeUsuario');
                await prefs.remove('emailUsuario');
                await prefs.remove('isAdmin');

                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB05C55),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
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
      backgroundColor: const Color(0xFFF8F5F2),
      child: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // CABEÇALHO
            // ======================================================

            _cabecalho(),

            const SizedBox(height: 18),

            // ======================================================
            // MENU PRINCIPAL
            // ======================================================

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
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
                          color: Color(0xFF9A8C84),
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

                    const SizedBox(height: 18),

                    _separador(),

                    const SizedBox(height: 18),

                    // ==================================================
                    // CONTA
                    // ==================================================

                    const Padding(
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
                          color: Color(0xFF9A8C84),
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

                    const SizedBox(height: 18),

                    _separador(),

                    const SizedBox(height: 18),

                    // ==================================================
                    // INFORMAÇÕES
                    // ==================================================

                    const Padding(
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
                          color: Color(0xFF9A8C84),
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

                    const SizedBox(height: 18),

                    // ==================================================
                    // ADMINISTRAÇÃO (visível só para o admin)
                    // ==================================================

                    if (isAdmin) ...[
                      _separador(),
                      const SizedBox(height: 18),
                      const Padding(
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
                            color: Color(0xFF9A8C84),
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
                      const SizedBox(height: 18),
                    ],

                    // ==================================================
                    // SAIR
                    // ==================================================

                    itemSair(
                      context,
                    ),

                    const SizedBox(height: 25),
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
      padding: const EdgeInsets.fromLTRB(
        22,
        25,
        22,
        25,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFE8DCD4),
            Color(0xFFF1E8E1),
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
                  padding: const EdgeInsets.all(4),
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
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const AvatarPerfil(radius: 40),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8D6E63),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // NOME
          Center(
            child: Text(
              nomeUsuario,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF40352F),
              ),
            ),
          ),

          const SizedBox(height: 5),

          // FRASE
          const Center(
            child: Text(
              "Cuide de você todos os dias 🌱",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF806F66),
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
      margin: const EdgeInsets.only(bottom: 7),
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
            padding: const EdgeInsets.symmetric(
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
                    color: const Color(0xFFF0E7E1),
                    borderRadius: BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: const Color(0xFF80675C),
                  ),
                ),

                const SizedBox(width: 13),

                // TEXTOS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F4039),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        descricao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF95877F),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 5),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFFB7AAA2),
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
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFF1D8D3),
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
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5DFDC),
                    borderRadius: BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 21,
                    color: Color(0xFFB05C55),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sair da conta",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9E4F49),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Encerrar sua sessão",
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB7837D),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFFBF8982),
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
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      color: const Color(0xFFE7DED8),
    );
  }

  // ================================================================
  // RODAPÉ
  // ================================================================

  Widget _rodape() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE9E0DB),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite_rounded,
                size: 13,
                color: Color(0xFFC89494),
              ),
              const SizedBox(width: 5),
              Text(
                "Mindful You",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF80675C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            "Versão 1.5.2",
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFFAAA09A),
            ),
          ),
        ],
      ),
    );
  }
}
