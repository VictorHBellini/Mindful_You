import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:mindful_you/widgets/avatar_perfil.dart';
import 'package:mindful_you/widgets/menu_lateral_tela.dart';

class PerfilTela extends StatefulWidget {
  const PerfilTela({super.key});

  @override
  State<PerfilTela> createState() => _PerfilTelaState();
}

class _PerfilTelaState extends State<PerfilTela>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  /// ID do usuário no SQLite (null se ainda não carregado)
  int? _usuarioId;

  /// Caminho absoluto da foto salva no dispositivo (null = usa avatar padrão)
  String? _fotoPath;

  String nomeUsuario = "Usuário";
  String emailUsuario = "usuario@email.com";
  String criadoEm = "";

  // ================================================================
  // ANIMAÇÃO DA IMAGEM DE FUNDO
  // ================================================================

  late AnimationController _animacaoFundo;
  late Animation<double> _movimentoX;
  late Animation<double> _movimentoY;
  late Animation<double> _escala;

  @override
  void initState() {
    super.initState();

    carregarDados();

    _animacaoFundo = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _movimentoX = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _animacaoFundo, curve: Curves.easeInOut),
    );

    _movimentoY = Tween<double>(begin: -4, end: 6).animate(
      CurvedAnimation(parent: _animacaoFundo, curve: Curves.easeInOut),
    );

    _escala = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _animacaoFundo, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animacaoFundo.dispose();
    super.dispose();
  }

  // ================================================================
  // CARREGAR DADOS DO SQLITE + SHAREDPREFERENCES
  // ================================================================

  Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('emailUsuario') ?? '';

    // Busca o usuário completo no SQLite
    if (email.isNotEmpty) {
      final usuario = await DatabaseService.instance.buscarPorEmail(email);
      if (usuario != null && mounted) {
        final criado = usuario['criado_em'] as String? ?? '';
        String criadoFormatado = '';
        if (criado.isNotEmpty) {
          try {
            final dt = DateTime.parse(criado);
            const meses = [
              'janeiro',
              'fevereiro',
              'março',
              'abril',
              'maio',
              'junho',
              'julho',
              'agosto',
              'setembro',
              'outubro',
              'novembro',
              'dezembro',
            ];
            criadoFormatado =
                'Membro desde ${meses[dt.month - 1]} de ${dt.year}';
          } catch (_) {}
        }

        setState(() {
          _usuarioId = usuario['id'] as int?;
          nomeUsuario = usuario['nome'] as String? ?? 'Usuário';
          emailUsuario = usuario['email'] as String? ?? email;
          _fotoPath = usuario['foto_path'] as String?;
          criadoEm = criadoFormatado;
        });

        // Mantém SharedPreferences sincronizado
        await prefs.setString('nomeUsuario', nomeUsuario);
        await prefs.setString('emailUsuario', emailUsuario);
        if (_fotoPath != null) {
          await prefs.setString('fotoPerfil', _fotoPath!);
        }
      }
    }
  }

  // ================================================================
  // SALVAR NOME E EMAIL NO SQLITE + SHAREDPREFERENCES
  // ================================================================

  Future<void> salvarDados({
    required String nome,
    required String email,
  }) async {
    if (_usuarioId == null) return;

    await DatabaseService.instance.atualizarUsuario(
      id: _usuarioId!,
      nome: nome,
      email: email,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nomeUsuario', nome);
    await prefs.setString('emailUsuario', email);

    if (!mounted) return;
    setState(() {
      nomeUsuario = nome;
      emailUsuario = email;
    });
  }

  // ================================================================
  // SELECIONAR FOTO
  // ================================================================

  Future<void> _selecionarFoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 600,
    );
    if (picked == null) return;

    final path = picked.path;

    // Persiste no SQLite
    if (_usuarioId != null) {
      await DatabaseService.instance.atualizarFoto(
        id: _usuarioId!,
        fotoPath: path,
      );
    }

    // Persiste no SharedPreferences para uso em outras telas
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fotoPerfil', path);

    if (!mounted) return;
    setState(() => _fotoPath = path);
  }

  // ================================================================
  // WIDGET DA FOTO DE PERFIL
  // ================================================================

  Widget _buildFotoPerfil() {
    final hasFile = _fotoPath != null &&
        _fotoPath!.isNotEmpty &&
        File(_fotoPath!).existsSync();

    return Stack(
      children: [
        Container(
          width: 145,
          height: 145,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: hasFile
                ? Image.file(
                    File(_fotoPath!),
                    fit: BoxFit.cover,
                    width: 145,
                    height: 145,
                  )
                : Image.asset(
                    AvatarPerfil.assetPadrao,
                    fit: BoxFit.cover,
                    width: 145,
                    height: 145,
                  ),
          ),
        ),

        // BOTÃO DA CÂMERA
        Positioned(
          bottom: 5,
          right: 5,
          child: GestureDetector(
            onTap: mostrarOpcoesFoto,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF8D6E63),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: const MenuLateral(),
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ======================================================
              // CABEÇALHO
              // ======================================================

              Container(
                width: double.infinity,
                height: 330,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8DCD4), Color(0xFFF1E8E1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(35),
                  ),
                ),
                child: Stack(
                  children: [
                    // DECORAÇÃO ANIMADA
                    Positioned(
                      top: -80,
                      right: -90,
                      child: AnimatedBuilder(
                        animation: _animacaoFundo,
                        builder: (context, child) {
                          return Transform.translate(
                            offset:
                                Offset(_movimentoX.value, _movimentoY.value),
                            child: Transform.scale(
                              scale: _escala.value,
                              child: child,
                            ),
                          );
                        },
                        child: Opacity(
                          opacity: 0.15,
                          child: Image.asset(
                            'assets/img/6.png',
                            width: 280,
                            height: 260,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // MENU
                    Positioned(
                      top: 12,
                      left: 18,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => scaffoldKey.currentState?.openDrawer(),
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.menu_rounded,
                              size: 27,
                              color: Color(0xFF75665E),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // TÍTULO
                    const Positioned(
                      top: 22,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              "Meu perfil",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F4039),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // FOTO
                    Positioned(
                      bottom: -5,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildFotoPerfil()),
                    ),
                  ],
                ),
              ),

              // ======================================================
              // DADOS DO USUÁRIO
              // ======================================================

              const SizedBox(height: 25),

              Text(
                nomeUsuario,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF40352F),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                emailUsuario,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8A7B73),
                ),
              ),

              const SizedBox(height: 8),

              if (criadoEm.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9DDD5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    criadoEm,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF80675C),
                    ),
                  ),
                ),

              // ======================================================
              // CONFIGURAÇÕES
              // ======================================================

              const SizedBox(height: 28),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Configurações",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF40352F),
                      ),
                    ),

                    const SizedBox(height: 13),

                    opcaoPerfil(
                      icon: Icons.person_outline_rounded,
                      titulo: "Editar perfil",
                      descricao: "Atualize seus dados pessoais",
                      onTap: mostrarEditarPerfil,
                    ),

                    // Antes esta seção tinha atalhos próprios para
                    // Notificações, Privacidade e Termos de uso, cada um
                    // com sua própria implementação (uma delas nem
                    // salvava a preferência de notificação, e a exclusão
                    // de conta daqui não limpava todos os dados locais
                    // como a versão em Configurações). Para não ter duas
                    // fontes divergentes da mesma coisa, essas opções
                    // agora vivem só na tela de Configurações.
                    opcaoPerfil(
                      icon: Icons.tune_rounded,
                      titulo: "Ver todas as configurações",
                      descricao: "Notificações, tema, privacidade e conta",
                      onTap: () {
                        Navigator.pushNamed(context, '/configuracao');
                      },
                    ),

                    const SizedBox(height: 20),

                    // SAIR
                    GestureDetector(
                      onTap: mostrarDialogLogout,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4F2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFF1D8D3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5DFDC),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFB05C55),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 13),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Sair da conta",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF9E4F49),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Encerrar sua sessão",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFB7837D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 15,
                              color: Color(0xFFBF8982),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // INDICADOR DE PROGRESSO
  // ================================================================

  Widget indicadorProgresso({
    required IconData icone,
    required String valor,
    required String titulo,
  }) {
    return Column(
      children: [
        Icon(icone, size: 24, color: const Color(0xFFC89494)),
        const SizedBox(height: 5),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF40352F),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Color(0xFF95877F)),
        ),
      ],
    );
  }

  // ================================================================
  // OPÇÃO DE PERFIL
  // ================================================================

  Widget opcaoPerfil({
    required IconData icon,
    required String titulo,
    required String descricao,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8DFDA)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EAE5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: const Color(0xFF80675C), size: 23),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F4039),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descricao,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF95877F),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: Color(0xFFB0A29A),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // EDITAR PERFIL (CRUD SQLite)
  // ================================================================

  void mostrarEditarPerfil() {
    final nomeController = TextEditingController(text: nomeUsuario);
    final emailController = TextEditingController(text: emailUsuario);
    final senhaAtualController = TextEditingController();
    final novaSenhaController = TextEditingController();
    final confirmarSenhaController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool salvando = false;
    bool obscureSenhaAtual = true;
    bool obscureNovaSenha = true;
    bool obscureConfirmarSenha = true;
    String? erroSenha;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 25,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0D8D3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      "Editar perfil",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF40352F),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // NOME
                    TextFormField(
                      controller: nomeController,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Digite seu nome";
                        }
                        if (value.trim().length < 3) {
                          return "Digite um nome válido";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: "Nome completo",
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF8D6E63),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F3F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // EMAIL
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Digite seu e-mail";
                        }
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value.trim())) {
                          return "Digite um e-mail válido";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: "E-mail",
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF8D6E63),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F3F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Container(
                      height: 1,
                      color: const Color(0xFFE8DFDA),
                    ),

                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Alterar senha",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF40352F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Deixe os campos abaixo em branco para manter a senha atual.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF95877F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SENHA ATUAL
                    TextFormField(
                      controller: senhaAtualController,
                      obscureText: obscureSenhaAtual,
                      decoration: InputDecoration(
                        labelText: "Senha atual",
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF8D6E63),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureSenhaAtual
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF8D6E63),
                          ),
                          onPressed: () => setModal(
                            () => obscureSenhaAtual = !obscureSenhaAtual,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F3F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // NOVA SENHA
                    TextFormField(
                      controller: novaSenhaController,
                      obscureText: obscureNovaSenha,
                      decoration: InputDecoration(
                        labelText: "Nova senha",
                        prefixIcon: const Icon(
                          Icons.lock_reset_outlined,
                          color: Color(0xFF8D6E63),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNovaSenha
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF8D6E63),
                          ),
                          onPressed: () => setModal(
                            () => obscureNovaSenha = !obscureNovaSenha,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F3F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CONFIRMAR NOVA SENHA
                    TextFormField(
                      controller: confirmarSenhaController,
                      obscureText: obscureConfirmarSenha,
                      decoration: InputDecoration(
                        labelText: "Confirmar nova senha",
                        prefixIcon: const Icon(
                          Icons.lock_reset_outlined,
                          color: Color(0xFF8D6E63),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmarSenha
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF8D6E63),
                          ),
                          onPressed: () => setModal(
                            () =>
                                obscureConfirmarSenha = !obscureConfirmarSenha,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F3F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    if (erroSenha != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFFC0392B).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFC0392B),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                erroSenha!,
                                style: const TextStyle(
                                  color: Color(0xFFC0392B),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: salvando
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                final senhaAtual = senhaAtualController.text;
                                final novaSenha = novaSenhaController.text;
                                final confirmarSenha =
                                    confirmarSenhaController.text;

                                final quiseTrocarSenha =
                                    senhaAtual.isNotEmpty ||
                                        novaSenha.isNotEmpty ||
                                        confirmarSenha.isNotEmpty;

                                if (quiseTrocarSenha) {
                                  if (senhaAtual.isEmpty ||
                                      novaSenha.isEmpty ||
                                      confirmarSenha.isEmpty) {
                                    setModal(() => erroSenha =
                                        'Preencha os 3 campos de senha, ou deixe todos em branco.');
                                    return;
                                  }
                                  if (novaSenha.length < 8) {
                                    setModal(() => erroSenha =
                                        'A nova senha deve ter pelo menos 8 caracteres.');
                                    return;
                                  }
                                  if (novaSenha != confirmarSenha) {
                                    setModal(() => erroSenha =
                                        'A nova senha e a confirmação não coincidem.');
                                    return;
                                  }

                                  setModal(() {
                                    erroSenha = null;
                                    salvando = true;
                                  });

                                  final usuarioAtual = _usuarioId == null
                                      ? null
                                      : await DatabaseService.instance
                                          .buscarPorEmail(emailUsuario);

                                  if (usuarioAtual == null) {
                                    setModal(() {
                                      salvando = false;
                                      erroSenha =
                                          'Não foi possível confirmar seu usuário. Tente novamente.';
                                    });
                                    return;
                                  }

                                  final senhaAtualCorreta =
                                      await DatabaseService.instance
                                          .senhaCorreta(
                                    usuario: usuarioAtual,
                                    senhaDigitada: senhaAtual,
                                  );

                                  if (!senhaAtualCorreta) {
                                    setModal(() {
                                      salvando = false;
                                      erroSenha = 'Senha atual incorreta.';
                                    });
                                    return;
                                  }

                                  await DatabaseService.instance.atualizarSenha(
                                    id: _usuarioId!,
                                    novaSenha: novaSenha,
                                  );
                                } else {
                                  setModal(() => salvando = true);
                                }

                                await salvarDados(
                                  nome: nomeController.text.trim(),
                                  email: emailController.text.trim(),
                                );

                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      quiseTrocarSenha
                                          ? "Perfil e senha atualizados com sucesso!"
                                          : "Perfil atualizado com sucesso!",
                                    ),
                                    backgroundColor: const Color(0xFF8D6E63),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8D6E63),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: salvando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Salvar alterações",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================================================================
  // FOTO — seleciona da galeria ou câmera
  // ================================================================

  void mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Foto de perfil",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF40352F),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF8D6E63),
                  ),
                  title: const Text("Escolher da galeria"),
                  onTap: () async {
                    Navigator.pop(context);
                    await _selecionarFoto(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF8D6E63),
                  ),
                  title: const Text("Tirar uma foto"),
                  onTap: () async {
                    Navigator.pop(context);
                    await _selecionarFoto(ImageSource.camera);
                  },
                ),
                if (_fotoPath != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFB05C55),
                    ),
                    title: const Text(
                      "Remover foto",
                      style: TextStyle(color: Color(0xFFB05C55)),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      if (_usuarioId != null) {
                        await DatabaseService.instance.atualizarFoto(
                          id: _usuarioId!,
                          fotoPath: null,
                        );
                      }
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('fotoPerfil');
                      if (!mounted) return;
                      setState(() => _fotoPath = null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================================================================
  // LOGOUT (limpa SharedPreferences)
  // ================================================================

  void mostrarDialogLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text("Sair da conta"),
          content: const Text(
            "Tem certeza que deseja encerrar sua sessão?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Color(0xFF8D6E63)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Limpa sessão
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Sair",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
