import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
  late Future<_DashboardData> _future;
  bool _inCityOnly = true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final repo = context.read<AppState>().repo;
    // All vehicles, unfiltered (this is a dashboard, not a search).
    final all = await repo.search(
        const TruckQuery(emptyOnly: false, verifiedOnly: false));
    final place = await _location.currentPlace();

    final items = <_Item>[];
    for (final t in all) {
      double? dist;
      String? city;
      bool inCity = false;
      if (place.ok && t.hasLiveLocation) {
        final p = place.position!;
        dist = _location.distanceKm(
            p.latitude, p.longitude, t.location.latitude, t.location.longitude);
        city = await _location.cityFor(t.location.latitude, t.location.longitude);
        final sameName = city != null &&
            place.city != null &&
            city.toLowerCase() == place.city!.toLowerCase();
        // "In my city" = same city name, or within ~50 km when names are absent.
        inCity = sameName || dist <= 50;
      }
      items.add(_Item(t, distanceKm: dist, city: city, inCity: inCity));
    }
    items.sort((a, b) =>
        (a.distanceKm ?? 1e9).compareTo(b.distanceKm ?? 1e9));
    return _DashboardData(place, items);
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
    final list = showInCity
        ? data.items.where((i) => i.inCity).toList()
        : data.items;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
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
          const SizedBox(height: 6),
          if (list.isEmpty)
            _empty(hasCity ? place.city! : 'your area')
          else
            for (final item in list) ...[
              TruckRow(
                truck: item.display,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TruckDetailScreen(truck: item.truck))),
                onCall: () => showCallSheet(context, item.truck),
              ),
              const SizedBox(height: 10),
            ],
        ],
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
