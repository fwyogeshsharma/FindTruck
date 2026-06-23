import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kit.dart';
import '../../widgets/list_row.dart';
import '../saved/saved_searches_screen.dart';
import '../saved/saved_trucks_full_screen.dart';
import 'finder_help_screen.dart';
import 'finder_settings_screen.dart';

/// 12 · Profile — the "Profile" tab body (finderDetail.jsx `FinderProfile`).
/// Shows the logged-in FreightDesk account and its report stats.
class FinderProfileTab extends StatefulWidget {
  const FinderProfileTab({super.key});

  @override
  State<FinderProfileTab> createState() => _FinderProfileTabState();
}

class _FinderProfileTabState extends State<FinderProfileTab> {
  late final Future<Map<String, dynamic>> _reports =
      context.read<AuthService>().myReports();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final savedCount = context.watch<AppState>().savedTruckIds.length;
    final alertCount =
        context.watch<AppState>().savedSearches.where((s) => s.alertOn).length;
    return Column(
      children: [
        const FlowHeader(title: 'Profile', hi: 'प्रोफ़ाइल'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 6, 2, 18),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                          color: AppColors.accentSoft, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(user?.initials ?? '?',
                          style: AppText.sans(
                              size: 22,
                              weight: FontWeight.w800,
                              color: AppColors.accent)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'truckfinder user',
                              style:
                                  AppText.sans(size: 19, weight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                              [
                                if (user?.role != null) user!.role!,
                                if (user != null) user.phone,
                              ].join(' · '),
                              style: AppText.sans(
                                  size: 13.5, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    Text('Edit',
                        style: AppText.sans(
                            size: 13,
                            weight: FontWeight.w700,
                            color: AppColors.accent)),
                  ],
                ),
              ),
              FutureBuilder<Map<String, dynamic>>(
                future: _reports,
                builder: (context, snap) {
                  final summary =
                      (snap.data?['summary'] as Map?)?.cast<String, dynamic>();
                  final total = snap.data?['total'];
                  return Row(
                    children: [
                      Expanded(
                          child: _statCard('${total ?? '—'}', 'reports')),
                      const SizedBox(width: 9),
                      Expanded(
                          child: _statCard(
                              '${summary?['passed'] ?? '—'}', 'verified')),
                      const SizedBox(width: 9),
                      Expanded(child: _statCard('$savedCount', 'saved')),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    FRow(
                      icon: 'bell',
                      title: 'Saved searches & alerts',
                      hi: 'सेव सर्च',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const SavedSearchesScreen())),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(999)),
                            child: Text('$alertCount',
                                style: AppText.sans(
                                    size: 11,
                                    weight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                          const SizedBox(width: 6),
                          AppIcon('chevron', size: 16, color: AppColors.muted),
                        ],
                      ),
                    ),
                    FRow(
                        icon: 'bookmark',
                        title: 'Saved trucks',
                        hi: 'सेव किए ट्रक',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const SavedTrucksFullScreen()))),
                    FRow(
                        icon: 'bell',
                        title: 'Settings',
                        hi: 'सेटिंग्स',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const FinderSettingsScreen()))),
                    FRow(
                        icon: 'help',
                        title: 'Help & support',
                        hi: 'मदद',
                        last: true,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const FinderHelpScreen()))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppText.sans(
                  size: 18, weight: FontWeight.w800, color: AppColors.accent)),
          const SizedBox(height: 1),
          Text(label,
              style:
                  AppText.sans(size: 11, weight: FontWeight.w600, color: AppColors.muted)),
        ],
      ),
    );
  }
}
