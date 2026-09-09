import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._();

  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    mode.value = (preferences.getBool('temaEscuro') ?? false)
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  static Future<void> setDark(bool isDark) async {
    mode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('temaEscuro', isDark);
  }
}
