import 'package:flutter/material.dart';

import '../widgets/finder_widgets.dart';
import 'account/finder_profile_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'find/finder_home_screen.dart';
import 'saved/saved_trucks_screen.dart';

/// Host for the three primary tabs (Find / Saved / Profile) sharing the
/// finder bottom navigation.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  DashboardTab(),
                  FinderHomeTab(),
                  SavedTrucksTab(),
                  FinderProfileTab(),
                ],
              ),
            ),
            FinderTabBar(
              active: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ],
        ),
      ),
    );
  }
}
