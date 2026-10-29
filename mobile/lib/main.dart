import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainGaApp());
}

class MainGaApp extends StatelessWidget {
  const MainGaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MainGa?',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
