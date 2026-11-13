import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Tanda visual MainGa?: kotak lime dengan ikon gamepad hitam.
/// Elemen dekoratif, sehingga dibaca sebagai satu label merek oleh TalkBack.
class AuthBrandMark extends StatelessWidget {
  final double size;

  const AuthBrandMark({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MainGa?',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.controlLarge),
        ),
        child: Icon(
          Icons.sports_esports_rounded,
          size: size * 0.52,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}
