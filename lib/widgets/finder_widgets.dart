import 'package:flutter/material.dart';

import '../models/truck.dart';
import '../theme/app_theme.dart';
import 'kit.dart';

/// truckfinder brand mark: maalgaadi-style truck box with a search badge
/// (finderScreens.jsx `FinderLogo`).
class FinderLogo extends StatelessWidget {
  const FinderLogo({super.key, this.size = 64, this.onDark = false});
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.28),
              color: onDark ? Colors.white.withValues(alpha: 0.16) : AppColors.accent,
              border: onDark
                  ? Border.all(color: Colors.white.withValues(alpha: 0.25))
                  : null,
            ),
            child: AppIcon('truck', size: size * 0.5, color: Colors.white),
          ),
          Positioned(
            right: -size * 0.06,
            bottom: -size * 0.06,
            child: Container(
              width: size * 0.42,
              height: size * 0.42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                    color: onDark ? AppColors.accent : AppColors.bg, width: 2),
              ),
              child: AppIcon('search', size: size * 0.24, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Availability pill (finderScreens.jsx `AvailChip`).
class AvailChip extends StatelessWidget {
  const AvailChip(this.kind, {super.key, this.sm = false});
  final Availability kind;
  final bool sm;

  @override
  Widget build(BuildContext context) {
    final (c, bg) = switch (kind) {
      Availability.empty => (AppColors.ok, AppColors.okBg),
      Availability.soon => (AppColors.warn, AppColors.warnBg),
      Availability.loaded => (AppColors.muted, AppColors.bg),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sm ? 8 : 9, vertical: sm ? 3 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: kind == Availability.loaded
            ? Border.all(color: AppColors.line)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(kind.label,
              style: AppText.sans(
                  size: sm ? 10.5 : 11.5, weight: FontWeight.w700, color: c)),
        ],
      ),
    );
  }
}

/// "Verified by maalgaadi" tick (finderScreens.jsx `Verified`).
class Verified extends StatelessWidget {
  const Verified({super.key, this.sm = false});
  final bool sm;

  @override
  Widget build(BuildContext context) {
    final d = sm ? 15.0 : 17.0;
    return Container(
      width: d,
      height: d,
      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
      child: Icon(Icons.check, size: sm ? 9 : 11, color: Colors.white),
    );
  }
}

/// Bottom navigation for the finder app (finderScreens.jsx `FinderTabBar`).
class FinderTabBar extends StatelessWidget {
  const FinderTabBar({super.key, required this.active, this.onTap});
  final int active; // 0 find, 1 saved, 2 profile
  final ValueChanged<int>? onTap;

  static const _tabs = [
    ('grid', 'Dashboard'),
    ('search', 'Find'),
    ('bookmark', 'Saved'),
    ('person', 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap == null ? null : () => onTap!(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(_tabs[i].$1,
                      size: 24,
                      color: i == active ? AppColors.accent : AppColors.muted),
                  const SizedBox(height: 3),
                  Text(_tabs[i].$2,
                      style: AppText.sans(
                          size: 10.5,
                          weight: i == active ? FontWeight.w700 : FontWeight.w600,
                          color: i == active ? AppColors.accent : AppColors.muted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A truck list card (finderScreens.jsx `TruckRow`).
class TruckRow extends StatelessWidget {
  const TruckRow({super.key, required this.truck, this.savedNote, this.onTap, this.onCall});
  final Truck truck;
  final String? savedNote;
  final VoidCallback? onTap;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final loaded = truck.availability == Availability.loaded;
    final meta = [
      truck.area,
      truck.distanceKm,
      savedNote != null ? 'saved $savedNote' : truck.updated,
    ].where((s) => s.trim().isNotEmpty).join(' · ');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ThumbBox(size: 58, label: 'truck'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(truck.plate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(size: 15, weight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 6),
                      const Verified(sm: true),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('${truck.wheels}-wheel · ${truck.body}',
                      style: AppText.sans(
                          size: 12.5, weight: FontWeight.w600, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      AppIcon('pin', size: 13, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(size: 11.5, color: AppColors.muted)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AvailChip(truck.availability, sm: true),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onCall,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: loaded ? AppColors.bg : AppColors.accent,
                      border: loaded ? Border.all(color: AppColors.line) : null,
                    ),
                    child: AppIcon('phone',
                        size: 18, color: loaded ? AppColors.muted : Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// From/To route card with swap control (finderScreens.jsx `RouteCard`).
class RouteCard extends StatelessWidget {
  const RouteCard({super.key, required this.from, required this.to, this.onSwap});
  final String from;
  final String to;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Stack(
        children: [
          Column(
            children: [
              _leg(
                marker: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ok, width: 3),
                  ),
                ),
                label: 'From · कहाँ से',
                value: from,
                border: true,
              ),
              _leg(
                marker: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                label: 'To · कहाँ तक (optional)',
                value: to,
                border: false,
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: onSwap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bg,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: AppIcon('swap', size: 18, color: AppColors.accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leg(
      {required Widget marker,
      required String label,
      required String value,
      required bool border}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: border
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      child: Row(
        children: [
          marker,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppText.sans(
                        size: 11, weight: FontWeight.w600, color: AppColors.muted)),
                Text(value,
                    style: AppText.sans(size: 14.5, weight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
