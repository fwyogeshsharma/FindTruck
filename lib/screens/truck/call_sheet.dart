import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/contact_saver.dart';
import '../../models/truck.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/finder_widgets.dart';
import '../../widgets/kit.dart';
import 'message_sheet.dart';

/// 09 · Call driver — tap-to-call confirm sheet (finderDetail.jsx `CallSheet`).
Future<void> showCallSheet(BuildContext context, Truck t) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C0F1923),
    builder: (ctx) => _CallSheet(truck: t, origin: context),
  );
}

class _CallSheet extends StatelessWidget {
  const _CallSheet({required this.truck, required this.origin});
  final Truck truck;

  /// The screen context that opened this sheet — stays mounted after the sheet
  /// pops, so it can host the message sheet handed off from here.
  final BuildContext origin;

  /// Close this sheet and open the template picker on the originating screen.
  void _message(BuildContext context) {
    Navigator.pop(context);
    showMessageSheet(origin, truck);
  }

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    // Read the state before popping, then save the driver to contacts as
    // 'Tr-Name-Location' (once per number) before opening the dialer.
    final state = context.read<AppState>();
    Navigator.pop(context);
    await saveDriverContact(truck: truck, number: number, state: state);
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
                Row(
                  children: [
                    Expanded(
                      child: PrimaryBtn(
                        'Call now',
                        icon: 'phone',
                        onTap: () => _call(context, truck.phone),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _MessageBtn(onTap: () => _message(context)),
                  ],
                ),
                const SizedBox(height: 9),
              ] else if (truck.hasMultiplePhones) ...[
                // Numbers above are tap-to-call; offer messaging as its own
                // action (the message sheet lets the finder pick which number).
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _message(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accentLine),
                      backgroundColor: AppColors.accentSoft,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: AppIcon('message', size: 19, color: AppColors.accent),
                    label: Text('Message driver',
                        style: AppText.sans(
                            size: 15,
                            weight: FontWeight.w800,
                            color: AppColors.accent)),
                  ),
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

/// Square secondary action beside "Call now" — opens the message templates.
class _MessageBtn extends StatelessWidget {
  const _MessageBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColors.accentLine),
          backgroundColor: AppColors.accentSoft,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: AppIcon('message', size: 22, color: AppColors.accent),
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
