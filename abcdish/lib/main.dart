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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ABCDish',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
      ),
      home: const SplashScreen(child: TabsScreen()),
    );
  }
}
