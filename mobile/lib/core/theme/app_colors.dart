import 'package:flutter/material.dart';

/// Single source of truth untuk palet warna aplikasi MainGa?.
/// Mengikuti aturan 60-30-10:
/// - 60% Hitam (#0B0B0C): Latar belakang, permukaan, dialog, bottom sheet, app bar.
/// - 30% Putih (#FFFFFF): Teks, ikon, garis, tombol sekunder/outline, chip filter aktif.
/// - 10% Lime (#C6F432): Aksen CTA utama, tab navigasi aktif, sorotan, fokus input, grafik.
class AppColors {
  AppColors._();

  // ── Background & Surfaces (60% Hitam #0B0B0C & Netral Turunan) ──
  /// Latar belakang utama aplikasi
  static const Color bg = Color(0xFF0B0B0C);

  /// Permukaan kartu standar (tone step 1)
  static const Color surface = Color(0xFF141416);

  /// Permukaan kartu terangkat, modal sheet, floating bar (tone step 2)
  static const Color surfaceElevated = Color(0xFF1C1C1F);

  /// Permukaan sorotan kontainer
  static const Color surfaceHighlight = Color(0xFF26262B);

  /// Permukaan latar input field
  static const Color inputBackground = Color(0xFF141416);

  // ── Borders & Dividers ──────────────────────────────────────
  /// Garis batas netral untuk kartu, modal, input
  static const Color border = Color(0xFF2A2A2E);

  /// Garis batas saat input aktif / fokus (Lime Green)
  static const Color borderFocused = Color(0xFFC6F432);

  // ── Primary Accent (10% Lime Green #C6F432) ──────────────────
  /// Aksen primer untuk CTA utama, tab aktif, dan fokus
  static const Color primary = Color(0xFFC6F432);

  /// Kontainer aksen primer bernuansa gelap
  static const Color primaryContainer = Color(0xFF1F280D);

  /// Variasi aksen primer terang
  static const Color primaryLight = Color(0xFFD4F75A);

  /// Teks dan ikon di atas warna Lime SELALU hitam kontras tinggi (#0B0B0C)
  static const Color onPrimary = Color(0xFF0B0B0C);

  // ── Secondary Accent (30% Putih #FFFFFF) ────────────────────
  /// Warna kedua (30%) untuk teks, ikon, border, tombol outline, chip aktif
  static const Color secondary = Color(0xFFFFFFFF);

  /// Kontainer sekunder gelap terangkat
  static const Color secondaryContainer = Color(0xFF1C1C1F);

  /// Teks dan ikon di atas warna sekunder putih
  static const Color onSecondary = Color(0xFF0B0B0C);

  // ── Typography Colors ──────────────────────────────────────
  /// Teks utama: Putih 100% kontras tinggi
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Teks sekunder: Putih opacity 65% untuk subtitle & info
  static const Color textSecondary = Color(0xA6FFFFFF);

  /// Teks tersier / muted / disabled: Putih opacity 38%
  static const Color textMuted = Color(0x61FFFFFF);

  /// Teks nonaktif: Putih opacity 38%
  static const Color textDisabled = Color(0x61FFFFFF);

  // ── Universal Neutrals ─────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // ── Functional & Status Colors (Saturasi Diturunkan) ────────
  /// Bintang rating game (emas hangat desaturasi)
  static const Color ratingStar = Color(0xFFE5B842);

  /// Pesan error / status destructive
  static const Color error = Color(0xFFE05353);

  /// Pesan sukses fungsional
  static const Color success = Color(0xFF4DA87D);

  // ── Status Library Game (Pembeda Fungsional Desaturasi) ─────
  /// Sedang Dimainkan (Playing - muted coral)
  static const Color statusPlaying = Color(0xFFD9736C);

  /// Tamat (Completed - muted forest green)
  static const Color statusCompleted = Color(0xFF4DA87D);

  /// Backlog (muted stone beige)
  static const Color statusBacklog = Color(0xFFD1C7B7);

  /// Wishlist (muted warm amber)
  static const Color statusWishlist = Color(0xFFD9A55B);

  /// Dropped (muted slate gray)
  static const Color statusDropped = Color(0xFF8E8E93);

  // ── fl_chart Visual Tokens ─────────────────────────────────
  /// Batang game tamat per bulan: lime
  static const Color chartCompletedBar = Color(0xFFC6F432);

  /// Garis riwayat harga: lime
  static const Color chartPriceLine = Color(0xFFC6F432);

  /// Donut genre favorit irisan 1: lime
  static const Color chartDonutSlice1 = Color(0xFFC6F432);

  /// Donut genre favorit irisan 2: putih
  static const Color chartDonutSlice2 = Color(0xFFFFFFFF);

  /// Donut genre favorit irisan 3: abu netral 1
  static const Color chartDonutSlice3 = Color(0xFFA1A1A6);

  /// Donut genre favorit irisan 4: abu netral 2
  static const Color chartDonutSlice4 = Color(0xFF6B6B70);

  /// Donut genre favorit irisan 5: abu netral 3
  static const Color chartDonutSlice5 = Color(0xFF3A3A3F);
}
