import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/truck_repository.dart';
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
  /// How many matches to gather before the first paint, and per scroll refill.
  static const _firstBatch = 10;
  static const _nextBatch = 20;

  final _scroll = ScrollController();
  late TruckPager _pager;
  bool _initialLoad = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _runSearch();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _runSearch() {
    final state = context.read<AppState>();
    _pager = state.repo.pager(state.query);
    _initialLoad = true;
    _error = null;
    _loadMore(want: _firstBatch);
  }

  Future<void> _loadMore({int want = _nextBatch}) async {
    if (_pager.isLoading || !_pager.hasMore) return;
    final pager = _pager; // capture: a new search may replace it mid-flight
    try {
      final added = await pager.loadMore(want: want);
      if (!mounted || pager != _pager) return;
      setState(() => _initialLoad = false);
      // A selective filter can produce an all-miss scan: nothing was added, so
      // the list didn't grow and no scroll event will arrive to ask again.
      // Keep pulling until we find matches or the table ends.
      if (added == 0 && pager.hasMore) _loadMore(want: want);
    } catch (e) {
      if (!mounted || pager != _pager) return;
      setState(() {
        _initialLoad = false;
        _error = e;
      });
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    // Refill well before the bottom so scrolling never stalls on a round-trip.
    if (pos.pixels >= pos.maxScrollExtent - 600) _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final q = context.watch<AppState>().query;
    // Each chip carries the query it produces once removed. Availability is
    // stored as two coupled fields (`availability` drives `emptyOnly` on the
    // filters sheet), so clearing that chip has to reset both or the sheet
    // reopens still showing the segment selected.
    final chips = <({String label, TruckQuery cleared})>[
      if (q.location.trim().isNotEmpty)
        (label: q.location.trim(), cleared: q.copyWith(location: '')),
      if (q.emptyOnly)
        (
          label: q.availability == 'All' ? 'Empty now' : q.availability,
          cleared: q.copyWith(emptyOnly: false, availability: 'All'),
        ),
      if (q.verifiedOnly)
        (label: 'Verified', cleared: q.copyWith(verifiedOnly: false)),
      if (q.wheels != 'Any')
        (label: '${q.wheels}-wheel', cleared: q.copyWith(wheels: 'Any')),
      if (q.body != 'Any') (label: q.body, cleared: q.copyWith(body: 'Any')),
      if (q.axle != 'Any') (label: q.axle, cleared: q.copyWith(axle: 'Any')),
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
                        Text(_countLabel,
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
                  // Whole chip is the tap target — the 12px × alone is far
                  // below a usable touch size.
                  for (final c in chips)
                    GestureDetector(
                      onTap: () => _removeFilter(c.cleared),
                      child: _chip(
                        label: c.label,
                        trailing:
                            AppIcon('close', size: 12, color: AppColors.accent),
                        fg: AppColors.accent,
                        bg: AppColors.accentSoft,
                        border: AppColors.accentLine,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  /// Loaded-so-far count, marked "+" while more of the table is still unscanned
  /// so the number isn't read as a final total.
  String get _countLabel {
    if (_initialLoad) return '… trucks';
    return '${_pager.items.length}${_pager.hasMore ? '+' : ''} trucks';
  }

  Widget _buildList() {
    final trucks = _pager.items;

    if (_initialLoad) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (trucks.isEmpty) {
      // Still scanning: no matches yet, but the table isn't exhausted.
      if (_pager.hasMore && _error == null) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.accent));
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon('truck', size: 40, color: AppColors.line),
              const SizedBox(height: 12),
              Text(
                  _error == null
                      ? 'No trucks match these filters'
                      : 'Couldn’t load trucks',
                  style: AppText.sans(weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                  _error == null
                      ? 'Try “Any” for some fields or a different location.'
                      : 'Check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: AppText.sans(size: 12.5, color: AppColors.muted)),
            ],
          ),
        ),
      );
    }

    // One trailing slot for the "loading more" spinner while rows remain.
    final showFooter = _pager.hasMore || _error != null;
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: trucks.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i >= trucks.length) return _footer();
        final t = trucks[i];
        return TruckRow(
          truck: t,
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TruckDetailScreen(truck: t))),
          onCall: () => showCallSheet(context, t),
        );
      },
    );
  }

  Widget _footer() {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: TextButton(
            onPressed: () => setState(() {
              _error = null;
              _loadMore();
            }),
            child: Text('Couldn’t load more · Retry',
                style: AppText.sans(size: 13, weight: FontWeight.w700)),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.accent),
        ),
      ),
    );
  }

  /// Drops one filter and re-runs the search against the reduced query.
  void _removeFilter(TruckQuery cleared) {
    context.read<AppState>().updateQuery(cleared);
    setState(_runSearch);
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
