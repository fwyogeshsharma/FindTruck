import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Result of resolving the device's current place.
class PlaceResult {
  const PlaceResult({this.position, this.city, this.state, this.error});

  final Position? position;
  final String? city;
  final String? state;
  final String? error;

  bool get ok => error == null && position != null;

  String get label {
    final parts = [if (city != null) city!, if (state != null) state!];
    return parts.isEmpty ? 'Location set' : parts.join(', ');
  }
}

/// Device GPS + reverse geocoding. Used by the dashboard to detect the user's
/// city/state and to label/sort trucks by proximity.
///
/// Note: the `geocoding` plugin has no web implementation, so city names are
/// only resolved on mobile. Web still gets the GPS position (for distance).
class LocationService {
  final Map<String, String?> _cityCache = {};

  Future<PlaceResult> currentPlace() async {
    try {
      if (!kIsWeb) {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) {
          return const PlaceResult(
              error: 'Location services are turned off on this device.');
        }
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return const PlaceResult(error: 'Location permission denied.');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      String? city, state;
      if (!kIsWeb) {
        try {
          final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
          if (marks.isNotEmpty) {
            final m = marks.first;
            city = _pick(m.locality, m.subAdministrativeArea);
            state = _nonEmpty(m.administrativeArea);
          }
        } catch (_) {
          // Geocoding can fail offline — keep the position, drop the name.
        }
      }
      return PlaceResult(position: pos, city: city, state: state);
    } catch (e) {
      return PlaceResult(error: '$e');
    }
  }

  /// Reverse-geocode a truck's coordinates to a city name (cached).
  Future<String?> cityFor(double lat, double lng) async {
    if (kIsWeb) return null;
    final key = '${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}';
    if (_cityCache.containsKey(key)) return _cityCache[key];
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      final city = marks.isEmpty
          ? null
          : _pick(marks.first.locality, marks.first.subAdministrativeArea);
      return _cityCache[key] = city;
    } catch (_) {
      return _cityCache[key] = null;
    }
  }

  /// Straight-line distance in km between two coordinates.
  double distanceKm(double aLat, double aLng, double bLat, double bLng) =>
      Geolocator.distanceBetween(aLat, aLng, bLat, bLng) / 1000.0;

  String? _pick(String? a, String? b) => _nonEmpty(a) ?? _nonEmpty(b);
  String? _nonEmpty(String? s) => (s != null && s.trim().isNotEmpty) ? s : null;
}
