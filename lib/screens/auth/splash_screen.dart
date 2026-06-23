import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/finder_widgets.dart';
import '../main_scaffold.dart';
import 'login_screen.dart';

/// 01 · Splash (finderScreens.jsx `FinderSplash`). Restores any saved session
/// while the brand mark shows, then routes to the dashboard or login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final auth = context.read<AuthService>();
    // Restore session and hold the splash for a minimum beat.
    await Future.wait([
      auth.restore(),
      Future<void>.delayed(const Duration(milliseconds: 1400)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            auth.isLoggedIn ? const MainScaffold() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accent,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FinderLogo(size: 76, onDark: true),
                const SizedBox(height: 22),
                Text('truckfinder',
                    style: AppText.sans(
                        size: 28,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('खाली ट्रक, तुरंत खोजें',
                    style: AppText.deva(
                        size: 14, color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Center(
              child: Text('powered by maalgaadi data',
                  style: AppText.sans(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7))),
            ),
          ),
        ],
      ),
    );
  }
}
