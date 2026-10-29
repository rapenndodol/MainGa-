import 'package:flutter/material.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/user_model.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authDataSource = AuthRemoteDataSource();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Beri sedikit jeda visual splash
    await Future.delayed(const Duration(milliseconds: 600));

    final token = await TokenStorage.getToken();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Coba verifikasi dengan user lokal atau fetch dari backend
      final userMap = await TokenStorage.getUser();
      UserModel? user;
      if (userMap != null) {
        user = UserModel.fromJson(userMap);
      }

      // Verifikasi token masih berlaku di backend secara asynchronous
      _authDataSource.getProfile(token).then((remoteUser) {
        if (remoteUser != null) {
          TokenStorage.saveUser(remoteUser.toJson());
        }
      }).catchError((_) {});

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
      );
    } else {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports_rounded,
              size: 64,
              color: AppTheme.primaryAccent,
            ),
            SizedBox(height: 16),
            Text(
              'MainGa?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
