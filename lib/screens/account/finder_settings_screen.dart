import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kit.dart';
import '../../widgets/list_row.dart';
import '../auth/login_screen.dart';

/// 13 · Settings (finderDetail.jsx `FinderSettings`).
class FinderSettingsScreen extends StatefulWidget {
  const FinderSettingsScreen({super.key});

  @override
  State<FinderSettingsScreen> createState() => _FinderSettingsScreenState();
}

class _FinderSettingsScreenState extends State<FinderSettingsScreen> {
  bool _alerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FlowHeader(
                lead: 'back',
                title: 'Settings',
                hi: 'सेटिंग्स',
                onLead: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                children: [
                  _group([
                    FRow(
                        icon: 'bell',
                        title: 'Alert notifications',
                        hi: 'अलर्ट',
                        trailing: AppToggle(
                            on: _alerts,
                            onChanged: (v) => setState(() => _alerts = v))),
                    FRow(
                        icon: 'globe',
                        title: 'Language',
                        hi: 'भाषा',
                        onTap: _pickLanguage,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('English',
                                style: AppText.sans(
                                    size: 13.5,
                                    weight: FontWeight.w600,
                                    color: AppColors.muted)),
                            AppIcon('chevron', size: 15, color: AppColors.muted),
                          ],
                        )),
                    const FRow(
                        icon: 'info',
                        title: 'About truckfinder',
                        hi: 'ऐप के बारे में',
                        last: true),
                  ]),
                  const SizedBox(height: 16),
                  _group([
                    FRow(
                      icon: 'logout',
                      title: 'Log out',
                      hi: 'लॉग आउट',
                      danger: true,
                      last: true,
                      onTap: () async {
                        await context.read<AuthService>().logout();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Center(
                    child: Text('truckfinder · v1.0.0 · data by maalgaadi',
                        style: AppText.sans(size: 12, color: AppColors.muted)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(children: rows),
    );
  }

  void _pickLanguage() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            for (final lang in ['English', 'हिन्दी (Hindi)', 'मराठी (Marathi)'])
              ListTile(
                title: Text(lang, style: AppText.sans(weight: FontWeight.w600)),
                onTap: () => Navigator.pop(context),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
