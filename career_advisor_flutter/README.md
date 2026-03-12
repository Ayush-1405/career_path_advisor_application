# Career Advisor Flutter App

A Flutter mobile application for the Career Advisor platform, converted from the Next.js web application. This app provides AI-powered career guidance, resume analysis, skills assessment, and career path recommendations.

## Features

- **User Authentication**: Login and registration with role-based access
- **Admin Portal**: Separate admin login and dashboard for platform management
- **Resume Analysis**: Upload and analyze resumes to get career insights
- **Skills Assessment**: Take comprehensive skills tests
- **Career Paths**: Discover and explore various career paths
- **User Dashboard**: Track progress and view recommendations
- **Admin Dashboard**: Monitor users, resumes, and platform analytics
- **Splash Screen**: Beautiful splash screen on app launch

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   └── auth_response.dart
├── services/                 # Business logic
│   ├── api_service.dart      # Backend API integration
│   └── auth_service.dart     # Authentication logic
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── auth/                 # Authentication screens
│   │   ├── user_login_screen.dart
│   │   ├── user_register_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── user/                 # User screens
│   │   ├── home_screen.dart
│   │   ├── user_dashboard_screen.dart
│   │   ├── analyze_screen.dart
│   │   ├── skills_screen.dart
│   │   └── career_paths_screen.dart
│   └── admin/                # Admin screens
│       ├── admin_login_screen.dart
│       ├── admin_dashboard_screen.dart
│       ├── admin_manage_screen.dart
│       ├── admin_resumes_screen.dart
│       ├── admin_analytics_screen.dart
│       └── admin_settings_screen.dart
├── utils/                    # Utilities
│   └── theme.dart            # App theme configuration
└── widgets/                  # Reusable widgets
```

## Backend Configuration

The app automatically configures the backend URL based on the platform:
- **Android Emulator**: `http://10.0.2.2:8080` (10.0.2.2 is the special IP to access host machine's localhost)
- **iOS Simulator**: `http://localhost:8080`
- **Physical Devices**: You need to use your computer's IP address (e.g., `http://192.168.1.100:8080`)

To manually change the backend URL, update `lib/utils/config.dart`:

```dart
static String get baseUrl {
  // Your custom URL
  return 'http://your-backend-url:8080';
}
```

**Important**: For physical devices (Android/iOS), you must:
1. Find your computer's IP address (use `ipconfig` on Windows or `ifconfig` on Mac/Linux)
2. Ensure your backend allows connections from your network
3. Update the baseUrl in `config.dart` to use your computer's IP

## Setup Instructions

1. **Install Flutter**: Make sure you have Flutter installed (SDK 3.10.4 or higher)

2. **Install Dependencies**:
   ```bash
   cd career_advisor_flutter
   flutter pub get
   ```

3. **Run the App**:
   ```bash
   flutter run
   ```

## Authentication Flow

### User Flow
1. App starts with splash screen
2. Checks for existing user session
3. If logged in → Navigate to Home/Dashboard
4. If not logged in → Navigate to Login screen
5. After login, role is checked:
   - If ADMIN → Redirect to Admin Dashboard
   - If USER → Redirect to User Home/Dashboard

### Admin Flow
1. Admin can access admin login from user login screen
2. Admin credentials are validated (role must be ADMIN)
3. On successful login → Admin Dashboard
4. Admin has access to:
   - User management
   - Resume management
   - Analytics
   - Settings

## Design

The app maintains the original design from the Next.js application:
- **User Theme**: Blue-purple gradient (primary colors)
- **Admin Theme**: Red-orange gradient (primary colors)
- **Material Design 3**: Modern, clean UI
- **Responsive Layout**: Works on various screen sizes

## API Endpoints Used

### Authentication
- `POST /api/auth/login` - User/Admin login
- `POST /api/auth/register` - User registration

### User Endpoints
- `GET /api/users/me/stats` - Dashboard statistics
- `POST /api/users/me/activity` - Track user activity
- `GET /api/career-paths` - Get career paths
- `GET /api/career-paths/{id}` - Get career path details
- `POST /api/resumes` - Submit resume

### Admin Endpoints
- `GET /api/admin/dashboard/stats` - Admin dashboard statistics
- `GET /api/admin/users` - Get all users
- `GET /api/admin/resumes` - Get all resumes
- `GET /admin/analytics` - Get analytics data
- `GET /api/admin/settings` - Get admin settings
- `PUT /api/admin/settings` - Update admin settings

## Demo Credentials

### Admin
- Email: `admin@careerpathai.com`
- Password: `admin123`

### User
- Register a new account or use existing credentials

## Troubleshooting

1. **Backend Connection Issues**: 
   - Ensure the Spring Boot backend is running on `http://localhost:8080`
   - For Android emulator, use `http://10.0.2.2:8080`
   - For iOS simulator, use `http://localhost:8080`
   - For physical devices, use your computer's IP address

2. **Dependencies Issues**:
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Build Issues**:
   ```bash
   flutter doctor
   flutter pub upgrade
   ```

## Notes

- The app uses SharedPreferences for local storage of authentication tokens
- Role-based routing ensures users and admins see appropriate screens
- All API calls include JWT token authentication
- The design closely matches the original Next.js application

## License

This project is part of the Career Advisor platform.
