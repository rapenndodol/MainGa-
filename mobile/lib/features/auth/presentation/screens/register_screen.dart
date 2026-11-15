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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authDataSource = AuthRemoteDataSource();

  static const Set<String> _knownFields = <String>{
    'nama',
    'email',
    'password',
    'password_confirmation',
  };

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, String> _serverErrors = const <String, String>{};

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _serverErrors = const <String, String>{};
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authDataSource.register(
      nama: _namaController.text.trim(),
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

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(user: result.user),
        ),
        (route) => false,
      );
      return;
    }

    final fieldErrors = parseAuthFieldErrors(result.errors);
    final extraErrors = fieldErrors.entries
        .where((entry) => !_knownFields.contains(entry.key))
        .map((entry) => entry.value)
        .where((value) => value.isNotEmpty)
        .join('\n');

    setState(() {
      _isLoading = false;
      _serverErrors = fieldErrors;
      if (extraErrors.isNotEmpty) {
        _errorMessage = extraErrors;
      } else if (fieldErrors.isEmpty) {
        _errorMessage = result.message.isNotEmpty
            ? result.message
            : 'Registrasi gagal. Silakan coba lagi.';
      } else {
        _errorMessage = null;
      }
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

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      title: 'Bergabung di MainGa?',
      subtitle: 'Mulai rapikan backlog dan incar diskon game favoritmu hari '
          'ini. Gratis, tanpa perlu akun toko.',
      onBack: () => Navigator.pop(context),
      children: [
        AutofillGroup(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _namaController,
                  label: 'Nama Lengkap',
                  hint: 'nama kamu',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  enabled: !_isLoading,
                  onChanged: (_) => _clearServerError('nama'),
                  validator: (val) {
                    final serverError = _serverErrors['nama'];
                    if (serverError != null) return serverError;
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama lengkap wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
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
                  hint: 'minimal 8 karakter',
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !_isLoading,
                  onChanged: (_) => _clearServerError('password'),
                  validator: (val) {
                    final serverError = _serverErrors['password'];
                    if (serverError != null) return serverError;
                    if (val == null || val.isEmpty) {
                      return 'Password wajib diisi';
                    }
                    if (val.length < 8) {
                      return 'Password minimal 8 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Konfirmasi Password',
                  hint: 'ulangi password',
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !_isLoading,
                  onChanged: (_) =>
                      _clearServerError('password_confirmation'),
                  onFieldSubmitted: (_) => _handleRegister(),
                  validator: (val) {
                    final serverError =
                        _serverErrors['password_confirmation'];
                    if (serverError != null) return serverError;
                    if (val == null || val.isEmpty) {
                      return 'Konfirmasi password wajib diisi';
                    }
                    if (val != _passwordController.text) {
                      return 'Konfirmasi password tidak cocok';
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
                  text: 'Daftar Sekarang',
                  onPressed: _isLoading ? null : _handleRegister,
                  isLoading: _isLoading,
                  icon: Icons.person_add_rounded,
                  variant: AppButtonVariant.primary,
                  height: 54,
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildLoginPrompt(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Sudah punya akun?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
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
          child: const Text('Masuk di sini'),
        ),
      ],
    );
  }
}
