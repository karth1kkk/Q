// lib/core/location_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  static Timer? _timer;
  static bool _running = false;

  /// Start pushing location every 30 seconds to Supabase.
  static Future<void> start() async {
    if (_running) return;
    _running = true;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    _push(); // immediate
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _push());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  static Future<void> _push() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await Supabase.instance.client.rpc('update_runner_location', params: {
        'p_lat': pos.latitude,
        'p_lng': pos.longitude,
      });
    } catch (_) {
      // Silently ignore — will retry next tick
    }
  }

  /// One-shot fetch for the accept flow
  static Future<Position> getCurrent() async {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}