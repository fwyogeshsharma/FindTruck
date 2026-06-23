import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/truck.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kit.dart';

/// 11 · Saved searches / alerts (finderDetail.jsx `SavedSearches`).
class SavedSearchesScreen extends StatefulWidget {
  const SavedSearchesScreen({super.key});

  @override
  State<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen> {
  late final List<SavedSearch> _searches =
      List.of(context.read<AppState>().savedSearches);

  @override
  Widget build(BuildContext context) {
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                children: [
                  Text(
                      'Get a ping when an empty truck matching your route appears.',
                      style:
                          AppText.sans(size: 13, color: AppColors.muted, height: 1.5)),
                  const SizedBox(height: 14),
                  for (var i = 0; i < _searches.length; i++) ...[
                    if (i != 0) const SizedBox(height: 10),
                    _searchCard(i),
                  ],
                ],
              ),
            ),
            BottomBar(children: [
              PrimaryBtn('Save current search', icon: 'plus', onTap: () {
                setState(() => _searches.add(const SavedSearch(
                    '10-wheel · Open', 'Pune → Mumbai', true, 'new')));
              }),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _searchCard(int i) {
    final s = _searches[i];
    return Container(
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
                    Text(s.title,
                        style: AppText.sans(size: 14.5, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AppIcon('pin', size: 13, color: AppColors.muted),
                        const SizedBox(width: 5),
                        Text(s.route,
                            style: AppText.sans(size: 12.5, color: AppColors.muted)),
                      ],
                    ),
                  ],
                ),
              ),
              AppToggle(
                  on: s.alertOn,
                  onChanged: (v) => setState(() => _searches[i] =
                      SavedSearch(s.title, s.route, v, s.newCount))),
            ],
          ),
          if (s.newCount.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.ok, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(s.newCount,
                      style: AppText.sans(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: AppColors.accent)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
