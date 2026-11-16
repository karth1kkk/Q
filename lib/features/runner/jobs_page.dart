// lib/features/runner/jobs_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/location_service.dart';
import '../../core/role_cache.dart';

class RunnerJobsPage extends StatefulWidget {
  const RunnerJobsPage({super.key});

  @override
  State<RunnerJobsPage> createState() => _RunnerJobsPageState();
}

class _RunnerJobsPageState extends State<RunnerJobsPage> {
  Future<List<Map<String, dynamic>>>? _jobsFuture;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    LocationService.start(); // begin streaming location
    _loadJobs();
  }

  @override
  void dispose() {
    LocationService.stop();
    super.dispose();
  }

  void _loadJobs() {
    setState(() {
      _jobsFuture = Supabase.instance.client
          .from('jobs')
          .select('*, bookings(restaurant_id, restaurants(name, lat, lng))')
          .eq('status', 'available')
          .order('accepted_at', ascending: true);
    });
  }

  Future<void> _acceptJob(String jobId, String restaurantName) async {
    setState(() => _accepting = true);
    try {
      // Get current location
      final pos = await LocationService.getCurrent();

      // Call the RPC — server enforces the distance rule
      final result = await Supabase.instance.client.rpc('accept_job', params: {
        'p_job_id': jobId,
        'p_lat': pos.latitude,
        'p_lng': pos.longitude,
      });

      if (!mounted) return;
      final distance = result['distance_m'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accepted $restaurantName ($distance m away)')),
      );
      _loadJobs();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _signOut() async {
    LocationService.stop();
    RoleCache.clear();
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Jobs'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadJobs),
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadJobs(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _jobsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No available jobs right now.')),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Pull down to refresh.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final job = rows[i];
                final booking = job['bookings'] as Map<String, dynamic>?;
                final restaurant =
                    booking?['restaurants'] as Map<String, dynamic>?;
                final name = restaurant?['name'] as String? ?? 'Unknown';
                final payout = (job['payout_amount'] as num?) ?? 10;

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.work_outline),
                  ),
                  title: Text(name),
                  subtitle: Text('Payout: RM${payout.toStringAsFixed(2)}'),
                  trailing: FilledButton(
                    onPressed:
                        _accepting ? null : () => _acceptJob(job['id'], name),
                    child: const Text('Accept'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}