import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/truck.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/finder_widgets.dart';
import '../../widgets/kit.dart';
import '../truck/truck_detail_screen.dart';
import '../truck/call_sheet.dart';
import 'saved_searches_screen.dart';

/// 10 · Saved trucks — the "Saved" tab body (finderDetail.jsx `SavedTrucks`).
class SavedTrucksTab extends StatelessWidget {
  const SavedTrucksTab({super.key, this.showHeader = true});

  final bool showHeader;

  static const _notes = ['2 days ago', '3 days ago', '5 days ago', '1 week ago'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text('Saved trucks',
                          style: AppText.sans(size: 18, weight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Text('सेव किए ट्रक', style: AppText.deva(size: 12.5)),
                    ],
                  ),
                ),
                IconBtn('bell',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const SavedSearchesScreen()))),
              ],
            ),
          ),
        Expanded(
          child: FutureBuilder<List<Truck>>(
            future: state.savedTrucks(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent));
              }
              final trucks = snap.data!;
              if (trucks.isEmpty) {
                return Center(
                  child: Text('No saved trucks yet',
                      style: AppText.sans(color: AppColors.muted)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: trucks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => TruckRow(
                  truck: trucks[i],
                  savedNote: _notes[i % _notes.length],
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => TruckDetailScreen(truck: trucks[i]))),
                  onCall: () => showCallSheet(context, trucks[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
