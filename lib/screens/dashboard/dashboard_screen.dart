import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/location_service.dart';
import '../../models/truck.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/finder_widgets.dart';
import '../../widgets/kit.dart';
import '../truck/call_sheet.dart';
import '../truck/truck_detail_screen.dart';

/// A vehicle on the dashboard, enriched with the user-relative distance and a
/// reverse-geocoded city so it can be matched to the user's location.
class _Item {
  _Item(this.truck, {this.distanceKm, required this.inCity});
  final Truck truck;
  final double? distanceKm;
  final bool inCity;

  Truck get display => distanceKm == null
      ? truck
      : truck.copyWith(distanceKm: '${distanceKm!.toStringAsFixed(1)} km');
}

/// Bounding box of mainland India (plus islands), used to frame the map when
/// the user turns "In my city" off and wants the country-wide picture.
final _indiaBounds = LatLngBounds(
  const LatLng(6.5, 68.0),
  const LatLng(35.6, 97.5),
);

/// A group of trucks collapsed into one map marker at the current zoom.
class _Cluster {
  _Cluster(this.center, this.trucks);
  final LatLng center;
  final List<Truck> trucks;

  int get count => trucks.length;
  bool get isSingle => trucks.length == 1;

  /// The dominant place name in the group, used to label the cluster.
  String get label {
    final tally = <String, int>{};
    for (final t in trucks) {
      final a = t.area.trim();
      if (a.isNotEmpty && a != '—') tally[a] = (tally[a] ?? 0) + 1;
    }
    if (tally.isEmpty) return '';
    var best = '';
    var bestN = 0;
    tally.forEach((k, v) {
      if (v > bestN) {
        best = k;
        bestN = v;
      }
    });
    return best;
  }
}

/// Screen-space spacing between cluster centres, in logical pixels. Larger =
/// fewer, fatter clusters.
const _clusterPx = 64.0;

/// Buckets [trucks] into a lat/lng grid whose cell size tracks [zoom], so one
/// badge reads "250" over Jaipur when zoomed out and splits into per-locality
/// counts as you zoom in.
///
/// Grid bucketing (rather than distance-based agglomeration) is deliberate: it
/// is a single O(n) pass, which matters because the map holds the whole ~7.7k
/// row table and re-clusters on every zoom change.
List<_Cluster> _clusterTrucks(List<Truck> trucks, double zoom) {
  // Web-Mercator: the world is 256 * 2^zoom px wide and spans 360 degrees.
  final degPerPx = 360.0 / (256.0 * math.pow(2.0, zoom));
  final cell = _clusterPx * degPerPx;
  if (cell <= 0 || !cell.isFinite) {
    return [for (final t in trucks) _Cluster(t.location, [t])];
  }

  final buckets = <int, List<Truck>>{};
  for (final t in trucks) {
    final gx = (t.location.longitude / cell).floor();
    final gy = (t.location.latitude / cell).floor();
    // Pack the 2-D cell index into one int key — cheaper than string keys on
    // a hot path that runs over every row on each zoom change.
    buckets.putIfAbsent((gx << 20) ^ (gy & 0xFFFFF), () => []).add(t);
  }

  final out = <_Cluster>[];
  for (final group in buckets.values) {
    var lat = 0.0, lng = 0.0;
    for (final t in group) {
      lat += t.location.latitude;
      lng += t.location.longitude;
    }
    out.add(_Cluster(LatLng(lat / group.length, lng / group.length), group));
  }
  // Draw the big groups last so their badges sit on top of the small ones.
  out.sort((a, b) => a.count.compareTo(b.count));
  return out;
}

/// Vehicle dashboard — lists every vehicle from FreightDesk, detects the
/// device's city via GPS, and filters to trucks in that city.
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _location = LocationService();
  final _mapController = MapController();
  final _scroll = ScrollController();
  late Future<PlaceResult> _future;
  bool _inCityOnly = true;

  /// Load-status filter for the list: all vehicles, only empty ones (available
  /// to book), or only loaded ones. 'all' | 'empty' | 'loaded'.
  String _loadFilter = 'all';

  /// When on, the list is narrowed to the [_recentPickLimit] empty vehicles
  /// reported near the user in the last [_recentWindow]. Driven by the shortcut
  /// card at the top of the dashboard.
  bool _recentEmptyOnly = false;

  /// How fresh a report must be to count as "just added".
  static const _recentWindow = Duration(hours: 24);

  /// How many vehicles the shortcut surfaces.
  static const _recentPickLimit = 5;

  /// The empty vehicles reported near the user inside [_recentWindow], newest
  /// first, capped at [_recentPickLimit].
  ///
  /// [items] is already narrowed by the "In my city" toggle, so this inherits
  /// whatever the user has chosen as "near me" rather than defining its own.
  List<_Item> _recentEmptyPicks(List<_Item> items) {
    final cutoff = DateTime.now().toUtc().subtract(_recentWindow);
    final picks = items.where((i) {
      if (i.truck.availability != Availability.empty) return false;
      final added = i.truck.createdAt;
      return added != null && added.toUtc().isAfter(cutoff);
    }).toList()
      ..sort((a, b) => b.truck.createdAt!.compareTo(a.truck.createdAt!));
    return picks.take(_recentPickLimit).toList();
  }

  /// How the vehicle list is ordered. Defaults to newest-added first so the
  /// latest truck reported to the API sits at the top.
  String _sortMode = 'latest'; // 'latest' | 'nearest'

  /// Id of the truck currently pinned/focused on the dashboard map, set by
  /// tapping a list item's thumbnail.
  String? _selectedId;

  /// Fallback map centre (Pune) when neither the device nor any truck has a fix.
  static const _fallbackCenter = LatLng(18.5204, 73.8567);

  /// The whole table, enriched with distance/near-me, filled in progressively
  /// as pages land. Single source of truth for the map, the counts and the
  /// list, so the chips read the real database totals rather than the size of
  /// one fetched page.
  List<_Item> _items = const [];
  bool _loadingAll = true;
  PlaceResult? _place;

  // Sorting 7k+ rows on every rebuild (each arriving batch, every scroll tick)
  // is enough to drop frames, so the ordered list is cached and only recomputed
  // when something it depends on actually changes.
  List<_Item> _view = const [];
  String _viewKey = '';

  /// How many rows of [_items] the list currently renders. Grows as the user
  /// scrolls so 7k+ rows don't all build at once.
  int _visible = _pageStep;
  static const _pageStep = 15;

  /// Current map zoom, tracked so clusters re-bucket as the user zooms.
  double _zoom = 12;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _scroll.addListener(_onScroll);
  }

  /// Grows the rendered window as the list nears its end.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent - 600) {
      if (_visible < _items.length) {
        setState(() => _visible += _pageStep);
      }
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// How many recent vehicles the dashboard loads. Bounded so the page loads
  /// Resolves the device location, then streams the whole table in behind it.
  ///
  /// The future completes on the *first* batch so the dashboard paints in a
  /// couple of seconds; later batches arrive via [setState]. Nearness is judged
  /// from coordinates rather than a server-side `?q=<city>` search, which means
  /// the counts are true database totals and a geocoded city name that doesn't
  /// match the data's spelling can no longer hide every nearby vehicle.
  Future<PlaceResult> _load() async {
    final repo = context.read<AppState>().repo;
    final place = await _location.currentPlace();

    final firstBatch = Completer<void>();
    _loadingAll = true;
    _place = place;

    void publish(List<Truck> trucks) {
      final items = [for (final t in trucks) _itemFor(t, place)];
      if (mounted) setState(() => _items = items);
      if (!firstBatch.isCompleted && trucks.isNotEmpty) firstBatch.complete();
    }

    unawaited(repo.allTrucks(onBatch: publish).then((all) {
      publish(all);
      if (mounted) setState(() => _loadingAll = false);
      if (!firstBatch.isCompleted) firstBatch.complete();
    }).onError((Object e, _) {
      if (mounted) setState(() => _loadingAll = false);
      // Surface the failure only if nothing painted yet; once a batch has
      // landed a later page failing shouldn't blank the dashboard.
      if (!firstBatch.isCompleted) firstBatch.completeError(e);
    }));

    await firstBatch.future;
    return place;
  }

  /// Wraps a truck with its distance from the user and whether it counts as
  /// "in my city" (~50 km).
  ///
  /// Distance rather than per-truck reverse geocoding: geocoding each row ran
  /// serially over the list and blew past the request timeout ("Future not
  /// completed").
  _Item _itemFor(Truck t, PlaceResult place) {
    if (!place.ok || !t.hasLiveLocation) {
      return _Item(t, inCity: false);
    }
    final p = place.position!;
    final dist = _location.distanceKm(
        p.latitude, p.longitude, t.location.latitude, t.location.longitude);
    return _Item(t, distanceKm: dist, inCity: dist <= 50);
  }

  /// Orders the list per [_sortMode]: newest-added first, or nearest first.
  List<_Item> _sorted(List<_Item> items) {
    final list = [...items];
    if (_sortMode == 'nearest') {
      list.sort(
          (a, b) => (a.distanceKm ?? 1e9).compareTo(b.distanceKm ?? 1e9));
    } else {
      // Latest added first — items without a timestamp fall to the bottom.
      list.sort((a, b) {
        final ax = a.truck.createdAt, bx = b.truck.createdAt;
        if (ax == null && bx == null) return 0;
        if (ax == null) return 1;
        if (bx == null) return -1;
        return bx.compareTo(ax);
      });
    }
    return list;
  }


  Future<void> _refresh() async {
    setState(() {
      _visible = _pageStep;
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(),
        Expanded(
          child: FutureBuilder<PlaceResult>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent));
              }
              if (snap.hasError) {
                return _message('Could not load vehicles.\n${snap.error}');
              }
              return _body(snap.data!);
            },
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vehicle dashboard',
                    style: AppText.sans(
                        size: 22, weight: FontWeight.w800, letterSpacing: -0.4)),
                Text('सभी गाड़ियाँ', style: AppText.deva(size: 12.5)),
              ],
            ),
          ),
          FutureBuilder<PlaceResult>(
            future: _future,
            builder: (context, snap) {
              final place = snap.data;
              final locating = snap.connectionState != ConnectionState.done;
              return GestureDetector(
                onTap: _refresh,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon('pin', size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                          locating
                              ? 'Locating…'
                              : (place?.ok ?? false)
                                  ? (place!.city ?? 'Located')
                                  : 'No location',
                          style:
                              AppText.sans(size: 13, weight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      AppIcon('refresh', size: 14, color: AppColors.muted),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _body(PlaceResult place) {
    final hasCity = place.ok && place.city != null;
    final showInCity = _inCityOnly && place.ok;
    final inArea =
        showInCity ? _items.where((i) => i.inCity).toList() : _items;
    final nearbyCount =
        showInCity ? inArea.length : _items.where((i) => i.inCity).length;

    // Counts are taken before the load filter is applied so each chip shows how
    // many vehicles it would reveal, not how many are currently shown.
    int countOf(Availability a) =>
        inArea.where((i) => i.truck.availability == a).length;
    final emptyCount = countOf(Availability.empty);
    final loadedCount = countOf(Availability.loaded);
    // Records with no `loaded_status` from the API land here (Truck._availability
    // defaults to `soon`). That is a large share of the table, so it gets its
    // own chip rather than being invisible under both Empty and Loaded.
    final soonCount = countOf(Availability.soon);

    final filtered = switch (_loadFilter) {
      'empty' => inArea
          .where((i) => i.truck.availability == Availability.empty)
          .toList(),
      'loaded' => inArea
          .where((i) => i.truck.availability == Availability.loaded)
          .toList(),
      'soon' => inArea
          .where((i) => i.truck.availability == Availability.soon)
          .toList(),
      _ => inArea,
    };
    // The shortcut overrides the load chips — the two would otherwise fight
    // (e.g. "Loaded" selected while the shortcut asks for empty ones).
    final recentEmpty = _recentEmptyPicks(inArea);

    // Cached: re-sorting the full table on every scroll tick drops frames.
    final key = '${_items.length}|$showInCity|$_loadFilter|$_sortMode'
        '|$_recentEmptyOnly';
    if (key != _viewKey) {
      _view = _sorted(_recentEmptyOnly ? recentEmpty : filtered);
      _viewKey = key;
    }
    final list = _view;

    // Trucks with a real GPS fix from the API — these get map markers.
    final located = list.where((i) => i.truck.hasLiveLocation).toList();

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _refresh,
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          if (located.isNotEmpty) ...[
            _map(located, place),
            const SizedBox(height: 12),
          ],
          if (!place.ok)
            _notice(
                'Showing all vehicles. ${place.error ?? 'Location unavailable.'} Tap the location chip to retry.',
                AppColors.warn,
                AppColors.warnBg),
          if (place.ok && !hasCity)
            _notice(
                kIsWeb
                    ? 'Got your location. City names need the mobile app, so vehicles are matched within ~50 km.'
                    : 'Got your location but could not name the city; matching within ~50 km.',
                AppColors.accent,
                AppColors.accentSoft),
          // "Empty, just added, near me" shortcut — the fastest path to a
          // bookable vehicle. Shown even at zero so the filter is discoverable
          // and explains why it's empty instead of silently disappearing.
          _recentEmptyCard(recentEmpty.length),
          const SizedBox(height: 14),
          // Count + filter toggle.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppText.sans(size: 13.5, color: AppColors.muted),
                      children: [
                        TextSpan(
                            text: '${list.length}',
                            style: AppText.sans(
                                size: 13.5,
                                weight: FontWeight.w800,
                                color: AppColors.ink)),
                        TextSpan(
                            text: showInCity
                                ? ' vehicles in ${hasCity ? place.city : 'your area'}'
                                : ' vehicles total · $nearbyCount nearby'),
                        if (_loadingAll)
                          const TextSpan(text: ' · loading…'),
                      ],
                    ),
                  ),
                ),
                if (place.ok) ...[
                  Text('In my city',
                      style:
                          AppText.sans(size: 12.5, weight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  AppToggle(on: _inCityOnly, onChanged: _setInCityOnly),
                ],
              ],
            ),
          ),
          // One control strip: sort modes and the load-status filter sit in the
          // same scrollable row, separated by a hairline so it still reads as
          // "order by" vs "show only".
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text('Sort',
                    style: AppText.sans(
                        size: 12.5, weight: FontWeight.w700, color: AppColors.muted)),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _sortChip('Latest', 'latest'),
                        const SizedBox(width: 8),
                        _sortChip('Nearest', 'nearest'),
                        Container(
                          width: 1,
                          height: 18,
                          color: AppColors.line,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        _loadChip('All', 'all', inArea.length),
                        const SizedBox(width: 8),
                        _loadChip('Empty now', 'empty', emptyCount),
                        const SizedBox(width: 8),
                        _loadChip('Loaded', 'loaded', loadedCount),
                        const SizedBox(width: 8),
                        _loadChip('Empty soon', 'soon', soonCount),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (list.isEmpty && !_loadingAll)
            _empty(hasCity ? place.city! : 'your area')
          else ...[
            // Only the scrolled-to window is built; [_onScroll] extends it.
            for (final item in list.take(_visible)) ...[
              TruckRow(
                truck: item.display,
                selected: _selectedId == item.truck.id,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TruckDetailScreen(truck: item.truck))),
                onThumbTap: item.truck.hasLiveLocation
                    ? () => _focusOnMap(item.truck)
                    : null,
                onCall: () => showCallSheet(context, item.truck),
              ),
              const SizedBox(height: 10),
            ],
            if (_visible < list.length || _loadingAll)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loadingAll
                            ? 'Loading vehicles…'
                            : 'Showing ${list.take(_visible).length} of ${list.length}',
                        style:
                            AppText.sans(size: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Flips the "In my city" filter and re-frames the map to match: the user's
  /// surroundings when on, the whole of India when off.
  void _setInCityOnly(bool v) {
    setState(() {
      _inCityOnly = v;
      // The visible set changed underneath the list, so start the window over
      // rather than leaving the user deep inside a list that just shrank.
      _visible = _pageStep;
      _selectedId = null;
    });
    _frameMap(v);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  /// Fits the map to the user's area or to all of India.
  ///
  /// Deferred to after the frame because the toggle can change before the map
  /// has laid out, and [MapController] throws if it is driven before then.
  void _frameMap(bool inCity) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final pos = _place?.position;
        if (inCity && pos != null) {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 11);
        } else {
          _mapController.fitCamera(CameraFit.bounds(
            bounds: _indiaBounds,
            padding: const EdgeInsets.all(14),
          ));
        }
        setState(() => _zoom = _mapController.camera.zoom);
      } catch (_) {
        // No map on screen yet (no located trucks) — nothing to frame.
      }
    });
  }

  /// Pins [truck] on the dashboard map and pans/zooms the map to it. Triggered
  /// by tapping the truck's thumbnail in the list.
  void _focusOnMap(Truck truck) {
    setState(() => _selectedId = truck.id);
    _mapController.move(truck.location, 15);
  }

  /// Dashboard overview map: every located truck as a marker, sourced from the
  /// API geolocation. The selected marker is enlarged; tapping any marker opens
  /// that truck's detail screen.
  Widget _map(List<_Item> located, PlaceResult place) {
    // Centre on the pinned truck, else the device, else the first truck.
    _Item? selected;
    for (final i in located) {
      if (i.truck.id == _selectedId) {
        selected = i;
        break;
      }
    }
    final center = selected?.truck.location ??
        (place.ok
            ? LatLng(place.position!.latitude, place.position!.longitude)
            : located.isNotEmpty
                ? located.first.truck.location
                : _fallbackCenter);

    // The map always shows every located vehicle in the table, independent of
    // the list's filters — the clusters are the country-wide picture.
    final mapTrucks = [
      for (final i in _items)
        if (i.truck.hasLiveLocation) i.truck,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 210,
        decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 12,
                // Bounded so the packed cluster-cell key below can't overflow
                // its 20-bit lat field (safe through zoom ~20).
                minZoom: 3,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
                // Re-bucket clusters as the user zooms. Gated on a meaningful
                // change so a pinch doesn't rebuild the grid every frame.
                onPositionChanged: (camera, _) {
                  if ((camera.zoom - _zoom).abs() >= 0.4) {
                    setState(() => _zoom = camera.zoom);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.faberwork.truckfinder',
                ),
                // The device's own position, if known.
                if (place.ok)
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(place.position!.latitude,
                          place.position!.longitude),
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                MarkerLayer(
                  markers: [
                    for (final c in _clusterTrucks(mapTrucks, _zoom))
                      _clusterMarker(c),
                  ],
                ),
              ],
            ),
            // Hint / count chip.
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon('pin', size: 13, color: AppColors.accent),
                    const SizedBox(width: 5),
                    Text('${mapTrucks.length} on map',
                        style:
                            AppText.sans(size: 11.5, weight: FontWeight.w700)),
                    if (_loadingAll) ...[
                      const SizedBox(width: 6),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.6),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One map marker for a [_Cluster]: a single truck renders as the usual pin,
  /// a group renders as a count badge that grows with the group size.
  Marker _clusterMarker(_Cluster c) {
    if (c.isSingle) {
      return _truckMarker(
          _Item(c.trucks.first, inCity: false), c.trucks.first.id == _selectedId);
    }
    // Badge grows with magnitude, not linearly with count — otherwise a 4000
    // cluster would swallow the viewport.
    final size = (30.0 + 9.0 * math.log(c.count) / math.ln10 * 2).clamp(34.0, 62.0);
    return Marker(
      point: c.center,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () => _onClusterTap(c),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.88),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: Center(
            child: Text(
              _compact(c.count),
              style: AppText.sans(
                  size: c.count >= 1000 ? 11.5 : 12.5,
                  weight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  /// 1240 -> '1.2k', so big counts stay inside the badge.
  static String _compact(int n) => n < 1000
      ? '$n'
      : '${(n / 1000).toStringAsFixed(n < 10000 ? 1 : 0)}k';

  /// Zooms into a cluster. Trucks reported at the same spot (common — a whole
  /// day's reports from one checkpoint share coordinates) never split no matter
  /// the zoom, so once we're at max zoom we list them instead.
  void _onClusterTap(_Cluster c) {
    if (_zoom >= 17.5) {
      _showClusterSheet(c);
      return;
    }
    final target = (_zoom + 2.5).clamp(3.0, 18.0);
    _mapController.move(c.center, target);
    setState(() => _zoom = target);
  }

  /// Bottom sheet listing the trucks inside a fully-zoomed cluster.
  void _showClusterSheet(_Cluster c) {
    final name = c.label;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  AppIcon('pin', size: 15, color: AppColors.accent),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      name.isEmpty
                          ? '${c.count} vehicles here'
                          : '${c.count} vehicles in $name',
                      style: AppText.sans(size: 14.5, weight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: c.trucks.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final t = c.trucks[i];
                  return ListTile(
                    dense: true,
                    title: Text(t.plate,
                        style:
                            AppText.sans(size: 13.5, weight: FontWeight.w700)),
                    subtitle: Text(
                      [t.wheels.isEmpty ? null : '${t.wheels}-wheel', t.body]
                          .whereType<String>()
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: AppText.sans(size: 11.5, color: AppColors.muted),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TruckDetailScreen(truck: t)));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A single truck pin. The selected one is larger and coloured; tapping opens
  /// the detail screen.
  Marker _truckMarker(_Item item, bool selected) {
    final size = selected ? 46.0 : 34.0;
    return Marker(
      point: item.truck.location,
      width: size,
      height: size,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedId = item.truck.id);
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TruckDetailScreen(truck: item.truck)));
        },
        child: AppIcon('pin',
            size: size,
            color: selected ? AppColors.accent : AppColors.muted),
      ),
    );
  }

  /// Tappable shortcut to the empty-and-just-added vehicles near the user.
  /// Acts as a toggle: tapping again clears the filter and restores the list.
  Widget _recentEmptyCard(int count) {
    final on = _recentEmptyOnly;
    final none = count == 0;
    return GestureDetector(
      onTap: none && !on
          ? null
          : () => setState(() {
                _recentEmptyOnly = !_recentEmptyOnly;
                // Leaving the load chips on would silently re-filter the list
                // the moment the shortcut is switched back off.
                if (_recentEmptyOnly) _loadFilter = 'all';
              }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: on ? AppColors.accent : AppColors.accentSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: on ? AppColors.accent : AppColors.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            AppIcon('truck',
                size: 18, color: on ? Colors.white : AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    none
                        ? 'No empty vehicles added in the last 24h'
                        : '$count empty ${count == 1 ? 'vehicle' : 'vehicles'} added in the last 24h',
                    style: AppText.sans(
                        size: 13.5,
                        weight: FontWeight.w800,
                        color: on ? Colors.white : AppColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    none
                        ? 'Newly reported empty vehicles near you will show up here.'
                        : on
                            ? 'Showing these only — tap to clear'
                            : 'Near you · tap to show only these',
                    style: AppText.sans(
                        size: 11.5,
                        color: on
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppColors.muted),
                  ),
                ],
              ),
            ),
            if (!none)
              Icon(on ? Icons.close : Icons.chevron_right,
                  size: 20, color: on ? Colors.white : AppColors.accent),
          ],
        ),
      ),
    );
  }

  /// A pill toggle for the list sort mode.
  Widget _sortChip(String label, String mode) =>
      _pill(label, _sortMode == mode, () => setState(() => _sortMode = mode));

  /// A pill toggle for the load-status filter, with the matching count.
  Widget _loadChip(String label, String mode, int count) => _pill(
      '$label ($count)', _loadFilter == mode && !_recentEmptyOnly, () {
    setState(() {
      _loadFilter = mode;
      // Picking a load filter is an explicit override of the shortcut.
      _recentEmptyOnly = false;
    });
  });

  /// Shared pill-chip styling for the sort and load-status rows.
  Widget _pill(String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: on ? AppColors.accent : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? AppColors.accent : AppColors.line),
        ),
        child: Text(label,
            style: AppText.sans(
                size: 12.5,
                weight: FontWeight.w700,
                color: on ? Colors.white : AppColors.ink)),
      ),
    );
  }

  Widget _notice(String text, Color fg, Color bg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          AppIcon('info', size: 18, color: fg),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text,
                style: AppText.sans(
                    size: 12.5, weight: FontWeight.w600, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }

  Widget _empty(String where) {
    // Point at whichever filter actually emptied the list, so the hint isn't
    // telling someone to change a toggle that wasn't the cause.
    final hint = _recentEmptyOnly
        ? 'Tap the “last 24h” card again to clear that filter.'
        : _loadFilter != 'all'
            ? 'Switch the Load filter back to “All” to see every vehicle.'
            : 'Turn off “In my city” to see all vehicles.';
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          AppIcon('truck', size: 40, color: AppColors.line),
          const SizedBox(height: 12),
          Text('No vehicles in $where right now',
              style: AppText.sans(weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(hint,
              style: AppText.sans(size: 12.5, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _message(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text,
              textAlign: TextAlign.center,
              style: AppText.sans(color: AppColors.muted)),
        ),
      );
}
