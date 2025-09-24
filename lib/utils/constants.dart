// API Configuration
class ApiConstants {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const String localBaseUrl =
      'http://10.0.2.2:8000/api/v1'; // For Android emulator

  // Timeouts
  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 30000;
  static const int sendTimeoutMs = 30000;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

// API Endpoints
class ApiEndpoints {
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';
  static const String deleteAccount = '/auth/delete-account';

  // Notes endpoints
  static const String notes = '/notes';
  static const String createNote = '/notes';
  static const String updateNote = '/notes'; // + /{id}
  static const String deleteNote = '/notes'; // + /{id}
  static const String getNotes = '/notes';
  static const String getNote = '/notes'; // + /{id}
  static const String searchNotes = '/notes/search';
  static const String toggleComplete = '/notes'; // + /{id}/toggle

  // Categories endpoints
  static const String categories = '/categories';

  // Tags endpoints
  static const String tags = '/tags';

  // Health check
  static const String health = '/health';
}

// App Configuration
class AppConfig {
  static const String appName = 'Notes App';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Professional full-stack notes application';

  // Features flags
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = false;
  static const bool enableBiometricAuth = false;
  static const bool enableDarkMode = true;

  // Cache settings
  static const int cacheExpirationHours = 24;
  static const int maxCachedNotes = 1000;
}

// UI Constants
class UIConstants {
  // Colors
  static const primaryColorCode = 0xFF2196F3;
  static const secondaryColorCode = 0xFF03DAC6;
  static const errorColorCode = 0xFFB00020;
  static const surfaceColorCode = 0xFFFFFBFE;

  // Spacing
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  static const double paddingXXLarge = 48.0;

  // Border radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;

  // Animation durations
  static const int animationDurationFast = 200;
  static const int animationDurationMedium = 300;
  static const int animationDurationSlow = 500;

  // Breakpoints
  static const double mobileMaxWidth = 768;
  static const double tabletMaxWidth = 1024;
  static const double desktopMinWidth = 1025;
}

// Storage Keys
class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userData = 'user_data';
  static const String theme = 'theme_preference';
  static const String language = 'language_preference';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String notesCache = 'notes_cache';
  static const String lastSyncTimestamp = 'last_sync_timestamp';
}

// Error Codes
class ErrorCodes {
  static const String networkError = 'NETWORK_ERROR';
  static const String timeoutError = 'TIMEOUT_ERROR';
  static const String unauthorizedError = 'UNAUTHORIZED_ERROR';
  static const String forbiddenError = 'FORBIDDEN_ERROR';
  static const String notFoundError = 'NOT_FOUND_ERROR';
  static const String validationError = 'VALIDATION_ERROR';
  static const String serverError = 'SERVER_ERROR';
  static const String unknownError = 'UNKNOWN_ERROR';
  static const String cacheError = 'CACHE_ERROR';
  static const String parseError = 'PARSE_ERROR';
}

// Validation Constants
class ValidationConstants {
  // Email
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';

  // Password
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 128;
  static const String passwordPattern =
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]';

  // Username
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 30;
  static const String usernamePattern = r'^[a-zA-Z0-9_]+$';

  // Notes
  static const int noteTitleMaxLength = 200;
  static const int noteContentMaxLength = 10000;
  static const int tagMaxLength = 50;
  static const int maxTagsPerNote = 10;

  // Names
  static const int nameMaxLength = 50;
}

// Default Values
class DefaultValues {
  static const String defaultCategory = 'General';
  static const String defaultNoteTitle = 'Untitled Note';
  static const String defaultNoteContent = '';
  static const int defaultPageSize = 20;
  static const String defaultSortBy = 'updated_at';
  static const String defaultSortOrder = 'desc';
}

// Route Names
class RouteNames {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String notes = '/notes';
  static const String addNote = '/add-note';
  static const String editNote = '/edit-note';
  static const String noteDetail = '/note-detail';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String categories = '/categories';
  static const String tags = '/tags';
}

// Asset Paths
class AssetPaths {
  static const String images = 'assets/images/';
  static const String icons = 'assets/icons/';
  static const String fonts = 'assets/fonts/';

  // Specific assets
  static const String logo = '${images}logo.png';
  static const String placeholder = '${images}placeholder.png';
  static const String emptyState = '${images}empty_state.png';
  static const String errorState = '${images}error_state.png';
}

// Development Configuration
class DevConfig {
  static const bool enableLogging = true;
  static const bool enablePrettyJsonLogs = true;
  static const bool enableNetworkLogs = true;
  static const bool enablePerformanceLogs = true;
  static const bool showDebugBanner = false;
}
