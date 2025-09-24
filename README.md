# Flutter Notes App 📝

A comprehensive full-stack notes management application built with Flutter, featuring a modern UI, robust authentication, and complete CRUD operations.

## 🎯 Features

### Frontend (Flutter)
- **Modern UI Design**: Material Design 3 with dark/light theme support
- **Authentication System**: Complete login/register flow with form validation
- **Notes Management**: Create, read, update, delete notes with rich features
- **Organization Tools**: Categories, tags, priority levels, and completion status
- **Responsive Design**: Works on mobile, tablet, and desktop
- **State Management**: Provider pattern for clean architecture
- **Mock Mode**: Fully functional without backend for testing

### Core Functionality
- ✅ User authentication (login/register/logout)
- ✅ Create, edit, delete notes
- ✅ Note categorization and tagging
- ✅ Priority levels (Low, Medium, High)
- ✅ Search and filter capabilities
- ✅ Statistics dashboard
- ✅ Responsive UI across devices
- ✅ Form validation and error handling
- ✅ Secure data storage

## 🏗️ Architecture

### Frontend Architecture
```
lib/
├── models/           # Data models and JSON serialization
├── services/         # API services and business logic
├── providers/        # State management with Provider
├── screens/          # UI screens and pages
├── widgets/          # Reusable UI components
├── utils/            # Constants, helpers, and utilities
└── main.dart         # App entry point
```

### Key Technologies
- **Flutter 3.35.4** - Cross-platform framework
- **Provider** - State management
- **Dio** - HTTP client for API calls
- **JSON Annotation** - Model serialization
- **Flutter Secure Storage** - Secure local storage
- **Material Design 3** - Modern UI components

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.35.4+
- Dart SDK 3.9.2+
- VS Code or Android Studio
- Chrome (for web testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repository-url>
   cd intern_task
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code (for models)**
   ```bash
   dart run build_runner build
   ```

4. **Run the app**
   ```bash
   # Web (recommended for testing)
   flutter run -d chrome
   
   # Mobile (requires emulator/device)
   flutter run
   ```

## 📱 Usage

### Mock Mode Testing
The app includes a comprehensive mock mode for testing without a backend:

1. **Login**: Use any valid email format and password (6+ characters)
2. **Create Notes**: Fill out title, content, category, priority, and tags
3. **Manage Notes**: Edit, delete, mark as complete
4. **Explore Features**: Categories, tags, search, statistics

### Sample Test Data
- **Email**: `test@example.com`
- **Password**: `password123`
- **Categories**: Personal, Work, Study, Health, Travel
- **Tags**: important, todo, reminder, work, personal, urgent

## 🎨 Screenshots

The app features a modern, clean interface with:
- Dark/Light theme support
- Responsive layout
- Intuitive navigation
- Rich text editing
- Advanced filtering options

## 🛠️ Development

### Project Structure
- **Clean Architecture**: Separation of concerns with models, services, and UI
- **State Management**: Provider pattern for predictable state updates
- **Error Handling**: Comprehensive error handling throughout the app
- **Type Safety**: Strong typing with Dart's type system

### Code Quality
- Dart analysis with strict linting rules
- Consistent code formatting
- Comprehensive error handling
- Type-safe JSON serialization

## 🔄 Future Backend Integration

The app is designed to easily integrate with a backend API:
- RESTful API endpoints already defined
- Authentication flow ready for JWT tokens
- Network error handling in place
- Easy toggle between mock and production modes

### Planned Backend Stack
- **Python + FastAPI** - High-performance API
- **MySQL** - Reliable database
- **JWT Authentication** - Secure token-based auth
- **RESTful Design** - Standard API patterns

## 📈 Performance

- Optimized for smooth 60fps animations
- Efficient state management
- Lazy loading for large datasets
- Memory-efficient image handling
- Fast startup time


