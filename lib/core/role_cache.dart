// lib/core/role_cache.dart
class RoleCache {
  static String? _role;

  static String? get role => _role;
  static bool get isDiner => _role == 'diner';
  static bool get isRunner => _role == 'runner';

  static void set(String role) => _role = role;
  static void clear() => _role = null;
}