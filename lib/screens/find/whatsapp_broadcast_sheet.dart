import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../models/truck.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kit.dart';

/// Bottom sheet that composes one common message and broadcasts it to the
/// selected trucks' drivers over WhatsApp (via the backend relay).
///
/// Returns the number of messages the backend accepted (via [Navigator.pop])
/// so the caller can clear its selection and show a confirmation.
class WhatsAppBroadcastSheet extends StatefulWidget {
  const WhatsAppBroadcastSheet({super.key, required this.trucks});

  final List<Truck> trucks;

  /// Opens the sheet. Resolves to the sent count, or null if dismissed.
  static Future<int?> show(BuildContext context, List<Truck> trucks) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => WhatsAppBroadcastSheet(trucks: trucks),
    );
  }

  @override
  State<WhatsAppBroadcastSheet> createState() => _WhatsAppBroadcastSheetState();
}

class _WhatsAppBroadcastSheetState extends State<WhatsAppBroadcastSheet> {
  final TextEditingController _msg = TextEditingController();
  bool _sending = false;
  String? _error;

  /// Selected trucks that actually have a phone number to message.
  late final List<Truck> _reachable =
      widget.trucks.where((t) => t.phone.trim().isNotEmpty).toList();

  int get _noNumber => widget.trucks.length - _reachable.length;

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msg.text.trim();
    if (text.isEmpty || _reachable.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final result = await context.read<AppState>().repo.broadcastWhatsApp(
            phones: _reachable.map((t) => t.phone.trim()).toList(),
            message: text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(result.sent);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not send. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canSend =
        !_sending && _reachable.isNotEmpty && _msg.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.whatsapp,
                      shape: BoxShape.circle,
                    ),
                    child: AppIcon('whatsapp', size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Message ${_reachable.length} drivers',
                            style: AppText.sans(
                                size: 17, weight: FontWeight.w800)),
                        Text('एक ही मैसेज सबको',
                            style: AppText.deva(size: 11.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const FieldLabel('Your message', hi: 'आपका संदेश'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line, width: 1.5),
                ),
                child: TextField(
                  controller: _msg,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 900,
                  onChanged: (_) => setState(() {}),
                  style: AppText.sans(size: 15, weight: FontWeight.w500),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    counterText: '',
                    hintText:
                        'e.g. Namaste, do you have a truck free from Agra today? '
                        'Reply here to confirm.',
                    hintStyle: AppText.sans(
                        size: 14.5,
                        weight: FontWeight.w500,
                        color: AppColors.muted),
                  ),
                ),
              ),
              if (_noNumber > 0) ...[
                const SizedBox(height: 10),
                _note(
                  icon: 'info',
                  color: AppColors.warn,
                  bg: AppColors.warnBg,
                  text: '$_noNumber selected truck(s) have no phone number and '
                      'will be skipped.',
                ),
              ],
              const SizedBox(height: 10),
              _note(
                icon: 'shield',
                color: AppColors.muted,
                bg: AppColors.bg,
                text: 'Sent from your business WhatsApp. Drivers who never '
                    'messaged you first receive it as an approved template.',
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                _note(
                  icon: 'info',
                  color: AppColors.bad,
                  bg: AppColors.badBg,
                  text: _error!,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canSend ? _send : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whatsapp,
                    disabledBackgroundColor: AppColors.line,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon('send',
                                size: 19,
                                color: canSend
                                    ? Colors.white
                                    : AppColors.muted),
                            const SizedBox(width: 8),
                            Text('Send to ${_reachable.length}',
                                style: AppText.sans(
                                    size: 16,
                                    weight: FontWeight.w800,
                                    color: canSend
                                        ? Colors.white
                                        : AppColors.muted)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _note({
    required String icon,
    required Color color,
    required Color bg,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: AppText.sans(size: 12, color: color, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
