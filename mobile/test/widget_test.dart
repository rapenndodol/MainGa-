import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/models/auth_response_model.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
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
  });
}
