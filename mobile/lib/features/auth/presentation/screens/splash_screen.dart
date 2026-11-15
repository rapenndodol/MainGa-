import 'package:flutter/material.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/user_model.dart';
import '../widgets/auth_brand_mark.dart';
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
    // Jeda visual splash
    await Future.delayed(const Duration(milliseconds: 600));

    final token = await TokenStorage.getToken();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      final userMap = await TokenStorage.getUser();
      UserModel? user;
      if (userMap != null) {
        user = UserModel.fromJson(userMap);
      }

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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const AuthBrandMark(size: 52),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'MainGa?',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 44,
                  height: 1.0,
                  letterSpacing: -1.8,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'KOLEKSI  •  BACKLOG  •  HARGA',
                style: AppTypography.overline.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.8,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 96,
                height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: const LinearProgressIndicator(
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Menyiapkan katalog game kamu',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
