/// User Model for Frusette Customer App
class User {
  final String id;
  final String email;
  final String fullName;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'customer',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'full_name': fullName, 'role': role};
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, role: $role)';
  }
}

/// Login Response Model
class LoginResponse {
  final bool success;
  final String? accessToken;
  final User? user;
  final String? errorMessage;

  LoginResponse({
    required this.success,
    this.accessToken,
    this.user,
    this.errorMessage,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] ?? false;

    if (success && json['data'] != null) {
      final data = json['data'];
      return LoginResponse(
        success: true,
        accessToken: data['access_token'],
        user: data['user'] != null ? User.fromJson(data['user']) : null,
      );
    } else {
      return LoginResponse(
        success: false,
        errorMessage: json['message'] ?? 'Login failed',
      );
    }
  }

  factory LoginResponse.error(String message) {
    return LoginResponse(success: false, errorMessage: message);
  }
}
