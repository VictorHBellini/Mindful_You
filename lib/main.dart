import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'features/auth/firebase_teste_tela.dart';
import 'features/checkin/screens/resultado_grafico_screen.dart';
import 'features/history/historico_global.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Etapa F1: conecta ao projeto Firebase sem migrar os dados locais.
  // Execute `flutterfire configure` para gerar firebase_options.dart.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // F3.2.2-D — Configuração isolada dos emuladores Firebase.
  const usarEmuladores = bool.fromEnvironment(
    'MINDFUL_FIREBASE_EMULATORS',
    defaultValue: false,
  );

  if (usarEmuladores) {
    if (!kIsWeb && Platform.isAndroid) {
      const host = '10.0.2.2';

      await FirebaseAuth.instance.useAuthEmulator(host, 9099);

      FirebaseFunctions.instanceFor(
        region: 'southamerica-east1',
      ).useFunctionsEmulator(host, 5001);

      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);

      debugPrint('Mindful You: Firebase Emulator habilitado no Android.');
    } else {
      throw UnsupportedError(
        'O modo Demo Firebase está configurado somente para o emulador Android.',
      );
    }
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
