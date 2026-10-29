import 'package:flutter/material.dart';

class LibraryStatusHelper {
  LibraryStatusHelper._();

  static const List<String> statuses = [
    'Wishlist',
    'Backlog',
    'Sedang Dimainkan',
    'Tamat',
    'Dropped',
  ];

  static Color getStatusColor(String status) {
    switch (status) {
      case 'Wishlist':
        return const Color(0xFF06B6D4); // Cyan
      case 'Backlog':
        return const Color(0xFF818CF8); // Indigo
      case 'Sedang Dimainkan':
        return const Color(0xFFF59E0B); // Amber / Gold
      case 'Tamat':
        return const Color(0xFF10B981); // Emerald Green
      case 'Dropped':
        return const Color(0xFFF43F5E); // Rose / Red
      default:
        return const Color(0xFF9CA3AF); // Muted
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'Wishlist':
        return Icons.favorite_border_rounded;
      case 'Backlog':
        return Icons.inventory_2_outlined;
      case 'Sedang Dimainkan':
        return Icons.play_circle_outline_rounded;
      case 'Tamat':
        return Icons.check_circle_outline_rounded;
      case 'Dropped':
        return Icons.remove_circle_outline_rounded;
      default:
        return Icons.bookmark_outline_rounded;
    }
  }
}

class LibraryStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const LibraryStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = LibraryStatusHelper.getStatusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LibraryStatusHelper.getStatusIcon(status),
            size: compact ? 12 : 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
