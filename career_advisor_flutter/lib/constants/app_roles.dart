/// Role values that match the backend (User.Role / API responses).
/// Use these for comparisons so user/admin behavior stays in sync with the server.
class AppRoles {
  AppRoles._();

  static const String user = 'USER';
  static const String admin = 'ADMIN';

  static bool isAdmin(String? role) =>
      role != null && role.toUpperCase() == admin;
  static bool isUser(String? role) =>
      role != null && role.toUpperCase() == user;
}
