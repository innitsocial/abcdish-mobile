import 'package:abcdish/core/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/screens/splash.dart';
import 'package:abcdish/screens/tabs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppErrorHandler.initialize();

  runApp(const ProviderScope(child: ABCDishApp()));
}

class ABCDishApp extends StatelessWidget {
  const ABCDishApp({super.key});

  static const _brandTomato = Color(0xFFE94335);
  static const _freshHerb = Color(0xFF2E7D32);
  static const _pageBackground = Color(0xFFF4F5F7);
  static const _surfaceWhite = Color(0xFFFFFFFF);
  static const _textDark = Color(0xFF050505);
  static const _mutedText = Color(0xFF65676B);

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _brandTomato,
          brightness: Brightness.light,
        ).copyWith(
          primary: _brandTomato,
          onPrimary: Colors.white,
          secondary: _freshHerb,
          onSecondary: Colors.white,
          surface: _surfaceWhite,
          onSurface: _textDark,
          surfaceContainer: _pageBackground,
          surfaceContainerHigh: _surfaceWhite,
          surfaceContainerHighest: const Color(0xFFE4E6EB),
          onSurfaceVariant: _mutedText,
        );

    return MaterialApp(
      title: 'ABCDish',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _pageBackground,
        canvasColor: _pageBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: _surfaceWhite,
          foregroundColor: _brandTomato,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: _brandTomato,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: _surfaceWhite,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceWhite,
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
          backgroundColor: _surfaceWhite,
          indicatorColor: _brandTomato.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              color: isSelected ? _brandTomato : _mutedText,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return IconThemeData(color: isSelected ? _brandTomato : _mutedText);
          }),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _surfaceWhite,
          selectedItemColor: _brandTomato,
          unselectedItemColor: _mutedText,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const SplashScreen(child: TabsScreen()),
    );
  }
}
