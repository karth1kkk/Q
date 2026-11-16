// lib/features/auth/role_select_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/role_cache.dart';

class RoleSelectPage extends StatefulWidget {
  const RoleSelectPage({super.key});

  @override
  State<RoleSelectPage> createState() => _RoleSelectPageState();
}

class _RoleSelectPageState extends State<RoleSelectPage> {
  bool _saving = false;

  Future<void> _pickRole(String role) async {
    setState(() => _saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Upsert the user row with the chosen role
      await Supabase.instance.client.from('users').upsert({
        'id': user.id,
        'phone': user.phone,
        'role': role,
      });

      // If runner, also create the runner profile row
      if (role == 'runner') {
        await Supabase.instance.client
            .from('runner_profiles')
            .upsert({'user_id': user.id});
      }

      // Update the in-memory role cache BEFORE navigating
      RoleCache.set(role);

      if (!mounted) return;
      context.go(role == 'runner' ? '/runner/jobs' : '/diner/browse');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How will you use Table Relay?')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoleCard(
              title: 'I want to book tables',
              subtitle: 'Skip the queue at popular restaurants',
              icon: Icons.restaurant,
              onTap: _saving ? null : () => _pickRole('diner'),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              title: 'I want to queue for pay',
              subtitle: 'Earn money by waiting in line',
              icon: Icons.directions_run,
              onTap: _saving ? null : () => _pickRole('runner'),
            ),
            const SizedBox(height: 24),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}