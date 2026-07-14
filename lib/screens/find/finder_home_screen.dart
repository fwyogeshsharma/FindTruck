import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/truck.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kit.dart';
import 'finder_results_screen.dart';

/// Find Vehicle — pick a location and the vehicle spec (axle / wheels / body),
/// then filter the FreightDesk database down to matching trucks.
class FinderHomeTab extends StatefulWidget {
  const FinderHomeTab({super.key});

  @override
  State<FinderHomeTab> createState() => _FinderHomeTabState();
}

class _FinderHomeTabState extends State<FinderHomeTab> {
  late TruckQuery _q = context.read<AppState>().query;

  void _search() {
    context.read<AppState>().updateQuery(_q);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FinderResultsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Find a vehicle',
                  style: AppText.sans(
                      size: 22, weight: FontWeight.w800, letterSpacing: -0.4)),
              Text('गाड़ी खोजें', style: AppText.deva(size: 12.5)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            children: [
              // Pickup location.
              Field(
                label: 'Location',
                hi: 'कहाँ से',
                value: _q.location,
                placeholder: 'City or area you want the truck from',
                prefix: '📍',
                keyboardType: TextInputType.streetAddress,
                onChanged: (v) => _q = _q.copyWith(location: v),
              ),
              const FieldLabel('Axle type', hi: 'एक्सल'),
              ChipRow(
                  options: const ['Any', 'Single-Axle', 'Multi-Axle'],
                  value: _q.axle,
                  onChanged: (v) => setState(() => _q = _q.copyWith(axle: v))),
              const SizedBox(height: 20),
              const FieldLabel('Wheels', hi: 'पहिये'),
              ChipRow(
                  options: const ['Any', '4', '6', '10', '12', '14', '16'],
                  value: _q.wheels,
                  onChanged: (v) =>
                      setState(() => _q = _q.copyWith(wheels: v))),
              const SizedBox(height: 20),
              const FieldLabel('Body type', hi: 'बॉडी — फ्लैट या ओपन'),
              ChipRow(
                  options: const [
                    'Any',
                    'Open Body',
                    'Flat Bed',
                    'Container',
                  ],
                  value: _q.body,
                  onChanged: (v) => setState(() => _q = _q.copyWith(body: v))),
              const SizedBox(height: 22),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentLine),
                ),
                child: Row(
                  children: [
                    AppIcon('bolt', size: 20, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Only empty trucks',
                              style: AppText.sans(
                                  size: 13.5, weight: FontWeight.w700)),
                          Text('सिर्फ़ खाली गाड़ियाँ',
                              style: AppText.deva(size: 11.5)),
                        ],
                      ),
                    ),
                    AppToggle(
                        on: _q.emptyOnly,
                        onChanged: (v) =>
                            setState(() => _q = _q.copyWith(emptyOnly: v))),
                  ],
                ),
              ),
            ],
          ),
        ),
        BottomBar(children: [
          PrimaryBtn('Find vehicles', icon: 'search', onTap: _search),
        ]),
      ],
    );
  }
}
