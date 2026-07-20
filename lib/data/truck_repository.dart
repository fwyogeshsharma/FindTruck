import 'dart:async';
import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../models/truck.dart';
import 'api_client.dart';

/// Source of truck data. The truckfinder app reads the FreightDesk truck
/// database and tracks a truck's live location off that shared API.
abstract class TruckRepository {
  /// Run a search and return matching trucks. When [limit] is set, fetching
  /// stops once that many rows have been read from the API (used by the
  /// dashboard to load a bounded, recent page instead of the whole table).
  Future<List<Truck>> search(TruckQuery query, {int? limit});

  /// Incremental version of [search] for the results list: returns a pager that
  /// yields the first few matches quickly and fetches the rest on scroll,
  /// instead of downloading the whole table before painting anything.
  TruckPager pager(TruckQuery query);

  /// Distinct city/area names known to the data source, sorted — powers the
  /// location autocomplete on the Find Vehicle screen.
  Future<List<String>> cities();

  /// Look up a single truck by id (for the detail screen / deep links).
  Future<Truck?> byId(String id);

  /// Live location stream for tracking a truck on the map.
  Stream<LatLng> trackLocation(Truck truck);

  /// How many trucks are empty right now near the user (home banner).
  Future<int> emptyNowCount();
}

/// Pull-based pager over a filtered truck search.
///
/// The API can only filter by location (`?q=`); wheels/body/axle/availability
/// are applied client-side, so a 50-row server page can yield zero matches.
/// [loadMore] therefore keeps pulling server pages until it has collected
/// [want] matches, its scan budget for this call runs out, or the table ends —
/// which is what lets the list paint after one round-trip instead of ~150.
class TruckPager {
  TruckPager({
    required this.fetchPage,
    required this.matches,
    this.pageSize = 50,
    this.scanBudget = 8,
  });

  /// Reads one raw (unfiltered) server page.
  final Future<List<Truck>> Function(int offset, int limit) fetchPage;

  /// Client-side filter predicate for the active query.
  final bool Function(Truck truck) matches;

  final int pageSize;

  /// Max server pages read in a single [loadMore] call, so one call can never
  /// block on scanning the whole table when the filter is very selective.
  final int scanBudget;

  /// Matches found so far, in server order.
  final List<Truck> items = [];

  int _offset = 0;
  bool _exhausted = false;
  bool _loading = false;

  /// False once the server has no more rows — only then is [items] complete.
  bool get hasMore => !_exhausted;
  bool get isLoading => _loading;

  /// Pulls pages until [want] new matches are found. Returns how many were
  /// added; 0 with [hasMore] still true means "scanned, all misses, ask again".
  Future<int> loadMore({int want = 10}) async {
    if (_loading || _exhausted) return 0;
    _loading = true;
    var added = 0;
    try {
      for (var scanned = 0; scanned < scanBudget && !_exhausted; scanned++) {
        final rows = await fetchPage(_offset, pageSize);
        _offset += rows.length;
        if (rows.length < pageSize) _exhausted = true; // last page reached
        for (final t in rows) {
          if (matches(t)) {
            items.add(t);
            added++;
          }
        }
        if (added >= want) break;
      }
    } finally {
      _loading = false;
    }
    return added;
  }
}

/// Whether [t] satisfies [q]. [loc] is the trimmed query location, passed in so
/// callers that already computed it don't redo the work per row.
bool _matchesQuery(Truck t, TruckQuery q, String loc) {
  // Exact city match. The server `?q=` is a substring search, so a query
  // like "Agra" also returns "Prayagraj" (…pray·agra·j); pin it to the
  // truck's actual city so only that city's trucks show.
  if (loc.isNotEmpty && t.area.trim().toLowerCase() != loc.toLowerCase()) {
    return false;
  }
  if (q.emptyOnly && t.availability == Availability.loaded) return false;
  if (q.verifiedOnly && !t.verifiedByMaalgaadi) return false;
  if (q.wheels != 'Any' && !RestTruckRepository._wheelsMatch(t.wheels, q.wheels)) {
    return false;
  }
  if (q.body != 'Any' && !t.body.toLowerCase().contains(q.body.toLowerCase())) {
    return false;
  }
  if (q.axle != 'Any' && t.axle.toLowerCase() != q.axle.toLowerCase()) {
    return false;
  }
  return true;
}

/// Distinct, sorted city names from [trucks], skipping blanks/placeholders.
/// Case-insensitive de-dup, keeping the first-seen spelling for display.
List<String> _distinctCities(Iterable<Truck> trucks) {
  final byLower = <String, String>{};
  for (final t in trucks) {
    final city = t.area.trim();
    if (city.isEmpty || city == '—') continue;
    byLower.putIfAbsent(city.toLowerCase(), () => city);
  }
  final list = byLower.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return list;
}

/// Live implementation backed by the FreightDesk REST API
/// (`GET /api/trucks`). Works on mobile and web.
class RestTruckRepository implements TruckRepository {
  RestTruckRepository(this._api);

  final ApiClient _api;

  // The API caps `limit` at 200, but large pages make the server drop the
  // connection mid-transfer ("Connection closed while receiving data"), so we
  // request smaller pages to keep each response light.
  static const _pageSize = 50;
  // Safety bound so a runaway dataset can't loop forever. Sized to cover the
  // full table with headroom (50 * 400 = 20000 rows).
  static const _maxPages = 400;

  // Small cache of the full (unfiltered) fetch so the home banner / saved
  // lists / dashboard don't re-hit the API. Only the no-query fetch is cached.
  List<Truck>? _lastFetch;

  /// Fetches every truck by paging through the API. When [q] is set it is sent
  /// as the server-side free-text query (`?q=`) and results are not cached.
  Future<List<Truck>> _fetchAll({String? q, int? maxRows}) async {
    final all = <Truck>[];
    for (var page = 0; page < _maxPages; page++) {
      final rows = await _fetchPage(page * _pageSize, _pageSize, q: q);
      all.addAll(rows);
      if (rows.length < _pageSize) break; // last page reached
      if (maxRows != null && all.length >= maxRows) break; // caller's cap hit
    }
    // Only the complete, unfiltered fetch is worth caching for reuse.
    if ((q == null || q.isEmpty) && maxRows == null) _lastFetch = all;
    return all;
  }

  /// Reads a single raw page from the API.
  Future<List<Truck>> _fetchPage(int offset, int limit, {String? q}) async {
    final data = await _api.getJson('/api/trucks', {
      'limit': limit,
      'offset': offset,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return (data as List)
        .whereType<Map>()
        .map((e) => Truck.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<Truck>> search(TruckQuery q, {int? limit}) async {
    final loc = q.location.trim();
    final all = await _fetchAll(q: loc.isEmpty ? null : loc, maxRows: limit);
    return all.where((t) => _matchesQuery(t, q, loc)).toList();
  }

  @override
  TruckPager pager(TruckQuery q) {
    final loc = q.location.trim();
    return TruckPager(
      pageSize: _pageSize,
      fetchPage: (offset, limit) =>
          _fetchPage(offset, limit, q: loc.isEmpty ? null : loc),
      matches: (t) => _matchesQuery(t, q, loc),
    );
  }

  /// Matches a truck's wheel count against a filter value. '16+' means 16 or
  /// more; otherwise an exact match on the numeric count.
  static bool _wheelsMatch(String truckWheels, String filter) {
    if (filter.endsWith('+')) {
      final min = int.tryParse(filter.replaceAll('+', ''));
      final w = int.tryParse(truckWheels);
      return min != null && w != null && w >= min;
    }
    return truckWheels == filter;
  }

  @override
  Future<List<String>> cities() async {
    final all = _lastFetch ?? await _fetchAll();
    return _distinctCities(all);
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
      phones: const [
        TruckPhone('+919988765432', 'Driver'),
        TruckPhone('+919820011223', 'Reporter · Maalgaadi desk'),
      ],
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
      phones: const [TruckPhone('+919812345678', 'Driver')],
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
      phones: const [TruckPhone('+919900112233', 'Driver')],
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
      phones: const [TruckPhone('+919765432100', 'Driver')],
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
      phones: const [TruckPhone('+919654321098', 'Driver')],
      location: const LatLng(18.5912, 73.7380),
    ),
  ];

  @override
  Future<List<Truck>> search(TruckQuery q, {int? limit}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final loc = q.location.trim();
    final res = _trucks.where((t) => _matchesQuery(t, q, loc)).toList();
    return (limit != null && res.length > limit) ? res.sublist(0, limit) : res;
  }

  @override
  TruckPager pager(TruckQuery q) {
    final loc = q.location.trim();
    return TruckPager(
      pageSize: 2, // small pages so the paging path is exercised offline
      fetchPage: (offset, limit) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (offset >= _trucks.length) return const [];
        return _trucks.sublist(offset, min(offset + limit, _trucks.length));
      },
      matches: (t) => _matchesQuery(t, q, loc),
    );
  }

  @override
  Future<List<String>> cities() async => _distinctCities(_trucks);

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
