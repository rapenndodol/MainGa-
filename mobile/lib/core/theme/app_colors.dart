import 'package:flutter/material.dart';

/// Single source of truth untuk palet warna aplikasi MainGa?.
/// Diturunkan dari analisis visual warm obsidian & coral terracotta.
class AppColors {
  AppColors._();

  // ── Background & Surfaces ───────────────────────────────────
  /// Latar belakang utama (deep warm obsidian black-cherry)
  static const Color bg = Color(0xFF140C0F);

  /// Permukaan kartu standar (warm tone step pertama)
  static const Color surface = Color(0xFF1E1216);

  /// Permukaan kartu terangkat, modal sheet, floating bar
  static const Color surfaceElevated = Color(0xFF29171E);

  /// Permukaan container sorotan / hover / selected
  static const Color surfaceHighlight = Color(0xFF3A1F28);

  /// Permukaan input field
  static const Color inputBackground = Color(0xFF1A1014);

  // ── Borders ────────────────────────────────────────────────
  /// Garis batas halus untuk kontur kartu & form
  static const Color border = Color(0xFF351D24);

  /// Garis batas ketika input aktif / fokus
  static const Color borderFocused = Color(0xFFE14B44);

  // ── Primary Accent (Coral Terracotta Crimson) ───────────────
  /// Aksen primer untuk tombol utama, indikator aktif, dan sorotan
  static const Color primary = Color(0xFFE14B44);

  /// Kontainer aksen primer dengan opacity/tone hangat
  static const Color primaryContainer = Color(0xFF3E1A20);

  /// Variasi warna aksen lebih terang untuk teks kontras di atas gelap
  static const Color primaryLight = Color(0xFFFF6B63);

  // ── Secondary Accent (Warm Peach / Butter Cream) ───────────
  /// Aksen sekunder untuk badge 'Popular', sorotan hangat, dan rating
  static const Color secondary = Color(0xFFF7D7BA);

  /// Kontainer aksen sekunder
  static const Color secondaryContainer = Color(0xFF33201D);

  // ── Typography Colors ──────────────────────────────────────
  /// Teks utama: kontras tinggi, off-white hangat
  static const Color textPrimary = Color(0xFFFFF5F5);

  /// Teks sekunder: warm ash mauve untuk subtitle & info
  static const Color textSecondary = Color(0xFFBBAAB0);

  /// Teks tersier / muted: keterangan waktu, placeholder, ikon non-aktif
  static const Color textMuted = Color(0xFF7D686F);

  // ── Functional & Status Colors ─────────────────────────────
  /// Bintang rating game
  static const Color ratingStar = Color(0xFFF6C15C);

  /// Pesan error / status destructive
  static const Color error = Color(0xFFEF4444);

  /// Pesan sukses
  static const Color success = Color(0xFF4EBA87);

  // ── Status Library Game ─────────────────────────────────────
  /// Sedang Dimainkan (Playing)
  static const Color statusPlaying = Color(0xFFE14B44);

  /// Tamat (Completed)
  static const Color statusCompleted = Color(0xFF4EBA87);

  /// Backlog
  static const Color statusBacklog = Color(0xFFF7D7BA);

  /// Wishlist
  static const Color statusWishlist = Color(0xFFE09F3E);

  /// Dropped (Ditinggalkan)
  static const Color statusDropped = Color(0xFF8E7C82);
}
