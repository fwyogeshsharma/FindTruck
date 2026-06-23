import 'dart:async';
import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../models/truck.dart';
import 'api_client.dart';

/// Source of truck data. The truckfinder app reads the FreightDesk truck
/// database and tracks a truck's live location off that shared API.
abstract class TruckRepository {
  /// Run a search and return matching trucks.
  Future<List<Truck>> search(TruckQuery query);

  /// Look up a single truck by id (for the detail screen / deep links).
  Future<Truck?> byId(String id);

  /// Live location stream for tracking a truck on the map.
  Stream<LatLng> trackLocation(Truck truck);

  /// How many trucks are empty right now near the user (home banner).
  Future<int> emptyNowCount();
}

/// Live implementation backed by the FreightDesk REST API
/// (`GET /api/trucks`). Works on mobile and web.
class RestTruckRepository implements TruckRepository {
  RestTruckRepository(this._api);

  final ApiClient _api;

  // Small cache so the home banner / saved lists don't re-hit the API.
  List<Truck>? _lastFetch;

  Future<List<Truck>> _fetchAll() async {
    final data = await _api.getJson('/api/trucks', {'limit': 100});
    final list = (data as List)
        .whereType<Map>()
        .map((e) => Truck.fromJson(e.cast<String, dynamic>()))
        .toList();
    _lastFetch = list;
    return list;
  }

  @override
  Future<List<Truck>> search(TruckQuery q) async {
    final all = await _fetchAll();
    return all.where((t) {
      if (q.emptyOnly && t.availability == Availability.loaded) return false;
      if (q.verifiedOnly && !t.verifiedByMaalgaadi) return false;
      return true;
    }).toList();
  }

  @override
  Future<Truck?> byId(String id) async {
    try {
      final data = await _api.getJson('/api/trucks/$id');
      return Truck.fromJson((data as Map).cast<String, dynamic>());
    } catch (_) {
      return (_lastFetch ?? await _fetchAll())
          .where((t) => t.id == id)
          .firstOrNull;
    }
  }

  @override
  Future<int> emptyNowCount() async {
    final all = _lastFetch ?? await _fetchAll();
    return all.where((t) => t.availability == Availability.empty).length;
  }

  @override
  Stream<LatLng> trackLocation(Truck truck) async* {
    yield truck.location;
    if (!truck.hasLiveLocation) return;
    // Re-poll the truck record; emit when its coordinates move.
    var last = truck.location;
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 5));
      final fresh = await byId(truck.id);
      final p = fresh?.location;
      if (p != null && (p.latitude != last.latitude || p.longitude != last.longitude)) {
        last = p;
        yield p;
      }
    }
  }
}

/// In-memory repository mirroring the wireframe's sample data. Useful for UI
/// work offline; truck positions drift so the detail map shows live tracking.
class MockTruckRepository implements TruckRepository {
  MockTruckRepository();

  final _rng = Random(7);

  static final List<Truck> _trucks = [
    Truck(
      id: 't1',
      plate: 'MH 12 AB 4471',
      wheels: '10',
      body: 'Open',
      availability: Availability.empty,
      area: 'Hadapsar',
      distanceKm: '4.2 km',
      updated: '20 min ago',
      driverName: 'Suresh K.',
      driverInitials: 'SK',
      phone: '+919988765432',
      location: const LatLng(18.5018, 73.9407),
    ),
    Truck(
      id: 't2',
      plate: 'MH 14 KP 2203',
      wheels: '12',
      body: 'Container',
      availability: Availability.empty,
      area: 'Wakad',
      distanceKm: '8.1 km',
      updated: '35 min ago',
      driverName: 'Imran S.',
      driverInitials: 'IS',
      phone: '+919812345678',
      location: const LatLng(18.5985, 73.7625),
    ),
    Truck(
      id: 't3',
      plate: 'GJ 05 CT 9023',
      wheels: '6',
      body: 'Tipper',
      availability: Availability.soon,
      area: 'Kharadi',
      distanceKm: '6.0 km',
      updated: '1 hr ago',
      driverName: 'Ramesh P.',
      driverInitials: 'RP',
      phone: '+919900112233',
      location: const LatLng(18.5515, 73.9430),
    ),
    Truck(
      id: 't4',
      plate: 'KA 03 MF 7762',
      wheels: '14',
      body: 'Trailer',
      availability: Availability.empty,
      area: 'Chinchwad',
      distanceKm: '12 km',
      updated: '2 hr ago',
      driverName: 'Anil G.',
      driverInitials: 'AG',
      phone: '+919765432100',
      location: const LatLng(18.6298, 73.7997),
    ),
    Truck(
      id: 't5',
      plate: 'RJ 14 GH 1180',
      wheels: '16+',
      body: 'Tanker',
      availability: Availability.loaded,
      area: 'Hinjawadi',
      distanceKm: '14 km',
      updated: '3 hr ago',
      driverName: 'Vikram J.',
      driverInitials: 'VJ',
      phone: '+919654321098',
      location: const LatLng(18.5912, 73.7380),
    ),
  ];

  @override
  Future<List<Truck>> search(TruckQuery q) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _trucks.where((t) {
      if (q.emptyOnly && t.availability == Availability.loaded) return false;
      if (q.verifiedOnly && !t.verifiedByMaalgaadi) return false;
      return true;
    }).toList();
  }

  @override
  Future<Truck?> byId(String id) async =>
      _trucks.where((t) => t.id == id).firstOrNull;

  @override
  Future<int> emptyNowCount() async => 1240;

  @override
  Stream<LatLng> trackLocation(Truck truck) async* {
    var pos = truck.location;
    yield pos;
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 3));
      final dLat = (_rng.nextDouble() - 0.5) * 0.0018;
      final dLng = (_rng.nextDouble() - 0.5) * 0.0018;
      pos = LatLng(pos.latitude + dLat, pos.longitude + dLng);
      yield pos;
    }
  }
}
