import 'package:flutter/material.dart';
import '../../../../core/widgets/app_rawg_attribution.dart';

/// Atribusi resmi RAWG.io yang mendelegasikan ke AppRawgAttribution terpusat.
class RawgAttribution extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const RawgAttribution({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return AppRawgAttribution(padding: padding);
  }
}
