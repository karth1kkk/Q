// lib/features/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/role_cache.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  String _selectedRole = 'diner'; // 'diner' or 'runner'
  bool _codeSent = false;
  bool _loading = false;
  String? _error;

  // ─── SEND OTP ────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !phone.startsWith('+')) {
      setState(() => _error = 'Enter phone with country code (e.g. +60123456789)');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);
      setState(() => _codeSent = true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── VERIFY OTP ──────────────────────────────────────────
  Future<void> _verifyOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: _phoneController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.sms,
      );

      if (response.session == null) {
        setState(() => _error = 'Invalid code');
        return;
      }

      final userId = response.session!.user.id;

      // Check if this user already exists and has a role
      final existing = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      final existingRole = existing?['role'] as String?;

      if (existingRole != null) {
        // Returning user — use their saved role (ignore selection)
        RoleCache.set(existingRole);

        if (!mounted) return;
        context.go(existingRole == 'runner' ? '/runner/jobs' : '/diner/browse');
        return;
      }

      // New user — save the role they picked on this screen
      await Supabase.instance.client.from('users').upsert({
        'id': userId,
        'phone': response.session!.user.phone,
        'role': _selectedRole,
      });

      if (_selectedRole == 'runner') {
        await Supabase.instance.client
            .from('runner_profiles')
            .upsert({'user_id': userId});
      }

      RoleCache.set(_selectedRole);

      if (!mounted) return;
      context.go(_selectedRole == 'runner' ? '/runner/jobs' : '/diner/browse');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ─── BUILD ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── LOGO / HEADER ──────────────────────
                  const Icon(Icons.restaurant_menu,
                      size: 64, color: Colors.deepOrange),
                  const SizedBox(height: 16),
                  Text(
                    'Q',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _codeSent
                        ? 'Enter the code sent to ${_phoneController.text}'
                        : 'Skip the queue. Or get paid to wait in one.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  if (!_codeSent) ...[
                    // ─── ROLE SELECTOR ────────────────────
                    Text('I am a…',
                        style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _RoleTile(
                            label: 'Diner',
                            icon: Icons.restaurant,
                            selected: _selectedRole == 'diner',
                            onTap: _loading
                                ? null
                                : () => setState(
                                    () => _selectedRole = 'diner'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleTile(
                            label: 'Runner',
                            icon: Icons.directions_run,
                            selected: _selectedRole == 'runner',
                            onTap: _loading
                                ? null
                                : () => setState(
                                    () => _selectedRole = 'runner'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── PHONE INPUT ──────────────────────
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '+60123456789',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _sendOtp,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _selectedRole == 'runner'
                                  ? 'Continue as Runner'
                                  : 'Continue as Diner',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ] else ...[
                    // ─── OTP INPUT ────────────────────────
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      enabled: !_loading,
                      autofocus: true,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24, letterSpacing: 12),
                      decoration: const InputDecoration(
                        labelText: '6-digit code',
                        hintText: '123456',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _verifyOtp,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Verify & Continue',
                              style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                                _codeSent = false;
                                _otpController.clear();
                                _error = null;
                              }),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Change number'),
                    ),
                  ],

                  // ─── ERROR ────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: theme.colorScheme.onErrorContainer,
                              size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ─── FOOTER ──────────────────────────────
                  if (!_codeSent)
                    Text(
                      _selectedRole == 'runner'
                          ? 'Earn money by holding tables for diners.'
                          : 'Never wait in line at popular restaurants again.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ROLE TILE WIDGET ────────────────────────────────────
class _RoleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _RoleTile({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: selected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: selected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}