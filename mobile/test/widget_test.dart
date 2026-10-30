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
  });
}
