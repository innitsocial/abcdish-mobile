import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  final String code;
  final String name;
  final String nativeName;
}

const supportedAppLanguages = [
  AppLanguage(code: 'en', name: 'English', nativeName: 'English'),
  AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
  AppLanguage(code: 'es', name: 'Spanish', nativeName: 'Español'),
  AppLanguage(code: 'fr', name: 'French', nativeName: 'Français'),
  AppLanguage(code: 'it', name: 'Italian', nativeName: 'Italiano'),
  AppLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
];

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(supportedAppLanguages.first) {
    _load();
  }

  static const _storageKey = 'app_language';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_storageKey);

    state = supportedAppLanguages.firstWhere(
      (language) => language.code == savedCode,
      orElse: () => supportedAppLanguages.first,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, language.code);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>(
  (ref) => LanguageNotifier(),
);
