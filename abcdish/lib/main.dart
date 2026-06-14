import 'package:abcdish/core/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/l10n/app_text.dart';
import 'package:abcdish/providers/theme_mode_provider.dart';
import 'package:abcdish/screens/splash.dart';
import 'package:abcdish/screens/tabs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppErrorHandler.initialize();

  runApp(const ProviderScope(child: ABCDishApp()));
}

class ABCDishApp extends ConsumerWidget {
  const ABCDishApp({super.key});

  static const _brandTomato = Color(0xFFE94335);
  static const _freshHerb = Color(0xFF2E7D32);
  static const _pageBackground = Color(0xFFF4F5F7);
  static const _navWarm = Color(0xFFFFF7F2);
  static const _navIndicator = Color(0xFFFFD8C9);
  static const _surfaceWhite = Color(0xFFFFFFFF);
  static const _textDark = Color(0xFF050505);
  static const _mutedText = Color(0xFF65676B);
  static const _darkBackground = Color(0xFF101210);
  static const _darkSurface = Color(0xFF1A1D19);
  static const _darkNav = Color(0xFF182116);
  static const _darkText = Color(0xFFF8F8F3);
  static const _darkMutedText = Color(0xFFC2C8BC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final text = ref.watch(appTextProvider);

    return MaterialApp(
      title: text.appTitle,
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      themeMode: themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const SplashScreen(child: TabsScreen()),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _brandTomato,
          brightness: brightness,
        ).copyWith(
          primary: _brandTomato,
          onPrimary: Colors.white,
          secondary: _freshHerb,
          onSecondary: Colors.white,
          surface: isDark ? _darkSurface : _surfaceWhite,
          onSurface: isDark ? _darkText : _textDark,
          surfaceContainer: isDark ? _darkBackground : _pageBackground,
          surfaceContainerHigh: isDark ? _darkSurface : _surfaceWhite,
          surfaceContainerHighest: isDark
              ? const Color(0xFF2A3028)
              : const Color(0xFFE4E6EB),
          onSurfaceVariant: isDark ? _darkMutedText : _mutedText,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? _darkBackground : _pageBackground,
      canvasColor: isDark ? _darkBackground : _pageBackground,
      textTheme: (isDark ? ThemeData.dark() : ThemeData.light()).textTheme
          .apply(
            fontFamily: 'Avenir Next',
            bodyColor: isDark ? _darkText : _textDark,
            displayColor: isDark ? _darkText : _textDark,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? _darkSurface : _surfaceWhite,
        foregroundColor: _brandTomato,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: _brandTomato,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? _darkSurface : _surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF232820) : _surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _brandTomato, width: 1.3),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: isDark ? _darkNav : _navWarm,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        indicatorColor: isDark
            ? _freshHerb.withValues(alpha: 0.28)
            : _navIndicator,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            color: isSelected
                ? _brandTomato
                : isDark
                ? _darkMutedText
                : _mutedText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected
                ? _brandTomato
                : isDark
                ? _darkMutedText
                : _mutedText,
            size: isSelected ? 27 : 25,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? _darkNav : _navWarm,
        selectedItemColor: _brandTomato,
        unselectedItemColor: isDark ? _darkMutedText : _mutedText,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
