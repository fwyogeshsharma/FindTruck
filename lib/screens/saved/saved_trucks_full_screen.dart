import 'package:flutter/material.dart';

import '../../widgets/kit.dart';
import 'saved_trucks_screen.dart';

/// Saved trucks opened as a full page from Profile (the "Saved" tab shows the
/// same list inline). Reuses [SavedTrucksTab].
class SavedTrucksFullScreen extends StatelessWidget {
  const SavedTrucksFullScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FlowHeader(
                lead: 'back',
                title: 'Saved trucks',
                hi: 'सेव किए ट्रक',
                onLead: () => Navigator.pop(context)),
            const Expanded(child: SavedTrucksTab(showHeader: false)),
          ],
        ),
      ),
    );
  }
}
