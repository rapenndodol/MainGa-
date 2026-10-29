import 'user_model.dart';

class AuthResponseModel {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;
  final Map<String, dynamic>? errors;

  const AuthResponseModel({
    required this.success,
    required this.message,
    this.token,
    this.user,
    this.errors,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    UserModel? user;
    String? token;

    if (json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      if (data['token'] != null) {
        token = data['token'].toString();
      }
      if (data['user'] is Map<String, dynamic>) {
        user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
    }

    Map<String, dynamic>? errors;
    if (json['errors'] is Map<String, dynamic>) {
      errors = json['errors'] as Map<String, dynamic>;
    }

    return AuthResponseModel(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      token: token,
      user: user,
      errors: errors,
    );
  }
}
