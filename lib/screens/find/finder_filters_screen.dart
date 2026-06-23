import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/truck.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/finder_widgets.dart';
import '../../widgets/kit.dart';

/// 07 · Filters (finderScreens.jsx `FinderFilters`).
class FinderFiltersScreen extends StatefulWidget {
  const FinderFiltersScreen({super.key});

  @override
  State<FinderFiltersScreen> createState() => _FinderFiltersScreenState();
}

class _FinderFiltersScreenState extends State<FinderFiltersScreen> {
  late TruckQuery _q = context.read<AppState>().query;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FlowHeader(
                lead: 'close',
                title: 'Filters',
                hi: 'फ़िल्टर',
                onLead: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                children: [
                  const FieldLabel('Route', hi: 'रूट'),
                  RouteCard(
                    from: _q.fromArea,
                    to: _q.toArea,
                    onSwap: () => setState(() =>
                        _q = _q.copyWith(fromArea: _q.toArea, toArea: _q.fromArea)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const FieldLabel('Distance', hi: 'दूरी'),
                      Text('within ${_q.maxDistanceKm.round()} km',
                          style: AppText.sans(
                              size: 13,
                              weight: FontWeight.w700,
                              color: AppColors.accent)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: AppColors.bg,
                      thumbColor: Colors.white,
                      overlayColor: AppColors.accentSoft,
                      trackHeight: 8,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 11),
                    ),
                    child: Slider(
                      value: _q.maxDistanceKm,
                      min: 5,
                      max: 50,
                      onChanged: (v) =>
                          setState(() => _q = _q.copyWith(maxDistanceKm: v)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const FieldLabel('Capacity (wheels)', hi: 'पहिये'),
                  ChipRow(
                      options: const ['6', '10', '12', '14', '16+'],
                      value: _q.wheels,
                      onChanged: (v) => setState(() => _q = _q.copyWith(wheels: v))),
                  const SizedBox(height: 20),
                  const FieldLabel('Body type', hi: 'बॉडी टाइप'),
                  ChipRow(
                      options: const [
                        'Open',
                        'Container',
                        'Tipper',
                        'Trailer',
                        'Tanker'
                      ],
                      value: _q.body,
                      onChanged: (v) => setState(() => _q = _q.copyWith(body: v))),
                  const SizedBox(height: 20),
                  const FieldLabel('Availability', hi: 'उपलब्धता'),
                  SegToggle(
                      options: const ['All', 'Empty now', 'Empty soon'],
                      value: _q.availability,
                      onChanged: (v) => setState(() => _q = _q.copyWith(
                          availability: v, emptyOnly: v != 'All'))),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Verified(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Verified trucks only',
                                style:
                                    AppText.sans(size: 13.5, weight: FontWeight.w700)),
                            Text('माालगाड़ी से सत्यापित',
                                style: AppText.deva(size: 11.5)),
                          ],
                        ),
                      ),
                      AppToggle(
                          on: _q.verifiedOnly,
                          onChanged: (v) =>
                              setState(() => _q = _q.copyWith(verifiedOnly: v))),
                    ],
                  ),
                ],
              ),
            ),
            BottomBar(children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _q = const TruckQuery()),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.line),
                          backgroundColor: AppColors.card,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Reset',
                            style: AppText.sans(
                                size: 15, weight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: PrimaryBtn('Show 86 trucks', onTap: () {
                      context.read<AppState>().updateQuery(_q);
                      Navigator.pop(context);
                    }),
                  ),
                ],
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
