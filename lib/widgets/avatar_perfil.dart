import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mindful_you/features/auth/services/session_service.dart';
import 'package:mindful_you/services/database_service.dart';
import 'package:mindful_you/widgets/avatar_perfil_notifier.dart';

/// Avatar compartilhado do usuario autenticado.
class AvatarPerfil extends StatefulWidget {
  const AvatarPerfil({super.key, this.radius = 28});

  final double radius;

  static const String assetPadrao = 'assets/img/3.png';

  @override
  State<AvatarPerfil> createState() => _AvatarPerfilState();
}

class _AvatarPerfilState extends State<AvatarPerfil> {
  String? _fotoPath;
  int _revisaoLeitura = 0;

  @override
  void initState() {
    super.initState();
    AvatarPerfilNotifier.revisao.addListener(_carregarFoto);
    _carregarFoto();
  }

  Future<void> _carregarFoto() async {
    final revisao = ++_revisaoLeitura;

    // Nao mantem a foto anterior enquanto a sessao e consultada.
    if (mounted && _fotoPath != null) {
      setState(() => _fotoPath = null);
    }

    try {
      final sessao = await SessionService.validar();
      if (!mounted || revisao != _revisaoLeitura) return;

      if (sessao == null) {
        setState(() => _fotoPath = null);
        return;
      }

      // SQLite e a fonte de verdade para a foto do usuario.
      final db = await DatabaseService.instance.database;
      final registros = await db.query(
        'usuarios',
        columns: ['foto_path'],
        where: 'id = ?',
        whereArgs: [sessao.id],
        limit: 1,
      );

      if (!mounted || revisao != _revisaoLeitura) return;

      // Confirma que a identidade nao mudou durante a consulta.
      final prefs = await SharedPreferences.getInstance();

      if (!mounted || revisao != _revisaoLeitura) return;

      if (prefs.getInt('usuarioId') != sessao.id) {
        setState(() => _fotoPath = null);
        return;
      }

      final caminho = registros.length == 1
          ? registros.single['foto_path'] as String?
          : null;

      setState(() => _fotoPath = caminho);
    } catch (_) {
      if (!mounted || revisao != _revisaoLeitura) return;
      setState(() => _fotoPath = null);
    }
  }

  ImageProvider _imagemPerfil() {
    final caminho = _fotoPath;

    if (caminho != null && caminho.isNotEmpty && File(caminho).existsSync()) {
      return FileImage(File(caminho));
    }

    return const AssetImage(AvatarPerfil.assetPadrao);
  }

  @override
  void dispose() {
    AvatarPerfilNotifier.revisao.removeListener(_carregarFoto);
    _revisaoLeitura++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: _imagemPerfil(),
    );
  }
}
