// lib/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/role_cache.dart';
import 'features/auth/login_page.dart';
import 'features/auth/role_select_page.dart';
import 'features/diner/browse_page.dart';
import 'features/diner/diner_shell.dart';
import 'features/runner/jobs_page.dart';
import 'features/runner/runner_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        RoleCache.clear();
      }
      notifyListeners();
    });
  }
}
final _authNotifier = AuthChangeNotifier();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final path = state.matchedLocation;
    final role = RoleCache.role;

    if (session == null) {
      return path == '/login' ? null : '/login';
    }

    if (role == null) {
      return path == '/role-select' ? null : '/role-select';
    }

    if (role == 'diner' && path.startsWith('/runner')) return '/diner/browse';
    if (role == 'runner' && path.startsWith('/diner')) return '/runner/jobs';

    if (path == '/login' || path == '/role-select') {
      return role == 'runner' ? '/runner/jobs' : '/diner/browse';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/role-select', builder: (_, __) => const RoleSelectPage()),
    
    // 🍽️ DINER INTERFACE (Using ShellRoute to wrap pages)
    ShellRoute(
      builder: (context, state, child) => DinerShell(child: child),
      routes: [
        GoRoute(path: '/diner/browse', builder: (_, __) => const DinerBrowsePage()),
        GoRoute(path: '/diner/profile', builder: (_, __) => const DinerProfilePage()),
      ],
    ),

    // 🏃 RUNNER INTERFACE (Using ShellRoute to wrap pages)
    ShellRoute(
      builder: (context, state, child) => RunnerShell(child: child),
      routes: [
        GoRoute(path: '/runner/jobs', builder: (_, __) => const RunnerJobsPage()),
        GoRoute(path: '/runner/profile', builder: (_, __) => const RunnerProfilePage()),
      ],
    ),
  ],
);