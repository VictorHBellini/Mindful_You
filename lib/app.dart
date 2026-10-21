import 'package:flutter/material.dart';

import 'routes.dart';
import 'core/theme/mindful_cores.dart';
import 'services/theme_service.dart';

class MindfulYouApp extends StatelessWidget {
  const MindfulYouApp({super.key});

  static const Color _primaryLight = MindfulCores.rosaPrimarioClaro;
  static const Color _primaryDark = MindfulCores.rosaPrimarioEscuro;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.mode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Mindful You',
          themeMode: themeMode,

          // ============================================================
          // TEMA CLARO
          // ============================================================
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            scaffoldBackgroundColor: MindfulCores.fundoClaro,
            colorScheme: ColorScheme.fromSeed(
              seedColor: _primaryLight,
              brightness: Brightness.light,
              surface: MindfulCores.superficieClara,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: MindfulCores.fundoClaro,
              foregroundColor: MindfulCores.marromTexto,
              elevation: 0,
              centerTitle: false,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: MindfulCores.bordaClara,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: MindfulCores.bordaClara,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: _primaryLight,
                  width: 1.5,
                ),
              ),
              labelStyle: const TextStyle(
                color: MindfulCores.marromSecundario,
              ),
              hintStyle: const TextStyle(
                color: MindfulCores.cinzaCampo,
              ),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return MindfulCores.cinzaCampo;
                },
              ),
              trackColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return _primaryLight;
                  }
                  return MindfulCores.trilhaSwitch;
                },
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: MindfulCores.bordaClara,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(
                color: MindfulCores.marromTexto,
              ),
              bodyMedium: TextStyle(
                color: MindfulCores.textoSecundario,
              ),
              bodySmall: TextStyle(
                color: MindfulCores.marromSecundario,
              ),
              titleLarge: TextStyle(
                color: MindfulCores.marromTexto,
                fontWeight: FontWeight.bold,
              ),
              titleMedium: TextStyle(
                color: MindfulCores.marromTexto,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // ============================================================
          // TEMA ESCURO
          // ============================================================
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: MindfulCores.fundoEscuro,
            colorScheme: ColorScheme.fromSeed(
              seedColor: _primaryDark,
              brightness: Brightness.dark,
              surface: MindfulCores.superficieEscura,
            ).copyWith(
              primary: _primaryDark,
              onPrimary: MindfulCores.contrasteRosaEscuro,
              secondary: MindfulCores.rosaSecundarioEscuro,
              surface: MindfulCores.superficieEscura,
              onSurface: MindfulCores.textoClaroEscuro,
              surfaceContainerHighest: MindfulCores.superficieAltaEscura,
            ),
            cardTheme: CardThemeData(
              color: MindfulCores.cartaoEscuro,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: MindfulCores.fundoEscuro,
              foregroundColor: MindfulCores.textoClaroEscuro,
              elevation: 0,
              centerTitle: false,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: MindfulCores.cartaoEscuro,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF3A3431),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF3A3431),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: _primaryDark,
                  width: 1.5,
                ),
              ),
              labelStyle: const TextStyle(
                color: Color(0xFFC5B8B1),
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF91837C),
              ),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF3A302F);
                  }
                  return const Color(0xFF91837C);
                },
              ),
              trackColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return _primaryDark;
                  }
                  return const Color(0xFF3A3431);
                },
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: Color(0xFF3A3431),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(
                color: MindfulCores.textoClaroEscuro,
              ),
              bodyMedium: TextStyle(
                color: Color(0xFFD2C5BE),
              ),
              bodySmall: TextStyle(
                color: Color(0xFFB0A19A),
              ),
              titleLarge: TextStyle(
                color: MindfulCores.textoClaroEscuro,
                fontWeight: FontWeight.bold,
              ),
              titleMedium: TextStyle(
                color: MindfulCores.textoClaroEscuro,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
