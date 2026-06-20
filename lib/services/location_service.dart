// lib/services/location_service.dart

import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Minta izin dan dapatkan posisi saat ini
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Hitung jarak antara dua koordinat (meter) dengan Haversine
  static double hitungJarak(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const R = 6371000.0; // radius bumi dalam meter
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  // Validasi apakah user dalam radius salon
  static bool dalamRadius({
    required double userLat,
    required double userLng,
    required double salonLat,
    required double salonLng,
    required double radiusMeter,
  }) {
    final jarak = hitungJarak(userLat, userLng, salonLat, salonLng);
    return jarak <= radiusMeter;
  }
}
