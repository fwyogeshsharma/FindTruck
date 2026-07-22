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

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    Navigator.pop(context);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start a call to $number')),
      );
    }
  }

  /// One number → show it large and let the primary button dial it. Several →
  /// list them so the finder picks who to ring, since they can reach different
  /// people (the reporter who logged the truck isn't the driver).
  List<Widget> _numberSection(BuildContext context) {
    if (truck.phones.isEmpty) {
      return [
        Text(
          'No number on this record',
          style: AppText.sans(size: 15, weight: FontWeight.w700),
        ),
      ];
    }
    if (!truck.hasMultiplePhones) {
      return [
        Text(
          truck.phones.first.pretty,
          style: AppText.sans(
            size: 26,
            weight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ];
    }
    return [
      Text(
        'Choose a number to call',
        style: AppText.sans(size: 13, color: AppColors.muted),
      ),
      const SizedBox(height: 10),
      for (final p in truck.phones) ...[
        _NumberRow(phone: p, onTap: () => _call(context, p.number)),
        const SizedBox(height: 8),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // The other bottom sheet in the app (settings) wraps its content in a
      // SafeArea; this one hardcoded 30px, so its actions sat under the system
      // nav bar on 3-button devices.
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: AppColors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      truck.driverInitials,
                      style: AppText.sans(
                        size: 16,
                        weight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          truck.driverName,
                          style: AppText.sans(
                            size: 17,
                            weight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Text(
                              truck.plate,
                              style: AppText.sans(
                                size: 12.5,
                                color: AppColors.muted,
                              ),
                            ),
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
              ..._numberSection(context),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon('info', size: 14, color: AppColors.muted),
                  const SizedBox(width: 7),
                  Text(
                    'Mention you found them on truckfinder',
                    style: AppText.sans(size: 12.5, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (!truck.hasMultiplePhones && truck.phone.isNotEmpty) ...[
                PrimaryBtn(
                  'Call now',
                  icon: 'phone',
                  onTap: () => _call(context, truck.phone),
                ),
                const SizedBox(height: 9),
              ],
              GhostBtn('Cancel', onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// One selectable number in the multi-number call sheet.
class _NumberRow extends StatelessWidget {
  const _NumberRow({required this.phone, required this.onTap});

  final TruckPhone phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phone.label,
                      style: AppText.sans(
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone.pretty,
                      style: AppText.sans(
                        size: 18,
                        weight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon('phone', size: 17, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
