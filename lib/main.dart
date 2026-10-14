import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'features/auth/firebase_teste_tela.dart';
import 'features/checkin/grafico_tela.dart';
import 'features/history/historico_global.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Etapa F1: conecta ao projeto Firebase sem migrar os dados locais.
  // Execute `flutterfire configure` para gerar firebase_options.dart.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const usarEmuladores = bool.fromEnvironment('MINDFUL_FIREBASE_EMULATORS', defaultValue: false);
  if (!kIsWeb && Platform.isAndroid && usarEmuladores) {
    await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
    FirebaseFunctions.instanceFor(region: 'southamerica-east1')
        .useFunctionsEmulator('10.0.2.2', 5001);
  }

  if (kIsWeb) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const FirebaseTesteTela(),
        onGenerateRoute: (settings) {
          if (settings.name == '/grafico') {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const GraficoTela(),
            );
          }
          return null;
        },
      ),
    );
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
