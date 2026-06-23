import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/kit.dart';
import '../../widgets/list_row.dart';

/// 14 · Help & support (finderDetail.jsx `FinderHelp`).
class FinderHelpScreen extends StatelessWidget {
  const FinderHelpScreen({super.key});

  static const _faqs = [
    'How fresh is the truck data?',
    'How is "empty now" decided?',
    "A driver didn't answer — what now?",
    'Report wrong truck info',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FlowHeader(
                lead: 'back',
                title: 'Help & support',
                hi: 'मदद',
                onLead: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                children: [
                  Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        AppIcon('search', size: 19, color: AppColors.muted),
                        const SizedBox(width: 10),
                        Text('Search help articles',
                            style:
                                AppText.sans(size: 14.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('Frequently asked',
                          style: AppText.sans(size: 14, weight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      Text('सामान्य सवाल', style: AppText.deva(size: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < _faqs.length; i++)
                          FRow(title: _faqs[i], last: i == _faqs.length - 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: AppIcon('phone', size: 19, color: AppColors.accent),
                      label: Text('Contact support',
                          style: AppText.sans(
                              size: 14.5,
                              weight: FontWeight.w800,
                              color: AppColors.accent)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.accentSoft,
                        side: const BorderSide(color: AppColors.accentLine, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
