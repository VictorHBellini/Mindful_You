import 'package:flutter/material.dart';

import 'routes.dart';
import 'services/theme_service.dart';

class MindfulYouApp extends StatelessWidget {
  const MindfulYouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.mode,
      builder: (context, themeMode, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mindful You',
        themeMode: themeMode,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFF7F4F1),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC89494),
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC89494),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );
  }
}
