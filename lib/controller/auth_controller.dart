import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../model/user_model.dart';
import '../utlits/api_constants.dart';

/// Auth Controller using ChangeNotifier for Provider state management
class AuthController extends ChangeNotifier {
  User? _user;
  String? _accessToken;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  // Getters
  User? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;

  // File names for storage
  static const String _tokenFileName = 'frusette_token.txt';
  static const String _userFileName = 'frusette_user.json';

  /// Get the app's document directory
  Future<Directory> _getStorageDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final appDir = Directory('${directory.path}/frusette');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  /// Initialize auth state from stored data
  Future<bool> init() async {
    try {
      debugPrint('=== AuthController: Initializing ===');

      final dir = await _getStorageDirectory();
      final tokenFile = File('${dir.path}/$_tokenFileName');
      final userFile = File('${dir.path}/$_userFileName');

      debugPrint('AuthController: Token file path: ${tokenFile.path}');
      debugPrint(
        'AuthController: Token file exists: ${await tokenFile.exists()}',
      );

      if (await tokenFile.exists()) {
        final token = await tokenFile.readAsString();
        debugPrint('AuthController: Token read: ${token.isNotEmpty}');

        if (token.isNotEmpty) {
          _accessToken = token;
          _isLoggedIn = true;

          if (await userFile.exists()) {
            try {
              final userData = await userFile.readAsString();
              _user = User.fromJson(jsonDecode(userData));
              debugPrint('AuthController: User loaded: ${_user?.fullName}');
            } catch (e) {
              debugPrint('AuthController: Error parsing user data: $e');
            }
          }

          notifyListeners();
          debugPrint('=== AuthController: User IS logged in ===');
          return true;
        }
      }

      _isLoggedIn = false;
      debugPrint('=== AuthController: User NOT logged in ===');
      return false;
    } catch (e) {
      debugPrint('AuthController: Error initializing auth: $e');
      return false;
    }
  }

  /// Login with email and password
  Future<LoginResponse> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = ApiConstants.getUrl(ApiConstants.login);
      debugPrint('AuthController: Logging in to $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConstants.defaultHeaders,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(ApiConstants.requestTimeout);

      debugPrint('AuthController: Response status: ${response.statusCode}');
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final loginResponse = LoginResponse.fromJson(responseData);

        if (loginResponse.success) {
          _accessToken = loginResponse.accessToken;
          _user = loginResponse.user;
          _isLoggedIn = true;

          debugPrint('AuthController: Login successful!');
          debugPrint(
            'AuthController: Token: ${_accessToken?.substring(0, 20)}...',
          );
          debugPrint('AuthController: User: ${_user?.fullName}');

          // Save to file
          await _saveAuthData();

          _isLoading = false;
          notifyListeners();
          return loginResponse;
        } else {
          _errorMessage = loginResponse.errorMessage ?? 'Login failed';
          _isLoading = false;
          notifyListeners();
          return loginResponse;
        }
      } else {
        final errorMsg =
            responseData['message'] ?? 'Login failed. Please try again.';
        _errorMessage = errorMsg;
        _isLoading = false;
        notifyListeners();
        return LoginResponse.error(errorMsg);
      }
    } catch (e) {
      debugPrint('AuthController: Login error: $e');
      _errorMessage = 'Network error. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      return LoginResponse.error(_errorMessage!);
    }
  }

  /// Save auth data to file
  Future<void> _saveAuthData() async {
    try {
      debugPrint('=== AuthController: Saving auth data ===');

      final dir = await _getStorageDirectory();
      final tokenFile = File('${dir.path}/$_tokenFileName');
      final userFile = File('${dir.path}/$_userFileName');

      if (_accessToken != null && _accessToken!.isNotEmpty) {
        await tokenFile.writeAsString(_accessToken!);
        debugPrint('AuthController: Token saved to: ${tokenFile.path}');

        // Verify
        final verify = await tokenFile.readAsString();
        debugPrint(
          'AuthController: VERIFY - Token saved: ${verify.isNotEmpty}',
        );
      }

      if (_user != null) {
        final userJson = jsonEncode(_user!.toJson());
        await userFile.writeAsString(userJson);
        debugPrint('AuthController: User data saved to: ${userFile.path}');
      }

      debugPrint('=== AuthController: Save complete ===');
    } catch (e) {
      debugPrint('AuthController: Error saving auth data: $e');
    }
  }

  /// Logout and clear stored data
  Future<void> logout() async {
    try {
      debugPrint('=== AuthController: Logging out ===');

      final dir = await _getStorageDirectory();
      final tokenFile = File('${dir.path}/$_tokenFileName');
      final userFile = File('${dir.path}/$_userFileName');

      if (await tokenFile.exists()) {
        await tokenFile.delete();
        debugPrint('AuthController: Token file deleted');
      }

      if (await userFile.exists()) {
        await userFile.delete();
        debugPrint('AuthController: User file deleted');
      }

      _user = null;
      _accessToken = null;
      _isLoggedIn = false;
      _errorMessage = null;

      notifyListeners();
      debugPrint('=== AuthController: Logged out successfully ===');
    } catch (e) {
      debugPrint('AuthController: Error during logout: $e');
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Check if user is authenticated
  Future<bool> checkAuth() async {
    debugPrint('AuthController: checkAuth called');
    final result = await init();
    debugPrint('AuthController: checkAuth returning $result');
    return result;
  }
}
