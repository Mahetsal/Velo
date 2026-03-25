import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uber_users_app/models/address_models.dart';

class AppInfoClass extends ChangeNotifier {
  static const String _languageKey = "app_language";
  static const String _themeModeKey = "app_theme_mode"; // system|light|dark

  AddressModel? pickUpLocation;
  AddressModel? dropOffLocation;

  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.system;
  bool _prefsLoaded = false;

  AppInfoClass() {
    _loadPrefs();
  }

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get prefsLoaded => _prefsLoaded;

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_languageKey) ?? "en";
    final theme = prefs.getString(_themeModeKey) ?? "system";

    _locale = Locale(lang == "ar" ? "ar" : "en");
    _themeMode = switch (theme) {
      "light" => ThemeMode.light,
      "dark" => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _prefsLoaded = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    final normalized = Locale(locale.languageCode == "ar" ? "ar" : "en");
    _locale = normalized;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _locale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => "light",
      ThemeMode.dark => "dark",
      ThemeMode.system => "system",
    };
    await prefs.setString(_themeModeKey, value);
  }

  void updatePickUpLocation(AddressModel pickUpModel) {
    pickUpLocation = pickUpModel;
    notifyListeners();
  }

  void updateDropOffLocation(AddressModel dropOffModel) {
    dropOffLocation = dropOffModel;
    notifyListeners();
  }
}