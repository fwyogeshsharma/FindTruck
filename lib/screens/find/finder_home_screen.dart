import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/truck.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/finder_widgets.dart';
import '../../widgets/kit.dart';
import 'finder_results_screen.dart';

/// 05 · Home / search — the "Find" tab body (finderScreens.jsx `FinderHome`).
class FinderHomeTab extends StatefulWidget {
  const FinderHomeTab({super.key});

  @override
  State<FinderHomeTab> createState() => _FinderHomeTabState();
}

class _FinderHomeTabState extends State<FinderHomeTab> {
  late TruckQuery _q = context.read<AppState>().query;
  int _emptyNow = 1240;

  @override
  void initState() {
    super.initState();
    context.read<AppState>().repo.emptyNowCount().then((v) {
      if (mounted) setState(() => _emptyNow = v);
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
        // Top bar: location + notifications.
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                    Text('Pune', style: AppText.sans(size: 13.5, weight: FontWeight.w700)),
                    AppIcon('chevron', size: 14, color: AppColors.muted),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card,
                  border: Border.all(color: AppColors.line),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AppIcon('bell', size: 20, color: AppColors.ink),
                    Positioned(
                      top: 9,
                      right: 10,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.bad,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.card, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            children: [
              Text('Find an empty truck',
                  style: AppText.sans(
                      size: 22, weight: FontWeight.w800, letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                      width: 7,
                      height: 7,
                      decoration:
                          const BoxDecoration(color: AppColors.ok, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('$_emptyNow trucks empty now near you',
                      style: AppText.sans(
                          size: 13, weight: FontWeight.w700, color: AppColors.accent)),
                ],
              ),
              const SizedBox(height: 16),
              RouteCard(
                from: _q.fromArea,
                to: _q.toArea,
                onSwap: () => setState(() => _q = _q.copyWith(
                    fromArea: _q.toArea, toArea: _q.fromArea)),
              ),
              const SizedBox(height: 18),
              _sectionLabel('Capacity', '· पहिये'),
              const SizedBox(height: 8),
              ChipRow(
                  options: const ['6', '10', '12', '14', '16+'],
                  value: _q.wheels,
                  onChanged: (v) => setState(() => _q = _q.copyWith(wheels: v))),
              const SizedBox(height: 16),
              _sectionLabel('Body type', '· बॉडी'),
              const SizedBox(height: 8),
              ChipRow(
                  options: const ['Open', 'Container', 'Tipper', 'Trailer', 'Tanker'],
                  value: _q.body,
                  onChanged: (v) => setState(() => _q = _q.copyWith(body: v))),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                              style: AppText.sans(size: 13.5, weight: FontWeight.w700)),
                          Text('सिर्फ़ खाली गाड़ियाँ', style: AppText.deva(size: 11.5)),
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
              const SizedBox(height: 18),
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    AppIcon('search', size: 18, color: AppColors.muted),
                    const SizedBox(width: 10),
                    Text('Or look up vehicle no. / phone',
                        style: AppText.sans(size: 13.5, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        BottomBar(children: [
          PrimaryBtn('Search 86 trucks', icon: 'search', onTap: _search),
        ]),
      ],
    );
  }

  Widget _sectionLabel(String en, String hi) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(en, style: AppText.sans(size: 13.5, weight: FontWeight.w700)),
        const SizedBox(width: 4),
        Text(hi, style: AppText.deva(size: 12)),
      ],
    );
  }
}
