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
import 'package:mobile/features/library/presentation/screens/library_screen.dart';
import 'package:mobile/features/wishlist/presentation/screens/wishlist_screen.dart';
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
      expect(find.text('Belum ada game'), findsOneWidget);
    });
  });
}
