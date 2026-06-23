import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'kit.dart';

/// Settings/menu list row (finderDetail.jsx `FRow`).
class FRow extends StatelessWidget {
  const FRow({
    super.key,
    this.icon,
    required this.title,
    this.hi,
    this.trailing,
    this.danger = false,
    this.last = false,
    this.onTap,
  });

  final String? icon;
  final String title;
  final String? hi;
  final Widget? trailing;
  final bool danger;
  final bool last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: danger ? AppColors.badBg : AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppIcon(icon!,
                    size: 20, color: danger ? AppColors.bad : AppColors.accent),
              ),
              const SizedBox(width: 13),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.sans(
                          size: 14.5,
                          weight: FontWeight.w600,
                          color: danger ? AppColors.bad : AppColors.ink)),
                  if (hi != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(hi!, style: AppText.deva(size: 11.5)),
                    ),
                ],
              ),
            ),
            trailing ??
                (danger
                    ? const SizedBox.shrink()
                    : AppIcon('chevron', size: 16, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
