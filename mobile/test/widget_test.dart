import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/models/auth_response_model.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/features/games/data/models/game_model.dart';
import 'package:mobile/features/games/data/models/games_response_model.dart';
import 'package:mobile/features/games/data/models/genre_model.dart';
import 'package:mobile/features/games/data/models/platform_model.dart';
import 'package:mobile/features/games/presentation/widgets/rawg_attribution.dart';
import 'package:mobile/features/home/presentation/screens/home_screen.dart';
import 'package:mobile/features/library/data/models/library_entry_model.dart';
import 'package:mobile/features/library/data/models/library_response_model.dart';
import 'package:mobile/features/library/presentation/screens/library_screen.dart';
import 'package:mobile/features/library/presentation/widgets/library_game_card.dart';
import 'package:mobile/features/library/presentation/widgets/library_status_badge.dart';
import 'package:mobile/features/wishlist/presentation/screens/wishlist_screen.dart';
import 'package:mobile/features/wishlist/data/models/wishlist_item_model.dart';
import 'package:mobile/features/wishlist/data/models/wishlist_response_model.dart';
import 'package:mobile/features/wishlist/data/models/game_price_model.dart';
import 'package:mobile/features/wishlist/presentation/widgets/wishlist_game_card.dart';
import 'package:mobile/features/notifications/data/models/notification_model.dart';
import 'package:mobile/features/notifications/data/models/notifications_response_model.dart';
import 'package:mobile/features/notifications/presentation/controllers/notification_notifier.dart';
import 'package:mobile/features/notifications/presentation/widgets/notification_card.dart';
import 'package:mobile/features/stats/data/models/user_stats_model.dart';
import 'package:mobile/features/stats/presentation/widgets/summary_stats_row.dart';
import 'package:mobile/features/stats/presentation/widgets/monthly_completed_chart.dart';
import 'package:mobile/features/stats/presentation/widgets/favorite_genres_chart.dart';
import 'package:mobile/features/library/presentation/widgets/random_game_sheet.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:mobile/core/widgets/app_badge.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_empty_state.dart';
import 'package:mobile/core/widgets/app_error_state.dart';
import 'package:mobile/main.dart';

class TestWrapper extends StatelessWidget {
  final Widget child;

  const TestWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: child,
    );
  }
}

void main() {
  group('Model Serialization Tests', () {
    test('UserModel.fromJson parses attributes correctly', () {
      final json = {
        'id': 1,
        'nama': 'Dimas Gamer',
        'email': 'dimas@example.com',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.nama, 'Dimas Gamer');
      expect(user.email, 'dimas@example.com');
      expect(user.toJson(), json);
    });

    test('AuthResponseModel.fromJson parses success response correctly', () {
      final json = {
        'success': true,
        'message': 'Login berhasil',
        'data': {
          'user': {
            'id': 10,
            'nama': 'Tester',
            'email': 'tester@mainga.com',
          },
          'token': 'sanctum_mock_token_123',
        },
      };

      final response = AuthResponseModel.fromJson(json);

      expect(response.success, true);
      expect(response.message, 'Login berhasil');
      expect(response.token, 'sanctum_mock_token_123');
      expect(response.user, isNotNull);
      expect(response.user!.nama, 'Tester');
    });

    test('AuthResponseModel.fromJson parses error response correctly', () {
      final json = {
        'success': false,
        'message': 'Validasi gagal',
        'errors': {
          'email': ['Email sudah terdaftar.'],
        },
      };

      final response = AuthResponseModel.fromJson(json);

      expect(response.success, false);
      expect(response.message, 'Validasi gagal');
      expect(response.errors, isNotNull);
      expect(response.errors!['email'], isA<List>());
    });

    test('GenreModel.fromJson parses attributes correctly', () {
      final json = {
        'id': 4,
        'nama': 'Action',
        'rawg_id': 4,
      };

      final genre = GenreModel.fromJson(json);

      expect(genre.id, 4);
      expect(genre.nama, 'Action');
      expect(genre.rawgId, 4);
    });

    test('PlatformModel.fromJson parses attributes correctly', () {
      final json = {
        'id': 1,
        'nama': 'PC',
        'rawg_id': 4,
      };

      final platform = PlatformModel.fromJson(json);

      expect(platform.id, 1);
      expect(platform.nama, 'PC');
      expect(platform.rawgId, 4);
    });

    test('GameModel.fromJson parses attributes correctly', () {
      final json = {
        'id': 100,
        'rawg_id': 3498,
        'judul': 'Grand Theft Auto V',
        'cover_url': 'https://media.rawg.io/games/gta5.jpg',
        'rating': 4.47,
        'genre': 'Action, Adventure',
        'genres': ['Action', 'Adventure'],
        'platform': 'PC, PlayStation 5',
        'platforms': ['PC', 'PlayStation 5'],
        'tanggal_rilis': '2013-09-17',
        'deskripsi': 'An action-adventure game developed by Rockstar Games.',
        'library_status': 'Sedang Dimainkan',
      };

      final game = GameModel.fromJson(json);

      expect(game.id, 100);
      expect(game.rawgId, 3498);
      expect(game.judul, 'Grand Theft Auto V');
      expect(game.coverUrl, 'https://media.rawg.io/games/gta5.jpg');
      expect(game.rating, 4.47);
      expect(game.genres.length, 2);
      expect(game.platforms.length, 2);
      expect(game.deskripsi, contains('Rockstar Games'));
      expect(game.libraryStatus, 'Sedang Dimainkan');
    });

    test('GamesResponseModel.fromJson parses pagination and games list', () {
      final json = {
        'success': true,
        'message': 'Daftar game berhasil diambil',
        'data': {
          'games': [
            {
              'id': 1,
              'rawg_id': 3498,
              'judul': 'Grand Theft Auto V',
              'cover_url': 'https://media.rawg.io/games/gta5.jpg',
              'rating': 4.47,
              'genre': 'Action',
              'genres': ['Action'],
              'platform': 'PC',
              'platforms': ['PC'],
              'tanggal_rilis': '2013-09-17',
            }
          ],
          'pagination': {
            'current_page': 1,
            'last_page': 5,
            'per_page': 20,
            'total': 100,
          }
        }
      };

      final response = GamesResponseModel.fromJson(json);

      expect(response.success, true);
      expect(response.games.length, 1);
      expect(response.games.first.judul, 'Grand Theft Auto V');
      expect(response.currentPage, 1);
      expect(response.lastPage, 5);
      expect(response.total, 100);
    });

    // ── Tahap 3 Tests: Library Serialization ──────────────────
    test('LibraryEntryModel.fromJson parses attributes correctly', () {
      final json = {
        'id': 5,
        'user_id': 1,
        'game_id': 10,
        'status': 'Sedang Dimainkan',
        'rating_pribadi': 9,
        'jam_main': 35.5,
        'catatan': 'Game favorit sepanjang masa.',
        'tanggal_tamat': null,
        'judul': 'The Witcher 3',
        'cover_url': 'https://media.rawg.io/witcher3.jpg',
        'game_rating': 4.7,
        'genre': 'RPG',
        'platform': 'PC',
      };

      final entry = LibraryEntryModel.fromJson(json);

      expect(entry.id, 5);
      expect(entry.userId, 1);
      expect(entry.gameId, 10);
      expect(entry.status, 'Sedang Dimainkan');
      expect(entry.ratingPribadi, 9);
      expect(entry.jamMain, 35.5);
      expect(entry.catatan, 'Game favorit sepanjang masa.');
      expect(entry.tanggalTamat, isNull);
      expect(entry.judul, 'The Witcher 3');
      expect(entry.coverUrl, 'https://media.rawg.io/witcher3.jpg');
      expect(entry.gameRating, 4.7);
      expect(entry.genre, 'RPG');
      expect(entry.platform, 'PC');
    });

    test('LibraryResponseModel.fromJson parses pagination and entry list', () {
      final json = {
        'success': true,
        'message': 'Daftar library berhasil diambil',
        'data': {
          'entries': [
            {
              'id': 1,
              'user_id': 1,
              'game_id': 20,
              'status': 'Tamat',
              'rating_pribadi': 10,
              'jam_main': 80.0,
              'catatan': 'Endingnya spektakuler!',
              'tanggal_tamat': '2026-10-29',
              'judul': 'Portal 2',
              'cover_url': 'https://media.rawg.io/portal2.jpg',
              'game_rating': 4.6,
              'genre': 'Puzzle',
              'platform': 'PC',
            }
          ],
          'pagination': {
            'current_page': 1,
            'last_page': 2,
            'per_page': 15,
            'total': 18,
          }
        }
      };

      final response = LibraryResponseModel.fromJson(json);

      expect(response.success, true);
      expect(response.entries.length, 1);
      expect(response.entries.first.judul, 'Portal 2');
      expect(response.entries.first.status, 'Tamat');
      expect(response.entries.first.tanggalTamat, '2026-10-29');
      expect(response.currentPage, 1);
      expect(response.lastPage, 2);
      expect(response.perPage, 15);
      expect(response.total, 18);
    });

    // ── Wishlist & Pelacak Harga (US-04 & US-05) Tests ─────────
    test('WishlistItemModel.fromJson parses attributes and target reached calculation correctly', () {
      final json = {
        'id': 10,
        'user_id': 1,
        'game_id': 5,
        'harga_target': 20.0,
        'harga_target_idr_estimasi': 320000,
        'aktif': true,
        'harga_tersedia': true,
        'harga_terendah': 14.99,
        'harga_terendah_idr_estimasi': 239840,
        'toko_termurah': 'Steam',
        'diskon_persen': 50.0,
        'selisih_harga_target': -5.01,
        'selisih_harga_target_idr_estimasi': -80160,
        'kurs_usd_ke_idr_estimasi': 16000.0,
        'dicek_terakhir': '2026-10-30T10:00:00Z',
        'game': {
          'id': 5,
          'rawg_id': 3498,
          'judul': 'Grand Theft Auto V',
          'cover_url': 'https://media.rawg.io/games/gta5.jpg',
          'rating': 4.5,
          'genre': 'Action',
          'genres': ['Action'],
          'platform': 'PC',
          'platforms': ['PC'],
        },
      };

      final item = WishlistItemModel.fromJson(json);

      expect(item.id, 10);
      expect(item.gameId, 5);
      expect(item.hargaTarget, 20.0);
      expect(item.hargaTerendah, 14.99);
      expect(item.tokoTermurah, 'Steam');
      expect(item.diskonPersen, 50.0);
      expect(item.isTargetReached, true);
      expect(item.judul, 'Grand Theft Auto V');
      expect(item.coverUrl, 'https://media.rawg.io/games/gta5.jpg');
    });

    test('WishlistResponseModel.fromJson parses wishlists and pagination correctly', () {
      final json = {
        'success': true,
        'message': 'Daftar wishlist berhasil diambil',
        'data': {
          'wishlists': [
            {
              'id': 1,
              'user_id': 1,
              'game_id': 10,
              'harga_target': 30.0,
              'harga_target_idr_estimasi': 480000,
              'aktif': true,
              'harga_tersedia': false,
              'harga_terendah': null,
              'toko_termurah': null,
              'game': {
                'id': 10,
                'rawg_id': 1234,
                'judul': 'Cyberpunk 2077',
              },
            }
          ],
          'pagination': {
            'current_page': 1,
            'last_page': 1,
            'per_page': 20,
            'total': 1,
          }
        }
      };

      final res = WishlistResponseModel.fromJson(json);

      expect(res.success, true);
      expect(res.wishlists.length, 1);
      expect(res.wishlists.first.judul, 'Cyberpunk 2077');
      expect(res.wishlists.first.isTargetReached, false);
      expect(res.currentPage, 1);
      expect(res.total, 1);
    });

    test('GamePricesResponseModel.fromJson parses store prices and history correctly', () {
      final json = {
        'success': true,
        'message': 'Data harga game berhasil diambil',
        'data': {
          'harga_tersedia': true,
          'status_keterangan': 'Harga tersedia',
          'harga_terendah': 19.99,
          'harga_terendah_idr_estimasi': 319840,
          'toko_termurah': 'Epic Games Store',
          'kurs_usd_ke_idr_estimasi': 16000.0,
          'harga_terkini': [
            {
              'id': 1,
              'toko': 'Epic Games Store',
              'harga': 19.99,
              'harga_idr_estimasi': 319840,
              'diskon_persen': 40.0,
              'dicek_pada': '2026-10-30T10:00:00Z',
            },
            {
              'id': 2,
              'toko': 'Steam',
              'harga': 24.99,
              'harga_idr_estimasi': 399840,
              'diskon_persen': 25.0,
              'dicek_pada': '2026-10-30T10:00:00Z',
            }
          ],
          'riwayat_harga': [
            {
              'id': 101,
              'toko': 'Steam',
              'harga': 39.99,
              'harga_idr_estimasi': 639840,
              'diskon_persen': 0.0,
              'dicek_pada': '2026-10-01T10:00:00Z',
            },
            {
              'id': 102,
              'toko': 'Epic Games Store',
              'harga': 19.99,
              'harga_idr_estimasi': 319840,
              'diskon_persen': 40.0,
              'dicek_pada': '2026-10-15T10:00:00Z',
            }
          ]
        }
      };

      final res = GamePricesResponseModel.fromJson(json);

      expect(res.success, true);
      expect(res.hargaTersedia, true);
      expect(res.tokoTermurah, 'Epic Games Store');
      expect(res.hargaTerendah, 19.99);
      expect(res.hargaTerkini.length, 2);
      expect(res.riwayatHarga.length, 2);
      expect(res.hargaTerkini.first.toko, 'Epic Games Store');
      expect(res.hargaTerkini.first.diskonPersen, 40.0);
    });

    test('NotificationModel.fromJson parses unread notification correctly', () {
      final json = {
        'id': 1,
        'user_id': 5,
        'game_id': 10,
        'judul': 'Diskon The Witcher 3',
        'judul_game': 'The Witcher 3: Wild Hunt',
        'pesan': 'Harga turun mencapai target di Steam!',
        'harga': 14.99,
        'toko': 'Steam',
        'dibaca_pada': null,
        'sudah_dibaca': false,
        'status_dibaca': 'belum_dibaca',
        'waktu': '2026-11-05T10:00:00Z',
        'created_at': '2026-11-05T10:00:00Z',
        'game': {
          'id': 10,
          'judul': 'The Witcher 3: Wild Hunt',
          'cover_url': 'https://media.rawg.io/witcher3.jpg',
        },
      };

      final notification = NotificationModel.fromJson(json);

      expect(notification.id, 1);
      expect(notification.userId, 5);
      expect(notification.gameId, 10);
      expect(notification.judulGame, 'The Witcher 3: Wild Hunt');
      expect(notification.pesan, 'Harga turun mencapai target di Steam!');
      expect(notification.harga, 14.99);
      expect(notification.toko, 'Steam');
      expect(notification.sudahDibaca, false);
      expect(notification.game?.coverUrl, 'https://media.rawg.io/witcher3.jpg');
    });

    test('NotificationsResponseModel.fromJson parses list and pagination correctly', () {
      final json = {
        'success': true,
        'message': 'Daftar notifikasi berhasil diambil',
        'data': {
          'notifications': [
            {
              'id': 1,
              'user_id': 5,
              'game_id': 10,
              'judul': 'Game Diskon',
              'judul_game': 'Hades',
              'pesan': 'Hades mencapai target harga di Epic Games Store',
              'harga': 9.99,
              'toko': 'Epic Games Store',
              'dibaca_pada': '2026-11-05T12:00:00Z',
              'sudah_dibaca': true,
              'status_dibaca': 'dibaca',
            }
          ],
          'pagination': {
            'current_page': 1,
            'last_page': 1,
            'per_page': 15,
            'total': 1,
          }
        }
      };

      final res = NotificationsResponseModel.fromJson(json);

      expect(res.success, true);
      expect(res.notifications.length, 1);
      expect(res.notifications.first.judulGame, 'Hades');
      expect(res.notifications.first.sudahDibaca, true);
      expect(res.total, 1);
    });

    test('UserStatsModel.fromJson parses statistics, months, and genres correctly', () {
      final json = {
        'total_game': 15,
        'total_jam': 120.5,
        'jumlah_tamat': 5,
        'game_tamat_per_bulan': [
          {
            'periode': '2026-11',
            'label': 'Nov 2026',
            'bulan': 'Nov 2026',
            'jumlah': 2,
          },
          {
            'periode': '2026-10',
            'label': 'Oct 2026',
            'bulan': 'Oct 2026',
            'jumlah': 3,
          }
        ],
        'genre_favorit': [
          {'nama': 'RPG', 'genre': 'RPG', 'jumlah': 7},
          {'nama': 'Action', 'genre': 'Action', 'jumlah': 5},
        ]
      };

      final stats = UserStatsModel.fromJson(json);

      expect(stats.totalGame, 15);
      expect(stats.totalJam, 120.5);
      expect(stats.jumlahTamat, 5);
      expect(stats.gameTamatPerBulan.length, 2);
      expect(stats.gameTamatPerBulan.first.shortMonth, 'Nov');
      expect(stats.genreFavorit.length, 2);
      expect(stats.genreFavorit.first.nama, 'RPG');
      expect(stats.isEmpty, false);
      expect(stats.hasCompletedGames, true);
      expect(stats.hasFavoriteGenres, true);
    });

    test('UserStatsModel.empty returns clean empty state', () {
      const stats = UserStatsModel.empty;
      expect(stats.totalGame, 0);
      expect(stats.totalJam, 0.0);
      expect(stats.jumlahTamat, 0);
      expect(stats.isEmpty, true);
      expect(stats.gameTamatPerBulan, isEmpty);
      expect(stats.genreFavorit, isEmpty);
    });
  });

  group('Widget Tests', () {
    testWidgets('MainGaApp builds successfully', (WidgetTester tester) async {
      await tester.pumpWidget(const MainGaApp());
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(find.byType(MainGaApp), findsOneWidget);
    });

    testWidgets('LoginScreen displays required form fields and buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: LoginScreen()),
      );

      // Verify header and texts
      expect(find.text('MainGa?'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Masuk ke MainGa?'), findsOneWidget);
      expect(find.text('Daftar Sekarang'), findsOneWidget);
    });

    testWidgets('RawgAttribution renders attribution text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: Scaffold(body: RawgAttribution())),
      );

      expect(find.text('Data by '), findsOneWidget);
      expect(find.text('RAWG.io'), findsOneWidget);
    });

    testWidgets('HomeScreen displays floating navigation bar with 4 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWrapper(
          child: HomeScreen(
            user: UserModel(id: 1, nama: 'Dimas', email: 'dimas@example.com'),
          ),
        ),
      );

      expect(find.text('Jelajah'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Wishlist'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('LibraryScreen displays informative empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: LibraryScreen()),
      );

      expect(find.text('Library Koleksi'), findsOneWidget);
      expect(find.text('Belum ada game'), findsOneWidget);
    });

    testWidgets('WishlistScreen displays informative empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWrapper(child: WishlistScreen()),
      );

      expect(find.text('Wishlist Incaran'), findsOneWidget);
      expect(find.text('Belum ada game di wishlist'), findsOneWidget);
    });

    // ── Tahap 3 Widget Tests: Badge & Card ────────────────────
    testWidgets('LibraryStatusBadge renders status badge correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWrapper(
          child: Scaffold(
            body: Column(
              children: [
                LibraryStatusBadge(status: 'Wishlist'),
                LibraryStatusBadge(status: 'Backlog'),
                LibraryStatusBadge(status: 'Sedang Dimainkan'),
                LibraryStatusBadge(status: 'Tamat'),
                LibraryStatusBadge(status: 'Dropped'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Wishlist'), findsOneWidget);
      expect(find.text('Backlog'), findsOneWidget);
      expect(find.text('Sedang Dimainkan'), findsOneWidget);
      expect(find.text('Tamat'), findsOneWidget);
      expect(find.text('Dropped'), findsOneWidget);
    });

    testWidgets('LibraryGameCard renders card elements correctly', (WidgetTester tester) async {
      const entry = LibraryEntryModel(
        id: 1,
        userId: 1,
        gameId: 10,
        status: 'Sedang Dimainkan',
        ratingPribadi: 9,
        jamMain: 42.5,
        catatan: 'Gameplay sangat seru.',
        judul: 'Cyberpunk 2077',
        gameRating: 4.5,
        genre: 'Action, RPG',
        platform: 'PC',
      );

      await tester.pumpWidget(
        const TestWrapper(
          child: Scaffold(
            body: LibraryGameCard(entry: entry),
          ),
        ),
      );

      expect(find.text('Cyberpunk 2077'), findsOneWidget);
      expect(find.text('Sedang Dimainkan'), findsOneWidget);
      expect(find.text('9/10'), findsOneWidget);
      expect(find.text('42.5 jam'), findsOneWidget);
      expect(find.text('"Gameplay sangat seru."'), findsOneWidget);
    });

    // ── Design System Shared Widgets Tests ────────────────────
    testWidgets('AppButton renders text and responds to tap', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: AppButton(
              text: 'Mulai Bermain',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Mulai Bermain'), findsOneWidget);
      await tester.tap(find.text('Mulai Bermain'));
      expect(tapped, true);
    });

    testWidgets('AppEmptyState renders icon, title, and optional action', (WidgetTester tester) async {
      bool actionClicked = false;
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: AppEmptyState(
              icon: Icons.gamepad_rounded,
              title: 'Koleksi Kosong',
              description: 'Kamu belum menambahkan game apa pun.',
              actionText: 'Jelajah Sekarang',
              onAction: () => actionClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Koleksi Kosong'), findsOneWidget);
      expect(find.text('Kamu belum menambahkan game apa pun.'), findsOneWidget);
      expect(find.text('Jelajah Sekarang'), findsOneWidget);

      await tester.tap(find.text('Jelajah Sekarang'));
      expect(actionClicked, true);
    });

    testWidgets('AppErrorState renders error message and retry button', (WidgetTester tester) async {
      bool retried = false;
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: AppErrorState(
              message: 'Gagal terhubung ke server',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Terjadi Kendala'), findsOneWidget);
      expect(find.text('Gagal terhubung ke server'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      await tester.tap(find.text('Coba Lagi'));
      expect(retried, true);
    });

    testWidgets('AppBadge.rating renders rating score with star icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: AppBadge.rating(4.8),
          ),
        ),
      );

      expect(find.text('4.8'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    // ── US-04 & US-05: WishlistGameCard Widget Test ────────────
    testWidgets('WishlistGameCard renders card elements and target reached status correctly', (WidgetTester tester) async {
      bool tapped = false;
      bool toggled = false;
      bool deleted = false;

      final item = WishlistItemModel(
        id: 1,
        userId: 1,
        gameId: 10,
        hargaTarget: 25.0,
        hargaTargetIdrEstimasi: 400000,
        aktif: true,
        hargaTersedia: true,
        hargaTerendah: 19.99,
        hargaTerendahIdrEstimasi: 319840,
        tokoTermurah: 'Steam',
        diskonPersen: 50.0,
        selisihHargaTarget: -5.01,
        selisihHargaTargetIdrEstimasi: -80160,
        game: const GameModel(
          id: 10,
          rawgId: 100,
          judul: 'The Witcher 3',
          rating: 4.8,
          genre: 'RPG',
          genres: ['RPG'],
          platform: 'PC',
          platforms: ['PC'],
        ),
      );

      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: WishlistGameCard(
              item: item,
              onTap: () => tapped = true,
              onToggleActive: (_) => toggled = true,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      expect(find.text('The Witcher 3'), findsOneWidget);
      expect(find.text('Target: '), findsOneWidget);
      expect(find.text('\$25.00'), findsOneWidget);
      expect(find.text('Steam: '), findsOneWidget);
      expect(find.text('\$19.99'), findsOneWidget);
      expect(find.text('-50%'), findsOneWidget);
      expect(find.textContaining('Mencapai target!'), findsOneWidget);
      expect(find.text('Pantau aktif'), findsOneWidget);

      await tester.tap(find.text('The Witcher 3'));
      expect(tapped, true);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleted, true);

      await tester.tap(find.byType(Switch));
      expect(toggled, true);
    });

    // ── US-06: NotificationCard Widget Test ────────────────────
    testWidgets('NotificationCard renders notification details and unread indicator', (WidgetTester tester) async {
      bool tapped = false;

      const notification = NotificationModel(
        id: 1,
        userId: 1,
        gameId: 10,
        judul: 'Diskon Spesial',
        judulGame: 'Hollow Knight',
        pesan: 'Harga turun menjadi \$7.49 di Steam',
        harga: 7.49,
        toko: 'Steam',
        sudahDibaca: false,
        statusDibaca: 'belum_dibaca',
        waktu: '2026-11-05T09:00:00Z',
      );

      await tester.pumpWidget(
        TestWrapper(
          child: Scaffold(
            body: NotificationCard(
              notification: notification,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Hollow Knight'), findsOneWidget);
      expect(find.text('Harga turun menjadi \$7.49 di Steam'), findsOneWidget);
      expect(find.text('Steam'), findsOneWidget);
      expect(find.text('\$7.49'), findsOneWidget);

      await tester.tap(find.text('Hollow Knight'));
      expect(tapped, true);
    });

    // ── US-07: SummaryStatsRow Widget Test ─────────────────────
    testWidgets('SummaryStatsRow renders statistics values correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWrapper(
          child: Scaffold(
            body: SummaryStatsRow(
              totalGame: 12,
              totalJam: 45.5,
              jumlahTamat: 4,
            ),
          ),
        ),
      );

      expect(find.text('12'), findsOneWidget);
      expect(find.text('Total Game'), findsOneWidget);
      expect(find.text('45.5j'), findsOneWidget);
      expect(find.text('Jam Bermain'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Game Tamat'), findsOneWidget);
    });

    // ── US-07: MonthlyCompletedChart Widget Test ───────────────
    testWidgets('MonthlyCompletedChart renders title and bar chart container', (WidgetTester tester) async {
      const data = [
        MonthlyCompletedStats(
          periode: '2026-10',
          label: 'Oct 2026',
          bulan: 'Oct 2026',
          jumlah: 2,
        ),
        MonthlyCompletedStats(
          periode: '2026-11',
          label: 'Nov 2026',
          bulan: 'Nov 2026',
          jumlah: 1,
        ),
      ];

      await tester.pumpWidget(
        const TestWrapper(
          child: Scaffold(
            body: MonthlyCompletedChart(data: data),
          ),
        ),
      );

      expect(find.text('Game Tamat'), findsOneWidget);
      expect(find.text('12 Bulan Terakhir'), findsOneWidget);
    });

    // ── US-07: FavoriteGenresChart Widget Test ─────────────────
    testWidgets('FavoriteGenresChart renders genre breakdown and legend', (WidgetTester tester) async {
      const genres = [
        GenreStats(nama: 'Action', genre: 'Action', jumlah: 8),
        GenreStats(nama: 'RPG', genre: 'RPG', jumlah: 4),
      ];

      await tester.pumpWidget(
        const TestWrapper(
          child: Scaffold(
            body: FavoriteGenresChart(genres: genres),
          ),
        ),
      );

      expect(find.text('Genre Favorit'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('RPG'), findsOneWidget);
      expect(find.text('8 game (67%)'), findsOneWidget);
      expect(find.text('4 game (33%)'), findsOneWidget);
    });

    // ── US-08: RandomGameSheet Widget Test ──────────────────────
    testWidgets('RandomGameSheet renders chosen backlog game and action buttons', (WidgetTester tester) async {
      const entry = LibraryEntryModel(
        id: 99,
        userId: 1,
        gameId: 42,
        status: 'Backlog',
        jamMain: 0,
        judul: 'Celeste',
        coverUrl: 'https://media.rawg.io/celeste.jpg',
        gameRating: 4.9,
        genre: 'Platformer',
        platform: 'PC',
      );

      await tester.pumpWidget(
        const TestWrapper(
          child: Scaffold(
            body: RandomGameSheet(initialEntry: entry),
          ),
        ),
      );

      expect(find.text('Acak Game Backlog'), findsOneWidget);
      expect(find.text('Celeste'), findsOneWidget);
      expect(find.text('Platformer'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('Mainkan Sekarang'), findsOneWidget);
      expect(find.text('Acak Ulang'), findsOneWidget);
    });

    testWidgets('RandomGameSheet renders empty backlog message when backlog is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWrapper(
          child: Scaffold(
            body: RandomGameSheet(initialBacklogEmpty: true),
          ),
        ),
      );

      expect(find.text('Backlog Kosong'), findsOneWidget);
      expect(find.text('Backlog kosong. Tambahkan game dengan status Backlog dulu.'), findsOneWidget);
      expect(find.text('Mengerti'), findsOneWidget);
    });

    // ── US-06: NotificationNotifier State Management ────────────
    test('NotificationNotifier manages unread count state properly', () {
      final notifier = NotificationNotifier.instance;

      notifier.setUnreadCount(5);
      expect(notifier.unreadCount, 5);

      notifier.decrementUnreadCount(by: 2);
      expect(notifier.unreadCount, 3);

      notifier.decrementUnreadCount(by: 10);
      expect(notifier.unreadCount, 0);
    });

    // ── US-08: LibraryScreen renders Acak Button ────────────────
    testWidgets('LibraryScreen renders Acak button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWrapper(
          child: LibraryScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Acak'), findsOneWidget);
      expect(find.byIcon(Icons.casino_rounded), findsOneWidget);
    });

    // ── US-06 & US-07: ProfileScreen Notification Bell & Stats Widget Test ──
    testWidgets('ProfileScreen renders notification bell icon and stats section', (WidgetTester tester) async {
      await tester.pumpWidget(
        const TestWrapper(
          child: ProfileScreen(),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
      expect(find.text('Statistik Bermain'), findsOneWidget);
    });
  });
}
