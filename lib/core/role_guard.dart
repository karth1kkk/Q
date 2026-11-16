// lib/core/role_guard.dart
import 'package:flutter/material.dart';
import 'role_cache.dart';

class RoleGuard extends StatelessWidget {
  final String requiredRole;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.requiredRole,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (RoleCache.role != requiredRole) {
      // Should never happen if router guards work, but a hard fail here
      // makes cross-role rendering impossible even if a route is added by mistake.
      return const Scaffold(
        body: Center(child: Text('Access denied')),
      );
    }
    return child;
  }
}