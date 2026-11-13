import 'package:flutter/material.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../auth_error_helpers.dart';
import '../widgets/auth_inline_error.dart';
import '../widgets/auth_page_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authDataSource = AuthRemoteDataSource();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, String> _serverErrors = const <String, String>{};

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _serverErrors = const <String, String>{};
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authDataSource.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result.success && result.token != null) {
      await TokenStorage.saveToken(result.token!);
      if (result.user != null) {
        await TokenStorage.saveUser(result.user!.toJson());
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(user: result.user),
        ),
      );
      return;
    }

    final fieldErrors = parseAuthFieldErrors(result.errors);
    setState(() {
      _isLoading = false;
      _serverErrors = fieldErrors;
      _errorMessage = fieldErrors.isEmpty
          ? (result.message.isNotEmpty
              ? result.message
              : 'Login gagal. Periksa kembali email dan password Anda.')
          : null;
    });
    _formKey.currentState?.validate();
  }

  void _clearServerError(String field) {
    if (!_serverErrors.containsKey(field) && _errorMessage == null) return;
    setState(() {
      _serverErrors = Map<String, String>.from(_serverErrors)..remove(field);
      _errorMessage = null;
    });
  }

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      title: 'MainGa?',
      subtitle: 'Kelola koleksi, susun backlog, dan pantau diskon game '
          'impianmu dalam satu tempat.',
      children: [
        AutofillGroup(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'nama@email.com',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_isLoading,
                  onChanged: (_) => _clearServerError('email'),
                  validator: (val) {
                    final serverError = _serverErrors['email'];
                    if (serverError != null) return serverError;
                    if (val == null || val.trim().isEmpty) {
                      return 'Email wajib diisi';
                    }
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(val.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppPasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'masukkan password',
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  enabled: !_isLoading,
                  onChanged: (_) => _clearServerError('password'),
                  onFieldSubmitted: (_) => _handleLogin(),
                  validator: (val) {
                    final serverError = _serverErrors['password'];
                    if (serverError != null) return serverError;
                    if (val == null || val.isEmpty) {
                      return 'Password wajib diisi';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AuthInlineError(message: _errorMessage!),
                ],
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  text: 'Masuk ke MainGa?',
                  onPressed: _isLoading ? null : _handleLogin,
                  isLoading: _isLoading,
                  icon: Icons.login_rounded,
                  variant: AppButtonVariant.primary,
                  height: 54,
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildRegisterPrompt(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterPrompt() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Belum punya akun?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : _openRegister,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            textStyle: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textPrimary,
            ),
          ),
          child: const Text('Daftar Sekarang'),
        ),
      ],
    );
  }
}
