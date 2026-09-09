import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Avatar compartilhado que exibe a foto de perfil do usuário logado.
///
/// BUG CORRIGIDO: `inicial_tela.dart`, `historico_tela.dart` e
/// `grafico_tela.dart` mostravam uma imagem fixa (`assets/img/3.jpg` ou
/// `assets/img/perfil.png`) no avatar do topo, então ele nunca refletia
/// a foto que o usuário realmente escolheu em `perfil_tela.dart` — só
/// `menu_lateral_tela.dart` mostrava a foto certa. Agora todas essas
/// telas usam este widget único, que lê a mesma chave (`fotoPerfil`)
/// salva pelo perfil e cai no mesmo avatar padrão quando não há foto
/// (ou o arquivo não existe mais).
class AvatarPerfil extends StatefulWidget {
  const AvatarPerfil({super.key, this.radius = 28});

  final double radius;

  /// Caminho do asset usado quando o usuário não tem foto salva (ou o
  /// arquivo não existe mais). Fonte única desse caminho — outras telas
  /// que precisem do mesmo fallback (ex: `perfil_tela.dart`, que edita a
  /// foto e por isso não usa este widget diretamente) devem referenciar
  /// esta constante em vez de repetir a string, para não reintroduzir a
  /// divergência descrita acima.
  static const String assetPadrao = 'assets/img/3.png';

  @override
  State<AvatarPerfil> createState() => _AvatarPerfilState();
}

class _AvatarPerfilState extends State<AvatarPerfil> {
  String? _fotoPath;

  @override
  void initState() {
    super.initState();
    _carregarFoto();
  }

  Future<void> _carregarFoto() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fotoPath = prefs.getString('fotoPerfil');
    });
  }

  ImageProvider _imagemPerfil() {
    final caminho = _fotoPath;
    if (caminho != null && caminho.isNotEmpty && File(caminho).existsSync()) {
      return FileImage(File(caminho));
    }
    return const AssetImage(AvatarPerfil.assetPadrao);
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: _imagemPerfil(),
    );
  }
}
