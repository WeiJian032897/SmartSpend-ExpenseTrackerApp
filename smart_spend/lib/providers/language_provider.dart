import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  
  Locale get currentLocale => _currentLocale;
  
  String get currentLanguageCode => _currentLocale.languageCode;
  
  String get currentLanguageName {
    switch (_currentLocale.languageCode) {
      case 'zh':
        return '简体中文';
      case 'en':
      default:
        return 'English';
    }
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_currentLocale.languageCode != languageCode) {
      _currentLocale = Locale(languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);
      notifyListeners();
    }
  }

  List<Map<String, String>> get supportedLanguages => [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'zh', 'name': 'Simplified Chinese', 'nativeName': '简体中文'},
  ];
}