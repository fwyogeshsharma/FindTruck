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
  _Item(this.truck, {this.distanceKm, this.city, required this.inCity});
  final Truck truck;
  final double? distanceKm;
  final String? city;
  final bool inCity;

  Truck get display => distanceKm == null
      ? truck
      : truck.copyWith(distanceKm: '${distanceKm!.toStringAsFixed(1)} km');
}

class _DashboardData {
  _DashboardData(this.place, this.items);
  final PlaceResult place;
  final List<_Item> items;

  int get inCityCount => items.where((i) => i.inCity).length;
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
  late Future<_DashboardData> _future;
  bool _inCityOnly = true;

  /// How the vehicle list is ordered. Defaults to newest-added first so the
  /// latest truck reported to the API sits at the top.
  String _sortMode = 'latest'; // 'latest' | 'nearest'

  /// Id of the truck currently pinned/focused on the dashboard map, set by
  /// tapping a list item's thumbnail.
  String? _selectedId;

  /// Fallback map centre (Pune) when neither the device nor any truck has a fix.
  static const _fallbackCenter = LatLng(18.5204, 73.8567);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// How many recent vehicles the dashboard loads. Bounded so the page loads
  /// fast and never times out fetching the entire (~7.5k row) table.
  static const _fetchLimit = 200;

  Future<_DashboardData> _load() async {
    final repo = context.read<AppState>().repo;
    // Recent vehicles, unfiltered and newest-first (this is a dashboard, not a
    // search). Bounded to a page so it loads quickly instead of the whole table.
    final all = await repo.search(
        const TruckQuery(emptyOnly: false, verifiedOnly: false),
        limit: _fetchLimit);
    final place = await _location.currentPlace();

    final items = <_Item>[];
    for (final t in all) {
      double? dist;
      bool inCity = false;
      if (place.ok && t.hasLiveLocation) {
        final p = place.position!;
        dist = _location.distanceKm(
            p.latitude, p.longitude, t.location.latitude, t.location.longitude);
        // "In my city" = within ~50 km. We match by distance rather than
        // reverse-geocoding each truck's city name: a per-truck geocode ran
        // serially over the whole list and was blowing past the request
        // timeout ("Future not completed").
        inCity = dist <= 50;
      }
      items.add(_Item(t, distanceKm: dist, city: null, inCity: inCity));
    }
    return _DashboardData(place, items);
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

  /// The most recently added vehicle across the whole (unfiltered) dataset.
  _Item? _latestOf(List<_Item> items) {
    _Item? best;
    for (final i in items) {
      final t = i.truck.createdAt;
      if (t == null) continue;
      if (best == null || t.isAfter(best.truck.createdAt!)) best = i;
    }
    return best;
  }

  Future<void> _refresh() async {
    final data = await _load();
    if (mounted) setState(() => _future = Future.value(data));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(),
        Expanded(
          child: FutureBuilder<_DashboardData>(
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
          FutureBuilder<_DashboardData>(
            future: _future,
            builder: (context, snap) {
              final place = snap.data?.place;
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

  Widget _body(_DashboardData data) {
    final place = data.place;
    final hasCity = place.ok && place.city != null;
    final showInCity = _inCityOnly && place.ok;
    final filtered = showInCity
        ? data.items.where((i) => i.inCity).toList()
        : data.items;
    final list = _sorted(filtered);

    // The single newest-added vehicle, highlighted at the top of the list.
    final latest = _latestOf(data.items);

    // Trucks with a real GPS fix from the API — these get map markers.
    final located = list.where((i) => i.truck.hasLiveLocation).toList();

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _refresh,
      child: ListView(
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
          // Latest-added vehicle, always pinned to the top.
          if (latest != null) ...[
            _latestCard(latest),
            const SizedBox(height: 14),
          ],
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
                                : ' vehicles total · ${data.inCityCount} nearby'),
                      ],
                    ),
                  ),
                ),
                if (place.ok) ...[
                  Text('In my city',
                      style:
                          AppText.sans(size: 12.5, weight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  AppToggle(
                      on: _inCityOnly,
                      onChanged: (v) => setState(() => _inCityOnly = v)),
                ],
              ],
            ),
          ),
          // Sort control: newest-added vs nearest.
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text('Sort',
                    style: AppText.sans(
                        size: 12.5, weight: FontWeight.w700, color: AppColors.muted)),
                const SizedBox(width: 10),
                _sortChip('Latest', 'latest'),
                const SizedBox(width: 8),
                _sortChip('Nearest', 'nearest'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (list.isEmpty)
            _empty(hasCity ? place.city! : 'your area')
          else
            for (final item in list) ...[
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
        ],
      ),
    );
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
                interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
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
                    for (final item in located)
                      _truckMarker(item, item.truck.id == _selectedId),
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
                    Text('${located.length} on map',
                        style:
                            AppText.sans(size: 11.5, weight: FontWeight.w700)),
                  ],
                ),
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

  /// A pill toggle for the list sort mode.
  Widget _sortChip(String label, String mode) {
    final on = _sortMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _sortMode = mode),
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

  /// Highlight card for the most recently added vehicle.
  Widget _latestCard(_Item item) {
    final t = item.display;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TruckDetailScreen(truck: item.truck))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon('bolt', size: 15, color: AppColors.accent),
                const SizedBox(width: 6),
                Text('LATEST ADDED',
                    style: AppText.sans(
                        size: 11,
                        weight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.accent)),
                const Spacer(),
                Text('Added ${t.updated}',
                    style: AppText.sans(size: 11.5, color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(t.plate,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.sans(
                                    size: 17, weight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 6),
                          const Verified(sm: true),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                          '${t.wheels}-wheel · ${t.body}'
                          '${t.axle != '—' ? ' · ${t.axle}' : ''}',
                          style: AppText.sans(
                              size: 12.5,
                              weight: FontWeight.w600,
                              color: AppColors.muted)),
                      const SizedBox(height: 3),
                      Text('Driver: ${t.driverName}',
                          style: AppText.sans(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: AppColors.ink)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AvailChip(t.availability, sm: true),
              ],
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          AppIcon('truck', size: 40, color: AppColors.line),
          const SizedBox(height: 12),
          Text('No vehicles in $where right now',
              style: AppText.sans(weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Turn off “In my city” to see all vehicles.',
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
