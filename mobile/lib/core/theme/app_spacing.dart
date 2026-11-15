import 'package:flutter/material.dart';

/// Skala jarak, padding, dan margin terpusat untuk MainGa?.
/// Ritme dasar 4/8/12/16/20/28/36 dengan tambahan token semantik
/// agar layar tidak memakai angka ajaib.
class AppSpacing {
  AppSpacing._();

  // ── Skala dasar ──────────────────────────────────────────────
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double huge = 36.0;

  // ── Jarak semantik ───────────────────────────────────────────
  /// Jarak antar section besar di dalam satu layar.
  static const double section = 32.0;

  /// Padding horizontal standar layar.
  static const double screen = xl;

  /// Ruang bawah agar konten tidak tertutup floating navigation dock.
  static const double bottomDock = 108.0;

  // ── Insets umum ──────────────────────────────────────────────
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);
  static const EdgeInsets allXxl = EdgeInsets.all(xxl);

  static const EdgeInsets hSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets hMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets hLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets hXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets vSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets vMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets vLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets vXl = EdgeInsets.symmetric(vertical: xl);

  // ── Padding semantik ─────────────────────────────────────────
  /// Padding dalam kartu konten.
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// Padding untuk baris list yang padat.
  static const EdgeInsets listPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  // ── Screen Padding standar ───────────────────────────────────
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Padding layar yang lebih lapang untuk form dan halaman detail.
  static const EdgeInsets screenPaddingWide = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  // ── Gap siap pakai ───────────────────────────────────────────
  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);
  static const SizedBox gapSection = SizedBox(height: section);
}
