import 'package:flutter/material.dart';

import 'routes.dart';
import 'services/theme_service.dart';

class MindfulYouApp extends StatelessWidget {
  const MindfulYouApp({super.key});

  static const Color _primaryLight = Color(0xFFC89494);
  static const Color _primaryDark = Color(0xFFD5A6A6);

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
            scaffoldBackgroundColor: const Color(0xFFF4F1ED),
            colorScheme: ColorScheme.fromSeed(
              seedColor: _primaryLight,
              brightness: Brightness.light,
              surface: const Color(0xFFF7F4F1),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF4F1ED),
              foregroundColor: Color(0xFF40352F),
              elevation: 0,
              centerTitle: false,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE8DFDA),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE8DFDA),
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
                color: Color(0xFF80675C),
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF9B8D85),
              ),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return const Color(0xFF9B8D85);
                },
              ),
              trackColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return _primaryLight;
                  }
                  return const Color(0xFFE2D9D4);
                },
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: Color(0xFFE8DFDA),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(
                color: Color(0xFF40352F),
              ),
              bodyMedium: TextStyle(
                color: Color(0xFF5E514A),
              ),
              bodySmall: TextStyle(
                color: Color(0xFF80675C),
              ),
              titleLarge: TextStyle(
                color: Color(0xFF40352F),
                fontWeight: FontWeight.bold,
              ),
              titleMedium: TextStyle(
                color: Color(0xFF40352F),
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
            scaffoldBackgroundColor: const Color(0xFF191716),
            colorScheme: ColorScheme.fromSeed(
              seedColor: _primaryDark,
              brightness: Brightness.dark,
              surface: const Color(0xFF201D1C),
            ).copyWith(
              primary: _primaryDark,
              onPrimary: const Color(0xFF2A2221),
              secondary: const Color(0xFFB99494),
              surface: const Color(0xFF201D1C),
              onSurface: const Color(0xFFF3ECE8),
              surfaceContainerHighest: const Color(0xFF2A2624),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF252120),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF191716),
              foregroundColor: Color(0xFFF3ECE8),
              elevation: 0,
              centerTitle: false,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF252120),
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
                color: Color(0xFFF3ECE8),
              ),
              bodyMedium: TextStyle(
                color: Color(0xFFD2C5BE),
              ),
              bodySmall: TextStyle(
                color: Color(0xFFB0A19A),
              ),
              titleLarge: TextStyle(
                color: Color(0xFFF3ECE8),
                fontWeight: FontWeight.bold,
              ),
              titleMedium: TextStyle(
                color: Color(0xFFF3ECE8),
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
