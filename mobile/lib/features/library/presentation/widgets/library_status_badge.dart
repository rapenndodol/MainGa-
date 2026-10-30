import 'package:flutter/material.dart';
import '../../../../core/widgets/app_status_chip.dart';

/// Helper mapping status game koleksi yang selaras dengan AppColors baru.
class LibraryStatusHelper {
  LibraryStatusHelper._();

  static const List<String> statuses = AppStatusHelper.statuses;

  static Color getStatusColor(String status) =>
      AppStatusHelper.getStatusColor(status);

  static IconData getStatusIcon(String status) =>
      AppStatusHelper.getStatusIcon(status);
}

/// Badge status library yang mendelegasikan ke AppStatusChip terpusat.
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
    return AppStatusChip(
      status: status,
      compact: compact,
    );
  }
}
