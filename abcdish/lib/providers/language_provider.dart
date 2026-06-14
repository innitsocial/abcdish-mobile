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
  AppLanguage(code: 'af', name: 'Afrikaans', nativeName: 'Afrikaans'),
  AppLanguage(code: 'sq', name: 'Albanian', nativeName: 'Shqip'),
  AppLanguage(code: 'am', name: 'Amharic', nativeName: 'አማርኛ'),
  AppLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
  AppLanguage(code: 'hy', name: 'Armenian', nativeName: 'Հայերեն'),
  AppLanguage(code: 'az', name: 'Azerbaijani', nativeName: 'Azərbaycanca'),
  AppLanguage(code: 'eu', name: 'Basque', nativeName: 'Euskara'),
  AppLanguage(code: 'be', name: 'Belarusian', nativeName: 'Беларуская'),
  AppLanguage(code: 'bn', name: 'Bengali', nativeName: 'বাংলা'),
  AppLanguage(code: 'bs', name: 'Bosnian', nativeName: 'Bosanski'),
  AppLanguage(code: 'bg', name: 'Bulgarian', nativeName: 'Български'),
  AppLanguage(code: 'ca', name: 'Catalan', nativeName: 'Català'),
  AppLanguage(code: 'ceb', name: 'Cebuano', nativeName: 'Cebuano'),
  AppLanguage(code: 'ny', name: 'Chichewa', nativeName: 'Chichewa'),
  AppLanguage(code: 'zh', name: 'Chinese', nativeName: '中文'),
  AppLanguage(code: 'co', name: 'Corsican', nativeName: 'Corsu'),
  AppLanguage(code: 'hr', name: 'Croatian', nativeName: 'Hrvatski'),
  AppLanguage(code: 'cs', name: 'Czech', nativeName: 'Čeština'),
  AppLanguage(code: 'da', name: 'Danish', nativeName: 'Dansk'),
  AppLanguage(code: 'nl', name: 'Dutch', nativeName: 'Nederlands'),
  AppLanguage(code: 'en', name: 'English', nativeName: 'English'),
  AppLanguage(code: 'eo', name: 'Esperanto', nativeName: 'Esperanto'),
  AppLanguage(code: 'et', name: 'Estonian', nativeName: 'Eesti'),
  AppLanguage(code: 'tl', name: 'Filipino', nativeName: 'Filipino'),
  AppLanguage(code: 'fi', name: 'Finnish', nativeName: 'Suomi'),
  AppLanguage(code: 'fr', name: 'French', nativeName: 'Français'),
  AppLanguage(code: 'fy', name: 'Frisian', nativeName: 'Frysk'),
  AppLanguage(code: 'gl', name: 'Galician', nativeName: 'Galego'),
  AppLanguage(code: 'ka', name: 'Georgian', nativeName: 'ქართული'),
  AppLanguage(code: 'de', name: 'German', nativeName: 'Deutsch'),
  AppLanguage(code: 'el', name: 'Greek', nativeName: 'Ελληνικά'),
  AppLanguage(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી'),
  AppLanguage(code: 'ht', name: 'Haitian Creole', nativeName: 'Kreyòl Ayisyen'),
  AppLanguage(code: 'ha', name: 'Hausa', nativeName: 'Hausa'),
  AppLanguage(code: 'haw', name: 'Hawaiian', nativeName: 'ʻŌlelo Hawaiʻi'),
  AppLanguage(code: 'he', name: 'Hebrew', nativeName: 'עברית'),
  AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
  AppLanguage(code: 'hmn', name: 'Hmong', nativeName: 'Hmoob'),
  AppLanguage(code: 'hu', name: 'Hungarian', nativeName: 'Magyar'),
  AppLanguage(code: 'is', name: 'Icelandic', nativeName: 'Íslenska'),
  AppLanguage(code: 'ig', name: 'Igbo', nativeName: 'Igbo'),
  AppLanguage(code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia'),
  AppLanguage(code: 'ga', name: 'Irish', nativeName: 'Gaeilge'),
  AppLanguage(code: 'it', name: 'Italian', nativeName: 'Italiano'),
  AppLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語'),
  AppLanguage(code: 'jv', name: 'Javanese', nativeName: 'Basa Jawa'),
  AppLanguage(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ'),
  AppLanguage(code: 'kk', name: 'Kazakh', nativeName: 'Қазақша'),
  AppLanguage(code: 'km', name: 'Khmer', nativeName: 'ខ្មែរ'),
  AppLanguage(code: 'rw', name: 'Kinyarwanda', nativeName: 'Kinyarwanda'),
  AppLanguage(code: 'ko', name: 'Korean', nativeName: '한국어'),
  AppLanguage(code: 'ku', name: 'Kurdish', nativeName: 'Kurdî'),
  AppLanguage(code: 'ky', name: 'Kyrgyz', nativeName: 'Кыргызча'),
  AppLanguage(code: 'lo', name: 'Lao', nativeName: 'ລາວ'),
  AppLanguage(code: 'la', name: 'Latin', nativeName: 'Latina'),
  AppLanguage(code: 'lv', name: 'Latvian', nativeName: 'Latviešu'),
  AppLanguage(code: 'lt', name: 'Lithuanian', nativeName: 'Lietuvių'),
  AppLanguage(code: 'lb', name: 'Luxembourgish', nativeName: 'Lëtzebuergesch'),
  AppLanguage(code: 'mk', name: 'Macedonian', nativeName: 'Македонски'),
  AppLanguage(code: 'mg', name: 'Malagasy', nativeName: 'Malagasy'),
  AppLanguage(code: 'ms', name: 'Malay', nativeName: 'Bahasa Melayu'),
  AppLanguage(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം'),
  AppLanguage(code: 'mt', name: 'Maltese', nativeName: 'Malti'),
  AppLanguage(code: 'mi', name: 'Maori', nativeName: 'Māori'),
  AppLanguage(code: 'mr', name: 'Marathi', nativeName: 'मराठी'),
  AppLanguage(code: 'mn', name: 'Mongolian', nativeName: 'Монгол'),
  AppLanguage(code: 'my', name: 'Burmese', nativeName: 'မြန်မာ'),
  AppLanguage(code: 'ne', name: 'Nepali', nativeName: 'नेपाली'),
  AppLanguage(code: 'no', name: 'Norwegian', nativeName: 'Norsk'),
  AppLanguage(code: 'or', name: 'Odia', nativeName: 'ଓଡ଼ିଆ'),
  AppLanguage(code: 'ps', name: 'Pashto', nativeName: 'پښتو'),
  AppLanguage(code: 'fa', name: 'Persian', nativeName: 'فارسی'),
  AppLanguage(code: 'pl', name: 'Polish', nativeName: 'Polski'),
  AppLanguage(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
  AppLanguage(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ'),
  AppLanguage(code: 'ro', name: 'Romanian', nativeName: 'Română'),
  AppLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский'),
  AppLanguage(code: 'sm', name: 'Samoan', nativeName: 'Gagana Samoa'),
  AppLanguage(code: 'gd', name: 'Scots Gaelic', nativeName: 'Gàidhlig'),
  AppLanguage(code: 'sr', name: 'Serbian', nativeName: 'Српски'),
  AppLanguage(code: 'st', name: 'Sesotho', nativeName: 'Sesotho'),
  AppLanguage(code: 'sn', name: 'Shona', nativeName: 'ChiShona'),
  AppLanguage(code: 'sd', name: 'Sindhi', nativeName: 'سنڌي'),
  AppLanguage(code: 'si', name: 'Sinhala', nativeName: 'සිංහල'),
  AppLanguage(code: 'sk', name: 'Slovak', nativeName: 'Slovenčina'),
  AppLanguage(code: 'sl', name: 'Slovenian', nativeName: 'Slovenščina'),
  AppLanguage(code: 'so', name: 'Somali', nativeName: 'Soomaali'),
  AppLanguage(code: 'es', name: 'Spanish', nativeName: 'Español'),
  AppLanguage(code: 'su', name: 'Sundanese', nativeName: 'Basa Sunda'),
  AppLanguage(code: 'sw', name: 'Swahili', nativeName: 'Kiswahili'),
  AppLanguage(code: 'sv', name: 'Swedish', nativeName: 'Svenska'),
  AppLanguage(code: 'tg', name: 'Tajik', nativeName: 'Тоҷикӣ'),
  AppLanguage(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்'),
  AppLanguage(code: 'tt', name: 'Tatar', nativeName: 'Татарча'),
  AppLanguage(code: 'te', name: 'Telugu', nativeName: 'తెలుగు'),
  AppLanguage(code: 'th', name: 'Thai', nativeName: 'ไทย'),
  AppLanguage(code: 'tr', name: 'Turkish', nativeName: 'Türkçe'),
  AppLanguage(code: 'tk', name: 'Turkmen', nativeName: 'Türkmençe'),
  AppLanguage(code: 'uk', name: 'Ukrainian', nativeName: 'Українська'),
  AppLanguage(code: 'ur', name: 'Urdu', nativeName: 'اردو'),
  AppLanguage(code: 'ug', name: 'Uyghur', nativeName: 'ئۇيغۇرچە'),
  AppLanguage(code: 'uz', name: 'Uzbek', nativeName: 'Oʻzbekcha'),
  AppLanguage(code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt'),
  AppLanguage(code: 'cy', name: 'Welsh', nativeName: 'Cymraeg'),
  AppLanguage(code: 'xh', name: 'Xhosa', nativeName: 'isiXhosa'),
  AppLanguage(code: 'yi', name: 'Yiddish', nativeName: 'ייִדיש'),
  AppLanguage(code: 'yo', name: 'Yoruba', nativeName: 'Yorùbá'),
  AppLanguage(code: 'zu', name: 'Zulu', nativeName: 'isiZulu'),
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
