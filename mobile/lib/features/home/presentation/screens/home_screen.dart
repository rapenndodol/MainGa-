import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../games/presentation/screens/explore_screen.dart';
import '../../../library/presentation/screens/library_screen.dart';
import '../../../notifications/presentation/controllers/notification_notifier.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../wishlist/presentation/screens/wishlist_screen.dart';
import '../widgets/floating_nav_bar.dart';

/// Screen utama yang menampung 4 tab dengan Floating Navigation Bar modern.
class HomeScreen extends StatefulWidget {
  final UserModel? user;
  final int initialIndex;

  const HomeScreen({
    super.key,
    this.user,
    this.initialIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Muat badge notifikasi saat aplikasi pertama dibuka
    NotificationNotifier.instance.fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const ExploreScreen(),
      const LibraryScreen(),
      const WishlistScreen(),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true, // Mendukung floating navigation dock di atas konten
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _currentIndex,
        onSelected: _selectTab,
      ),
    );
  }

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
    // Saat tab Profil ditampilkan, sinkronkan badge notifikasi
    if (index == 3) {
      NotificationNotifier.instance.fetchUnreadCount();
    }
  }
}
