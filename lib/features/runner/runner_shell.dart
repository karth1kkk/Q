// lib/features/runner/runner_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/role_cache.dart';

class RunnerShell extends StatelessWidget {
  final Widget child;
  const RunnerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = location.contains('profile') ? 1 : 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          if (i == 0) context.go('/runner/jobs');
          if (i == 1) context.go('/runner/profile');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.work), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }
}

// Simple profile page for Runner
class RunnerProfilePage extends StatelessWidget {
  const RunnerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Runner Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You are logged in as a Runner.'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                RoleCache.clear();
                await Supabase.instance.client.auth.signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}