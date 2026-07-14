import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/truck.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/finder_widgets.dart';
import '../../widgets/kit.dart';
import '../truck/truck_detail_screen.dart';
import '../truck/call_sheet.dart';
import 'finder_filters_screen.dart';

/// 06 · Results (finderScreens.jsx `FinderResults`).
class FinderResultsScreen extends StatefulWidget {
  const FinderResultsScreen({super.key});

  @override
  State<FinderResultsScreen> createState() => _FinderResultsScreenState();
}

class _FinderResultsScreenState extends State<FinderResultsScreen> {
  late Future<List<Truck>> _future;
  int? _count;

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  void _runSearch() {
    final state = context.read<AppState>();
    _future = state.repo.search(state.query)
      ..then((list) {
        if (mounted) setState(() => _count = list.length);
      });
  }

  @override
  Widget build(BuildContext context) {
    final q = context.watch<AppState>().query;
    final chips = <String>[
      if (q.location.trim().isNotEmpty) q.location.trim(),
      if (q.emptyOnly) 'Empty now',
      if (q.wheels != 'Any') '${q.wheels}-wheel',
      if (q.body != 'Any') q.body,
      if (q.axle != 'Any') q.axle,
    ];
    final subtitle = q.location.trim().isEmpty
        ? 'All locations${q.emptyOnly ? ' · empty now' : ''}'
        : '${q.location.trim()}${q.emptyOnly ? ' · empty now' : ''}';
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  IconBtn('back', onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_count ?? '…'} trucks',
                            style: AppText.sans(size: 17, weight: FontWeight.w800)),
                        Text(subtitle,
                            style: AppText.sans(size: 11.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
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
                        AppIcon('sort', size: 15, color: AppColors.ink),
                        const SizedBox(width: 5),
                        Text('Nearest',
                            style: AppText.sans(size: 13, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Active filter chips.
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                children: [
                  GestureDetector(
                    onTap: _openFilters,
                    child: _chip(
                      label: 'Filters · ${chips.length}',
                      leading: AppIcon('filter', size: 14, color: Colors.white),
                      fg: Colors.white,
                      bg: AppColors.accent,
                    ),
                  ),
                  for (final c in chips)
                    _chip(
                      label: c,
                      trailing: AppIcon('close', size: 12, color: AppColors.accent),
                      fg: AppColors.accent,
                      bg: AppColors.accentSoft,
                      border: AppColors.accentLine,
                    ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Truck>>(
                future: _future,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(color: AppColors.accent));
                  }
                  final trucks = snap.data!;
                  if (trucks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon('truck', size: 40, color: AppColors.line),
                            const SizedBox(height: 12),
                            Text('No trucks match these filters',
                                style:
                                    AppText.sans(weight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Try “Any” for some fields or a different location.',
                                textAlign: TextAlign.center,
                                style: AppText.sans(
                                    size: 12.5, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: trucks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => TruckRow(
                      truck: trucks[i],
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TruckDetailScreen(truck: trucks[i]))),
                      onCall: () => showCallSheet(context, trucks[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilters() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const FinderFiltersScreen()))
        .then((_) {
      if (!mounted) return;
      setState(_runSearch);
    });
  }

  Widget _chip({
    required String label,
    Widget? leading,
    Widget? trailing,
    required Color fg,
    required Color bg,
    Color? border,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 5)],
          Text(label,
              style: AppText.sans(size: 12.5, weight: FontWeight.w700, color: fg)),
          if (trailing != null) ...[const SizedBox(width: 5), trailing],
        ],
      ),
    );
  }
}
