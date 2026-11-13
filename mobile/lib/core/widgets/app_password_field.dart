import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_text_field.dart';

/// Field password dengan tombol tampil/sembunyikan yang punya label
/// aksesibilitas eksplisit dan target sentuh 48dp.
class AppPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction textInputAction;
  final bool enabled;
  final Iterable<String>? autofillHints;

  const AppPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction = TextInputAction.next,
    this.enabled = true,
    this.autofillHints,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  void _toggleVisibility() {
    setState(() => _obscure = !_obscure);
  }

  @override
  Widget build(BuildContext context) {
    final String semanticLabel =
        _obscure ? 'Tampilkan password' : 'Sembunyikan password';

    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscure,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      enabled: widget.enabled,
      autofillHints: widget.autofillHints,
      suffixIcon: Semantics(
        button: true,
        label: semanticLabel,
        onTap: _toggleVisibility,
        excludeSemantics: true,
        child: IconButton(
          onPressed: _toggleVisibility,
          tooltip: semanticLabel,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: AnimatedSwitcher(
            duration: AppMotion.fast,
            switchInCurve: AppMotion.curve,
            switchOutCurve: AppMotion.reverseCurve,
            child: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              key: ValueKey<bool>(_obscure),
              color: AppColors.textMuted,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
