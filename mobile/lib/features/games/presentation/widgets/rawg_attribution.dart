import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';

class RawgAttribution extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const RawgAttribution({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  Future<void> _launchRawg() async {
    final uri = Uri.parse('https://rawg.io');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _launchRawg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Data by ',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  'RAWG.io',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryAccent,
                    decoration: TextDecoration.underline,
                    decorationColor: AppTheme.primaryAccent.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 12,
                  color: AppTheme.primaryAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
