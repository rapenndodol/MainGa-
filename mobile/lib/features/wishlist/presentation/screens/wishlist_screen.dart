import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_empty_state.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Wishlist Incaran',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: const SafeArea(
        child: AppEmptyState(
          icon: Icons.favorite_rounded,
          title: 'Belum ada game',
          description:
              'Daftar game incaran dengan target harga akan muncul di sini. Buka tab Jelajah untuk mulai mencari game yang ingin dipantau.',
        ),
      ),
    );
  }
}
