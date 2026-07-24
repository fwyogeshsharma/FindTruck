import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/message_template.dart';
import '../../models/truck.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kit.dart';
import '../account/message_templates_screen.dart';

/// Message driver — pick a saved template, then hand off to the phone's SMS
/// app with the number and the (name-filled) text already composed, so the
/// finder just reads it and taps send.
Future<void> showMessageSheet(BuildContext context, Truck t) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C0F1923),
    builder: (_) => _MessageSheet(truck: t),
  );
}

class _MessageSheet extends StatefulWidget {
  const _MessageSheet({required this.truck});
  final Truck truck;

  @override
  State<_MessageSheet> createState() => _MessageSheetState();
}

class _MessageSheetState extends State<_MessageSheet> {
  /// The number the SMS will go to — defaults to the driver's (best) number.
  late String _number = widget.truck.phone;

  Future<void> _sendTemplate(MessageTemplate tpl) async {
    final text = tpl.render(driverName: widget.truck.driverName);
    // sms:<number>?body=<text> — the OS opens its Messages app pre-filled;
    // the finder reviews and taps send.
    //
    // We must NOT use Uri(queryParameters:) here: it encodes spaces as '+',
    // and the Android Messages app inserts those literally ("Hi+I+am"). Encode
    // the body ourselves with encodeComponent, which uses %20 for spaces, and
    // build the string directly so the app shows real spaces.
    final uri = Uri.parse('sms:$_number?body=${Uri.encodeComponent(text)}');
    Navigator.pop(context);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open your Messages app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final truck = widget.truck;
    final templates = context.watch<AppState>().messageTemplates;
    final hasNumber = _number.trim().isNotEmpty;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: AppColors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      truck.driverInitials,
                      style: AppText.sans(
                        size: 16,
                        weight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Message ${truck.driverName}',
                            style: AppText.sans(
                                size: 17, weight: FontWeight.w800)),
                        Text('टेम्पलेट चुनें',
                            style: AppText.deva(size: 11.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (!hasNumber)
                _noNumberNote()
              else ...[
                // Number picker only when the record carries more than one.
                if (truck.hasMultiplePhones) ...[
                  Text('Send to',
                      style:
                          AppText.sans(size: 13, color: AppColors.muted)),
                  const SizedBox(height: 8),
                  for (final p in truck.phones) ...[
                    _NumberOption(
                      phone: p,
                      selected: p.number == _number,
                      onTap: () => setState(() => _number = p.number),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 6),
                ],

                FieldLabel('Choose a template', hi: 'संदेश चुनें'),
                const SizedBox(height: 2),
                if (templates.isEmpty)
                  _emptyTemplates(context)
                else
                  ...templates.map((tpl) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TemplateRow(
                          template: tpl,
                          driverName: truck.driverName,
                          onTap: () => _sendTemplate(tpl),
                        ),
                      )),

                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon('info', size: 14, color: AppColors.muted),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'Opens your Messages app — review, then send',
                        style: AppText.sans(size: 12, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const MessageTemplatesScreen()));
                  },
                  icon: AppIcon('edit', size: 17, color: AppColors.accent),
                  label: Text('Manage templates',
                      style: AppText.sans(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.accent)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noNumberNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon('info', size: 15, color: AppColors.warn),
          const SizedBox(width: 8),
          Expanded(
            child: Text('This record has no phone number to message.',
                style: AppText.sans(
                    size: 12.5, color: AppColors.warn, height: 1.35)),
          ),
        ],
      ),
    );
  }

  Widget _emptyTemplates(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        'No templates yet. Tap "Manage templates" to add one.',
        style: AppText.sans(size: 13.5, color: AppColors.muted, height: 1.35),
      ),
    );
  }
}

/// A selectable recipient number (multi-number records).
class _NumberOption extends StatelessWidget {
  const _NumberOption({
    required this.phone,
    required this.selected,
    required this.onTap,
  });

  final TruckPhone phone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : AppColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.line,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(phone.label,
                        style: AppText.sans(
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: AppColors.muted)),
                    const SizedBox(height: 2),
                    Text(phone.pretty,
                        style: AppText.sans(
                            size: 16,
                            weight: FontWeight.w800,
                            letterSpacing: 0.3)),
                  ],
                ),
              ),
              AppIcon(selected ? 'check' : 'chevron',
                  size: 18,
                  color: selected ? AppColors.accent : AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tappable template — shows its title and a preview with the driver's
/// name already filled in, so the finder sees exactly what will be sent.
class _TemplateRow extends StatelessWidget {
  const _TemplateRow({
    required this.template,
    required this.driverName,
    required this.onTap,
  });

  final MessageTemplate template;
  final String driverName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = template.render(driverName: driverName);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.title,
                        style: AppText.sans(
                            size: 14.5, weight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(
                            size: 12.5,
                            color: AppColors.muted,
                            height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon('send', size: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
