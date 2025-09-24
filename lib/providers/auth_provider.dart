import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/exceptions.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // State
  AuthState _state = AuthState.initial;
  User? _user;
  String? _errorMessage;
  List<String> _errorDetails = [];

  // Stream subscriptions
  StreamSubscription<User?>? _userSubscription;
  StreamSubscription<bool>? _authStateSubscription;

  // Constructor with auto-initialization
  AuthProvider() {
    // Auto-initialize when created
    initialize();
  }

  // Getters
  AuthState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  List<String> get errorDetails => _errorDetails;
  bool get isAuthenticated =>
      _state == AuthState.authenticated && _user != null;
  bool get isUnauthenticated => _state == AuthState.unauthenticated;
  bool get isLoading => _state == AuthState.loading;
  bool get hasError => _state == AuthState.error;
  bool get isInitialized => _state != AuthState.initial;

  // User properties
  String? get userId => _user?.id;
  String? get userEmail => _user?.email;
  String? get userName => _user?.username;
  String? get userDisplayName => _user?.displayName;
  String? get userFullName => _user?.fullName;
  String? get userAvatarUrl => _user?.avatarUrl;

  // Initialize provider
  Future<void> initialize() async {
    _setState(AuthState.loading);

    try {
      // Initialize auth service
      await _authService.initialize();

      // Listen to auth state changes
      _userSubscription = _authService.userStream.listen(_onUserChanged);
      _authStateSubscription = _authService.authStateStream.listen(
        _onAuthStateChanged,
      );

      // Set initial state based on current auth status
      if (_authService.isAuthenticated && _authService.currentUser != null) {
        _user = _authService.currentUser;
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      debugPrint('Auth provider initialization error: $e');
      _setError('Failed to initialize authentication', [e.toString()]);
    }
  }

  // Check current authentication status
  Future<void> checkAuthStatus() async {
    try {
      // Initialize if not already done
      if (_state == AuthState.initial) {
        await initialize();
        return;
      }

      // Check if we have a current user from the auth service
      if (_authService.isAuthenticated && _authService.currentUser != null) {
        _user = _authService.currentUser;
        _setState(AuthState.authenticated);
      } else {
        // Clear invalid auth state
        _user = null;
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      debugPrint('Auth status check error: $e');
      // On error, assume unauthenticated
      _user = null;
      _setState(AuthState.unauthenticated);
    }
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    if (isLoading) return false;

    _setState(AuthState.loading);
    _clearError();

    try {
      // Validate input
      if (email.trim().isEmpty || password.isEmpty) {
        _setError('Please provide both email and password', [
          'VALIDATION_ERROR',
        ]);
        return false;
      }

      final response = await _authService.login(email.trim(), password);

      if (response.success && response.data != null) {
        _user = response.data!;
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setError(response.message, response.errors);
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      if (e is AuthenticationException) {
        _setError(e.message, [e.code ?? 'AUTH_ERROR']);
      } else if (e is ValidationException) {
        _setError(e.message, [e.allErrors]);
      } else if (e is NetworkException) {
        _setError('Network error. Please check your connection.', [
          'NETWORK_ERROR',
        ]);
      } else {
        _setError('Login failed. Please try again.', [e.toString()]);
      }
      return false;
    }
  }

  // Register new user
  Future<bool> register(RegisterRequest request) async {
    if (isLoading) return false;

    _setState(AuthState.loading);
    _clearError();

    try {
      // Validate input
      if (request.email.trim().isEmpty ||
          request.username.trim().isEmpty ||
          request.password.isEmpty) {
        _setError('Please fill in all required fields', ['VALIDATION_ERROR']);
        return false;
      }

      final response = await _authService.register(request);

      if (response.success && response.data != null) {
        _user = response.data!;
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setError(response.message, response.errors);
        return false;
      }
    } catch (e) {
      debugPrint('Register error: $e');
      if (e is ValidationException) {
        _setError(e.message, [e.allErrors]);
      } else if (e is EmailAlreadyExistsException) {
        _setError(e.message, [e.code ?? 'EMAIL_EXISTS']);
      } else if (e is UsernameAlreadyExistsException) {
        _setError(e.message, [e.code ?? 'USERNAME_EXISTS']);
      } else if (e is NetworkException) {
        _setError('Network error. Please check your connection.', [
          'NETWORK_ERROR',
        ]);
      } else {
        _setError('Registration failed. Please try again.', [e.toString()]);
      }
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    if (isLoading) return;

    _setState(AuthState.loading);

    try {
      await _authService.logout();
      _user = null;
      _clearError();
      _setState(AuthState.unauthenticated);
    } catch (e) {
      debugPrint('Logout error: $e');
      // Force logout even if there's an error
      _user = null;
      _clearError();
      _setState(AuthState.unauthenticated);
    }
  }

  // Get user profile
  Future<bool> getUserProfile() async {
    if (!isAuthenticated) return false;

    try {
      final response = await _authService.getUserProfile();

      if (response.success && response.data != null) {
        _user = response.data!;
        notifyListeners();
        return true;
      } else {
        _setError(response.message, response.errors);
        return false;
      }
    } catch (e) {
      debugPrint('Get profile error: $e');
      _setError('Failed to load profile', [e.toString()]);
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (!isAuthenticated) return false;

    final previousState = _state;
    _setState(AuthState.loading);

    try {
      final response = await _authService.updateProfile(updates);

      if (response.success && response.data != null) {
        _user = response.data!;
        _setState(previousState);
        return true;
      } else {
        _setError(response.message, response.errors);
        return false;
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      if (e is ValidationException) {
        _setError(e.message, [e.allErrors]);
      } else {
        _setError('Failed to update profile', [e.toString()]);
      }
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (!isAuthenticated) return false;

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      _setError('Please provide both current and new passwords', [
        'VALIDATION_ERROR',
      ]);
      return false;
    }

    final previousState = _state;
    _setState(AuthState.loading);

    try {
      final response = await _authService.changePassword(
        currentPassword,
        newPassword,
      );

      if (response.success) {
        _setState(previousState);
        return true;
      } else {
        _setError(response.message, response.errors);
        return false;
      }
    } catch (e) {
      debugPrint('Change password error: $e');
      if (e is ValidationException) {
        _setError(e.message, [e.allErrors]);
      } else if (e is UnauthorizedException) {
        _setError('Current password is incorrect', ['INVALID_PASSWORD']);
      } else {
        _setError('Failed to change password', [e.toString()]);
      }
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount(String password) async {
    if (!isAuthenticated) return false;

    if (password.isEmpty) {
      _setError('Please provide your password to delete account', [
        'VALIDATION_ERROR',
      ]);
      return false;
    }

    _setState(AuthState.loading);

    try {
      final response = await _authService.deleteAccount(password);

      if (response.success) {
        _user = null;
        _clearError();
        _setState(AuthState.unauthenticated);
        return true;
      } else {
        _setError(response.message, response.errors);
        return false;
      }
    } catch (e) {
      debugPrint('Delete account error: $e');
      if (e is UnauthorizedException) {
        _setError('Password is incorrect', ['INVALID_PASSWORD']);
      } else {
        _setError('Failed to delete account', [e.toString()]);
      }
      return false;
    }
  }

  // Check if token is still valid
  Future<bool> isTokenValid() async {
    try {
      return await _authService.isTokenValid();
    } catch (e) {
      debugPrint('Token validation error: $e');
      return false;
    }
  }

  // Refresh access token
  Future<bool> refreshToken() async {
    try {
      return await _authService.refreshToken();
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }

  // Quick login validation (for forms)
  String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? validatePassword(String? password, {bool isNewPassword = false}) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (isNewPassword) {
      if (password.length < 8) {
        return 'Password must be at least 8 characters long';
      }

      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
        return 'Password must contain uppercase, lowercase and numbers';
      }
    }

    return null;
  }

  String? validateUsername(String? username) {
    if (username == null || username.trim().isEmpty) {
      return 'Username is required';
    }

    if (username.trim().length < 3) {
      return 'Username must be at least 3 characters long';
    }

    if (username.trim().length > 30) {
      return 'Username must be less than 30 characters';
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(username.trim())) {
      return 'Username can only contain letters, numbers and underscore';
    }

    return null;
  }

  String? validateName(String? name, String fieldName) {
    if (name != null && name.trim().isNotEmpty) {
      if (name.trim().length > 50) {
        return '$fieldName must be less than 50 characters';
      }
    }
    return null;
  }

  // Clear error
  void clearError() {
    _clearError();
    if (_state == AuthState.error) {
      _setState(
        _user != null ? AuthState.authenticated : AuthState.unauthenticated,
      );
    }
  }

  // Private methods
  void _setState(AuthState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void _setError(String message, List<String>? errors) {
    _errorMessage = message;
    _errorDetails = errors ?? [];
    _setState(AuthState.error);
  }

  void _clearError() {
    _errorMessage = null;
    _errorDetails = [];
  }

  void _onUserChanged(User? user) {
    if (_user != user) {
      _user = user;
      notifyListeners();
    }
  }

  void _onAuthStateChanged(bool isAuthenticated) {
    if (isAuthenticated && _user != null) {
      _setState(AuthState.authenticated);
    } else {
      _setState(AuthState.unauthenticated);
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _authStateSubscription?.cancel();
    _authService.dispose();
    super.dispose();
  }
}
