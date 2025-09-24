import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/api_response.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Mock mode for testing (set to true to enable mock authentication)
  static const bool _mockMode = true;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _expiresAtKey = 'expires_at';

  final StreamController<User?> _userController =
      StreamController<User?>.broadcast();
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  User? _currentUser;
  bool _isAuthenticated = false;

  // Getters
  Stream<User?> get userStream => _userController.stream;
  Stream<bool> get authStateStream => _authStateController.stream;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  // Initialize service
  Future<void> initialize() async {
    if (_mockMode) {
      // In mock mode, just set unauthenticated state
      _currentUser = null;
      _isAuthenticated = false;
      _userController.add(null);
      return;
    }

    try {
      await _loadUserFromStorage();
      await _checkTokenValidity();
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      await logout();
    }
  }

  // Login with email and password
  Future<ApiResponse<User>> login(String email, String password) async {
    try {
      // Mock authentication for testing
      if (_mockMode) {
        return _mockLogin(email, password);
      }

      final loginRequest = LoginRequest(
        email: email.trim(),
        password: password,
      );

      final response = await ApiService().post<AuthResponse>(
        ApiEndpoints.login,
        data: loginRequest.toJson(),
        fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );

      if (response.success && response.data != null) {
        await _saveAuthData(response.data!);
        return ApiResponse<User>.success(
          message: response.message,
          data: response.data!.user,
        );
      } else {
        return ApiResponse<User>.error(
          message: response.message,
          errors: response.errors,
        );
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return ApiResponse<User>.error(
        message: 'Login failed. Please try again.',
        errors: [e.toString()],
      );
    }
  }

  // Register new user
  Future<ApiResponse<User>> register(RegisterRequest registerRequest) async {
    try {
      // Mock authentication for testing
      if (_mockMode) {
        return _mockRegister(registerRequest);
      }

      final response = await ApiService().post<AuthResponse>(
        ApiEndpoints.register,
        data: registerRequest.toJson(),
        fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );

      if (response.success && response.data != null) {
        await _saveAuthData(response.data!);
        return ApiResponse<User>.success(
          message: response.message,
          data: response.data!.user,
        );
      } else {
        return ApiResponse<User>.error(
          message: response.message,
          errors: response.errors,
        );
      }
    } catch (e) {
      debugPrint('Register error: $e');
      return ApiResponse<User>.error(
        message: 'Registration failed. Please try again.',
        errors: [e.toString()],
      );
    }
  }

  // Refresh access token
  Future<bool> refreshToken() async {
    try {
      // In mock mode, always return true (token is always valid)
      if (_mockMode) {
        return true;
      }

      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await ApiService().post<AuthResponse>(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
        fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );

      if (response.success && response.data != null) {
        await _saveAuthData(response.data!);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }

  // Get current access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      debugPrint('Get access token error: $e');
      return null;
    }
  }

  // Get current refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('Get refresh token error: $e');
      return null;
    }
  }

  // Check if token is still valid
  Future<bool> isTokenValid() async {
    try {
      final expiresAtStr = await _storage.read(key: _expiresAtKey);
      if (expiresAtStr == null) return false;

      final expiresAt = DateTime.parse(expiresAtStr);
      return DateTime.now().isBefore(expiresAt);
    } catch (e) {
      debugPrint('Token validation error: $e');
      return false;
    }
  }

  // Get user profile
  Future<ApiResponse<User>> getUserProfile() async {
    if (_mockMode) {
      // Create a mock user profile
      final mockUser = User(
        id: '1',
        email: 'user@example.com',
        username: 'johndoe',
        firstName: 'John',
        lastName: 'Doe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
      
      _currentUser = mockUser;
      _userController.add(_currentUser);
      await _saveUserToStorage(_currentUser!);
      
      return ApiResponse<User>(
        success: true,
        data: mockUser,
        message: 'Profile loaded successfully',
      );
    }
    
    try {
      final response = await ApiService().get<User>(
        ApiEndpoints.profile,
        fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
      );

      if (response.success && response.data != null) {
        _currentUser = response.data!;
        _userController.add(_currentUser);
        await _saveUserToStorage(_currentUser!);
      }

      return response;
    } catch (e) {
      debugPrint('Get profile error: $e');
      return ApiResponse<User>.error(
        message: 'Failed to load profile',
        errors: [e.toString()],
      );
    }
  }

  // Update user profile
  Future<ApiResponse<User>> updateProfile(Map<String, dynamic> updates) async {
    if (_mockMode) {
      // Return success without making API call
      return ApiResponse<User>(
        success: true,
        message: 'Profile updated successfully',
      );
    }
    
    try {
      final response = await ApiService().put<User>(
        ApiEndpoints.profile,
        data: updates,
        fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
      );

      if (response.success && response.data != null) {
        _currentUser = response.data!;
        _userController.add(_currentUser);
        await _saveUserToStorage(_currentUser!);
      }

      return response;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return ApiResponse<User>.error(
        message: 'Failed to update profile',
        errors: [e.toString()],
      );
    }
  }

  // Change password
  Future<ApiResponse<void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_mockMode) {
      // Return success without making API call
      return ApiResponse<void>(
        success: true,
        message: 'Password changed successfully',
      );
    }
    
    try {
      final response = await ApiService().put(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      return ApiResponse<void>(
        success: response.success,
        message: response.message,
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Change password error: $e');
      return ApiResponse<void>.error(
        message: 'Failed to change password',
        errors: [e.toString()],
      );
    }
  }

  // Logout user
  Future<void> logout() async {
    if (_mockMode) {
      // Just clear local data in mock mode
      await _clearAuthData();
      return;
    }
    
    try {
      // Try to logout from server
      try {
        await ApiService().post(ApiEndpoints.logout);
      } catch (e) {
        debugPrint('Server logout error: $e');
        // Continue with local logout even if server logout fails
      }

      // Clear local data
      await _clearAuthData();
    } catch (e) {
      debugPrint('Logout error: $e');
      // Force clear even if there's an error
      await _clearAuthData();
    }
  }

  // Delete account
  Future<ApiResponse<void>> deleteAccount(String password) async {
    if (_mockMode) {
      // Just logout in mock mode
      await logout();
      return ApiResponse<void>(
        success: true,
        message: 'Account deleted successfully',
      );
    }
    
    try {
      final response = await ApiService().delete(
        ApiEndpoints.deleteAccount,
        data: {'password': password},
      );

      if (response.success) {
        await logout();
      }

      return ApiResponse<void>(
        success: response.success,
        message: response.message,
        errors: response.errors,
      );
    } catch (e) {
      debugPrint('Delete account error: $e');
      return ApiResponse<void>.error(
        message: 'Failed to delete account',
        errors: [e.toString()],
      );
    }
  }

  // Private methods
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    try {
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: authResponse.accessToken),
        _storage.write(key: _refreshTokenKey, value: authResponse.refreshToken),
        _storage.write(
          key: _expiresAtKey,
          value: authResponse.expiresAt.toIso8601String(),
        ),
        _saveUserToStorage(authResponse.user),
      ]);

      _currentUser = authResponse.user;
      _isAuthenticated = true;

      _userController.add(_currentUser);
      _authStateController.add(true);
    } catch (e) {
      debugPrint('Save auth data error: $e');
      throw e;
    }
  }

  Future<void> _saveUserToStorage(User user) async {
    try {
      final userJson = user.toJson();
      await _storage.write(key: _userKey, value: userJson.toString());
    } catch (e) {
      debugPrint('Save user error: $e');
      throw e;
    }
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final userDataStr = await _storage.read(key: _userKey);
      if (userDataStr != null) {
        final userJson = Map<String, dynamic>.from(
          Uri.splitQueryString(userDataStr),
        );
        _currentUser = User.fromJson(userJson);
        _isAuthenticated = true;

        _userController.add(_currentUser);
        _authStateController.add(true);
      }
    } catch (e) {
      debugPrint('Load user error: $e');
      // Don't throw, just continue without cached user
    }
  }

  Future<void> _checkTokenValidity() async {
    // Skip token validation in mock mode
    if (_mockMode) {
      return;
    }

    if (_isAuthenticated) {
      final isValid = await isTokenValid();
      if (!isValid) {
        final refreshed = await refreshToken();
        if (!refreshed) {
          await _clearAuthData();
        }
      }
    }
  }

  Future<void> _clearAuthData() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userKey),
        _storage.delete(key: _expiresAtKey),
      ]);

      _currentUser = null;
      _isAuthenticated = false;

      _userController.add(null);
      _authStateController.add(false);
    } catch (e) {
      debugPrint('Clear auth data error: $e');
    }
  }

  // Mock authentication methods for testing
  Future<ApiResponse<User>> _mockLogin(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Accept any email/password combination for demo
    // For demo purposes, we'll accept:
    // Email: any valid email format
    // Password: any password with at least 6 characters
    
    if (!email.contains('@') || !email.contains('.')) {
      return ApiResponse<User>.error(
        message: 'Please enter a valid email address',
        errors: ['INVALID_EMAIL'],
      );
    }

    if (password.length < 6) {
      return ApiResponse<User>.error(
        message: 'Password must be at least 6 characters',
        errors: ['PASSWORD_TOO_SHORT'],
      );
    }

    // Create mock user
    final mockUser = User(
      id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim().toLowerCase(),
      username: email.split('@')[0],
      firstName: 'Demo',
      lastName: 'User',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      isActive: true,
      avatarUrl: null,
    );

    // Create mock auth data
    final mockAuthResponse = AuthResponse(
      accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      user: mockUser,
    );

    // Save mock auth data
    await _saveAuthData(mockAuthResponse);

    return ApiResponse<User>.success(
      message: 'Login successful! Welcome to Notes App.',
      data: mockUser,
    );
  }

  Future<ApiResponse<User>> _mockRegister(RegisterRequest registerRequest) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Basic validation
    if (!registerRequest.email.contains('@') || !registerRequest.email.contains('.')) {
      return ApiResponse<User>.error(
        message: 'Please enter a valid email address',
        errors: ['INVALID_EMAIL'],
      );
    }

    if (registerRequest.password.length < 6) {
      return ApiResponse<User>.error(
        message: 'Password must be at least 6 characters',
        errors: ['PASSWORD_TOO_SHORT'],
      );
    }

    if (registerRequest.username.length < 3) {
      return ApiResponse<User>.error(
        message: 'Username must be at least 3 characters',
        errors: ['USERNAME_TOO_SHORT'],
      );
    }

    // Create mock user
    final mockUser = User(
      id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      email: registerRequest.email.trim().toLowerCase(),
      username: registerRequest.username.trim(),
      firstName: registerRequest.firstName?.trim(),
      lastName: registerRequest.lastName?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      avatarUrl: null,
    );

    // Create mock auth data
    final mockAuthResponse = AuthResponse(
      accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      user: mockUser,
    );

    // Save mock auth data
    await _saveAuthData(mockAuthResponse);

    return ApiResponse<User>.success(
      message: 'Account created successfully! Welcome to Notes App.',
      data: mockUser,
    );
  }

  // Cleanup
  void dispose() {
    _userController.close();
    _authStateController.close();
  }
}
