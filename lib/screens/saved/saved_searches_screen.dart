import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/truck.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kit.dart';
import '../find/finder_results_screen.dart';

/// 11 · Saved searches / alerts (finderDetail.jsx `SavedSearches`).
class SavedSearchesScreen extends StatelessWidget {
  const SavedSearchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final searches = state.savedSearches;
    final alreadySaved = state.isSearchSaved(state.query);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FlowHeader(
                lead: 'back',
                title: 'Saved searches',
                hi: 'सेव सर्च और अलर्ट',
                onLead: () => Navigator.pop(context)),
            Expanded(
              child: searches.isEmpty
                  ? _empty()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                      children: [
                        Text(
                            'Tap a search to run it again.',
                            style: AppText.sans(
                                size: 13, color: AppColors.muted, height: 1.5)),
                        const SizedBox(height: 14),
                        for (var i = 0; i < searches.length; i++) ...[
                          if (i != 0) const SizedBox(height: 10),
                          _SearchCard(search: searches[i]),
                        ],
                      ],
                    ),
            ),
            BottomBar(children: [
              PrimaryBtn(
                alreadySaved ? 'Current search already saved' : 'Save current search',
                icon: alreadySaved ? 'check' : 'plus',
                disabled: alreadySaved,
                onTap: () => _saveCurrent(context),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCurrent(BuildContext context) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final saved = await state.saveSearch(state.query);
    messenger.showSnackBar(SnackBar(
      content: Text(saved ? 'Search saved' : 'That search is already saved'),
    ));
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon('bell', size: 40, color: AppColors.line),
            const SizedBox(height: 12),
            Text('No saved searches yet',
                style: AppText.sans(weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
                'Set up filters on the Find screen, then save the search here '
                'to run it again in one tap.',
                textAlign: TextAlign.center,
                style: AppText.sans(size: 12.5, color: AppColors.muted, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({required this.search});

  final SavedSearch search;

  /// Loads this search into the active query and opens the results screen.
  void _run(BuildContext context) {
    context.read<AppState>().updateQuery(search.query);
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FinderResultsScreen()));
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete saved search?',
            style: AppText.sans(size: 16, weight: FontWeight.w800)),
        content: Text('${search.title} · ${search.route}',
            style: AppText.sans(size: 13.5, color: AppColors.muted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: AppText.sans(weight: FontWeight.w700))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: AppText.sans(weight: FontWeight.w700, color: AppColors.bad)),
          ),
        ],
      ),
    );
    if (ok == true) await state.removeSavedSearch(search.id);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _run(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(search.title,
                            style:
                                AppText.sans(size: 14.5, weight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            AppIcon('pin', size: 13, color: AppColors.muted),
                            const SizedBox(width: 5),
                            Text(search.route,
                                style: AppText.sans(
                                    size: 12.5, color: AppColors.muted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppToggle(
                    on: search.alertOn,
                    onChanged: (v) =>
                        context.read<AppState>().setSearchAlert(search.id, v),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Tap to run',
                      style: AppText.sans(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: AppColors.accent)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _confirmDelete(context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon('trash', size: 13, color: AppColors.bad),
                          const SizedBox(width: 5),
                          Text('Delete',
                              style: AppText.sans(
                                  size: 11.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.bad)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
