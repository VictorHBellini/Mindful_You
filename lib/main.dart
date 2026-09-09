import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'features/history/historico_global.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    runApp(const _MindfulYouWebNaoSuportado());
    return;
  }

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await carregarHistorico();
  await ThemeService.load();

  runApp(const MindfulYouApp());
}

class _MindfulYouWebNaoSuportado extends StatelessWidget {
  const _MindfulYouWebNaoSuportado();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mindful You',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F4F1),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC89494)),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.web_asset_off_rounded,
                    size: 48,
                    color: Color(0xFF8D6E63),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Versão web ainda não disponível',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF40352F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'O Mindful You usa armazenamento local no dispositivo '
                    'para login e perfil, que ainda não é suportado no '
                    'navegador. Abra o app no Android, iOS, Windows ou '
                    'Linux.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF80675C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
