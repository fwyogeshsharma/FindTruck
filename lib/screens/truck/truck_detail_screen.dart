import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/truck.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/finder_widgets.dart';
import '../../widgets/kit.dart';
import 'call_sheet.dart';

/// 08 · Truck detail with photos, specs, **live location** and trust badge
/// (finderDetail.jsx `TruckDetail`). The map tracks the truck off the shared
/// maalgaadi API via [TruckRepository.trackLocation].
class TruckDetailScreen extends StatefulWidget {
  const TruckDetailScreen({super.key, required this.truck});
  final Truck truck;

  @override
  State<TruckDetailScreen> createState() => _TruckDetailScreenState();
}

class _TruckDetailScreenState extends State<TruckDetailScreen> {
  final _mapController = MapController();
  late final Stream<LatLng> _track =
      context.read<AppState>().repo.trackLocation(widget.truck);

  @override
  Widget build(BuildContext context) {
    final t = widget.truck;
    final state = context.watch<AppState>();
    final saved = state.isSaved(t.id);
    final specs = [
      ('Capacity', '${t.wheels}-wheel', 'truck'),
      ('Body type', t.body, 'grid'),
      ('Status', t.availability.label, 'bolt'),
    ];
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Photo carousel + overlay controls.
                Stack(
                  children: [
                    const Ph(height: 230, radius: 0, label: 'photo carousel'),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconBtn('back',
                              onDark: true, onTap: () => Navigator.pop(context)),
                          IconBtn(saved ? 'bookmark' : 'bookmark',
                              onDark: true,
                              onTap: () => state.toggleSaved(t.id)),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < t.photoCount; i++)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == 0 ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: i == 0
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(t.plate,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.sans(
                                          size: 22,
                                          weight: FontWeight.w800,
                                          letterSpacing: 0.5)),
                                ),
                                const SizedBox(width: 7),
                                const Verified(),
                              ],
                            ),
                          ),
                          AvailChip(t.availability),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          AppIcon('clock', size: 14, color: AppColors.muted),
                          const SizedBox(width: 5),
                          Text('Updated ${t.updated}',
                              style: AppText.sans(
                                  size: 12.5, color: AppColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          for (final s in specs) ...[
                            if (s != specs.first) const SizedBox(width: 9),
                            Expanded(child: _specCard(s.$1, s.$2, s.$3)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      _liveMap(t),
                      const SizedBox(height: 16),
                      _driverCard(t),
                      const SizedBox(height: 14),
                      _verifiedBanner(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          BottomBar(children: [
            Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => state.toggleSaved(t.id),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: AppColors.line),
                      backgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_border,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryBtn('Call driver',
                      icon: 'phone',
                      onTap: () => showCallSheet(context, t)),
                ),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  Widget _specCard(String label, String value, String icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          AppIcon(icon, size: 20, color: AppColors.accent),
          const SizedBox(height: 6),
          Text(value,
              textAlign: TextAlign.center,
              style: AppText.sans(size: 14, weight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(label,
              style:
                  AppText.sans(size: 10.5, weight: FontWeight.w600, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _liveMap(Truck t) {
    if (!t.hasLiveLocation) {
      // No GPS reported for this truck — show a labelled placeholder.
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Ph(height: 110, radius: 0, label: 'location · ${t.area}'),
            Positioned.fill(
              child: Center(
                child: AppIcon('pin', size: 30, color: AppColors.accent),
              ),
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
        height: 150,
        child: StreamBuilder<LatLng>(
          stream: _track,
          initialData: t.location,
          builder: (context, snap) {
            final pos = snap.data ?? t.location;
            // Keep the moving truck centred.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _mapController.move(pos, _mapController.camera.zoom);
            });
            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: pos,
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.faberwork.truckfinder',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: pos,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: AppIcon('pin', size: 36, color: AppColors.accent),
                      ),
                    ]),
                  ],
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
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
                        Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                                color: AppColors.ok, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Live · ${t.area}',
                            style: AppText.sans(
                                size: 11.5, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _driverCard(Truck t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
                color: AppColors.accentSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(t.driverInitials,
                style: AppText.sans(
                    weight: FontWeight.w800, color: AppColors.accent)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.driverName,
                    style: AppText.sans(size: 15, weight: FontWeight.w700)),
                Text('Owner-driver · ${_maskPhone(t.phone)}',
                    style: AppText.sans(size: 12.5, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifiedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Verified(),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppText.sans(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.ink,
                    height: 1.45),
                children: const [
                  TextSpan(text: 'Info collected & verified via '),
                  TextSpan(
                      text: 'maalgaadi',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: ' · report if wrong'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length < 6) return phone;
    return '${phone.substring(0, 6)} ${phone.substring(6, 8)}•••';
  }
}
