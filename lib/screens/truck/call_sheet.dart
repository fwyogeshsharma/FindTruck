import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/truck.dart';
import '../../theme/app_theme.dart';
import '../../widgets/finder_widgets.dart';
import '../../widgets/kit.dart';

/// 09 · Call driver — tap-to-call confirm sheet (finderDetail.jsx `CallSheet`).
Future<void> showCallSheet(BuildContext context, Truck t) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C0F1923),
    builder: (ctx) => _CallSheet(truck: t),
  );
}

class _CallSheet extends StatelessWidget {
  const _CallSheet({required this.truck});
  final Truck truck;

  String get _pretty {
    final p = truck.phone.replaceAll('+91', '').trim();
    if (p.length == 10) return '+91 ${p.substring(0, 5)} ${p.substring(5)}';
    return truck.phone;
  }

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: truck.phone);
    Navigator.pop(context);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start a call to ${truck.phone}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
                color: AppColors.line, borderRadius: BorderRadius.circular(999)),
          ),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                    color: AppColors.accentSoft, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(truck.driverInitials,
                    style: AppText.sans(
                        size: 16, weight: FontWeight.w800, color: AppColors.accent)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(truck.driverName,
                        style: AppText.sans(size: 17, weight: FontWeight.w800)),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Text(truck.plate,
                            style: AppText.sans(
                                size: 12.5, color: AppColors.muted)),
                        const SizedBox(width: 5),
                        const Verified(sm: true),
                      ],
                    ),
                  ],
                ),
              ),
              AvailChip(truck.availability, sm: true),
            ],
          ),
          const SizedBox(height: 18),
          Text(_pretty,
              style: AppText.sans(
                  size: 26, weight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon('info', size: 14, color: AppColors.muted),
              const SizedBox(width: 7),
              Text('Mention you found them on truckfinder',
                  style: AppText.sans(size: 12.5, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 18),
          PrimaryBtn('Call now', icon: 'phone', onTap: () => _call(context)),
          const SizedBox(height: 9),
          GhostBtn('Cancel', onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
