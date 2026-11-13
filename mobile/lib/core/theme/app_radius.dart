import 'package:flutter/material.dart';

/// Skala radius terpusat untuk konsistensi seluruh komponen MainGa?.
/// Nilai lama dipertahankan agar kontrak visual tidak berubah mendadak,
/// sementara alias semantik memudahkan pemakaian yang konsisten.
class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 14.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double full = 999.0;

  // ── Alias semantik ───────────────────────────────────────────
  /// Kontrol kecil: badge, chip, thumbnail mini.
  static const double control = sm;

  /// Kontrol utama: input, tombol kecil, kartu dalam.
  static const double controlLarge = md;

  /// Permukaan kartu dan panel.
  static const double card = lg;

  /// Modal, bottom sheet, dan dialog.
  static const double sheet = xl;

  /// Bentuk pill penuh.
  static const double pill = full;

  static const Radius rSm = Radius.circular(sm);
  static const Radius rMd = Radius.circular(md);
  static const Radius rLg = Radius.circular(lg);
  static const Radius rXl = Radius.circular(xl);
  static const Radius rFull = Radius.circular(full);

  static final BorderRadius smBorderRadius = BorderRadius.circular(sm);
  static final BorderRadius mdBorderRadius = BorderRadius.circular(md);
  static final BorderRadius lgBorderRadius = BorderRadius.circular(lg);
  static final BorderRadius xlBorderRadius = BorderRadius.circular(xl);
  static final BorderRadius fullBorderRadius = BorderRadius.circular(full);

  static final BorderRadius controlBorderRadius = BorderRadius.circular(control);
  static final BorderRadius controlLargeBorderRadius =
      BorderRadius.circular(controlLarge);
  static final BorderRadius cardBorderRadius = BorderRadius.circular(card);
  static final BorderRadius sheetBorderRadius = BorderRadius.circular(sheet);
  static final BorderRadius pillBorderRadius = BorderRadius.circular(pill);

  /// Radius atas untuk bottom sheet.
  static const BorderRadius sheetTopBorderRadius = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}
