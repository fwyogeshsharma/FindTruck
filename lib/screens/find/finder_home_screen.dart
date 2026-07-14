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
  List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    context.read<AppState>().repo.cities().then((c) {
      if (mounted) setState(() => _cities = c);
    });
  }

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
              // Pickup location — autocompletes against the truck cities.
              LocationAutocomplete(
                value: _q.location,
                cities: _cities,
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

/// Location input that suggests known truck cities. Typing filters the list;
/// picking one (or typing a name that matches) sets the exact city to search.
class LocationAutocomplete extends StatelessWidget {
  const LocationAutocomplete({
    super.key,
    required this.value,
    required this.cities,
    required this.onChanged,
  });

  final String value;
  final List<String> cities;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel('Location', hi: 'कहाँ से'),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Autocomplete<String>(
                initialValue: TextEditingValue(text: value),
                optionsBuilder: (tev) {
                  final input = tev.text.trim().toLowerCase();
                  if (input.isEmpty) return cities;
                  return cities
                      .where((c) => c.toLowerCase().contains(input));
                },
                onSelected: onChanged,
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  return _CityInputBox(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    onSubmitted: onFieldSubmitted,
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(14),
                        color: AppColors.card,
                        child: SizedBox(
                          width: width,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 260),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, i) {
                                final city = options.elementAt(i);
                                return InkWell(
                                  onTap: () => onSelected(city),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: [
                                        const Text('📍'),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(city,
                                              style: AppText.sans(
                                                  size: 14.5,
                                                  weight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The boxed text field for [LocationAutocomplete], styled to match [Field].
class _CityInputBox extends StatelessWidget {
  const _CityInputBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final active = focusNode.hasFocus;
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: active ? AppColors.accent : AppColors.line, width: 1.5),
            boxShadow: active
                ? [
                    const BoxShadow(
                        color: AppColors.accentSoft,
                        blurRadius: 0,
                        spreadRadius: 3)
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text('📍', style: AppText.sans(weight: FontWeight.w700)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.streetAddress,
                  onChanged: onChanged,
                  onSubmitted: (_) => onSubmitted(),
                  style: AppText.sans(size: 15.5, weight: FontWeight.w600),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'City you want the truck from',
                    hintStyle: AppText.sans(
                        size: 15.5,
                        weight: FontWeight.w500,
                        color: AppColors.muted),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
