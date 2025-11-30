import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _notificationsKey = 'notifications_enabled';
  static const String _languageKey = 'language_code';

  bool _notificationsEnabled = true;
  String _languageCode = 'en';

  bool get notificationsEnabled => _notificationsEnabled;
  String get languageCode => _languageCode;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    _languageCode = prefs.getString(_languageKey) ?? 'en';
    notifyListeners();
  }

  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, _notificationsEnabled);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _languageCode);
    notifyListeners();
  }
}
