import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/message_template.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kit.dart';

/// Manage SMS templates — create, edit and delete the messages the finder
/// reuses when texting drivers. Bodies may use the `{name}` token, which is
/// swapped for the driver's name when a template is sent.
class MessageTemplatesScreen extends StatelessWidget {
  const MessageTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final templates = context.watch<AppState>().messageTemplates;
    return Scaffold(
      body: Column(
        children: [
          FlowHeader(
            title: 'Message templates',
            hi: 'मैसेज टेम्पलेट',
            lead: 'back',
            onLead: () => Navigator.pop(context),
          ),
          Expanded(
            child: templates.isEmpty
                ? _empty()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                    children: [
                      _hint(),
                      const SizedBox(height: 14),
                      for (final t in templates) ...[
                        _TemplateCard(template: t),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: Text('New template',
            style: AppText.sans(
                size: 14.5, weight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }

  Widget _hint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon('info', size: 15, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Type {name} anywhere in the message and it becomes the '
              "driver's name when you send it.",
              style: AppText.sans(
                  size: 12.5, color: AppColors.accent, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon('message', size: 40, color: AppColors.muted),
            const SizedBox(height: 12),
            Text('No templates yet',
                style: AppText.sans(size: 16, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Add a template and reuse it to text any driver.\n'
              'Use {name} for the driver\'s name.',
              textAlign: TextAlign.center,
              style: AppText.sans(
                  size: 13, color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});
  final MessageTemplate template;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(template.title,
                          style: AppText.sans(
                              size: 15, weight: FontWeight.w800)),
                    ),
                    if (template.hasNamePlaceholder) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('{name}',
                            style: AppText.sans(
                                size: 10.5,
                                weight: FontWeight.w800,
                                color: AppColors.accent)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(template.body,
                    style: AppText.sans(
                        size: 13, color: AppColors.muted, height: 1.35)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _openEditor(context, existing: template),
                icon: AppIcon('edit', size: 18, color: AppColors.muted),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _confirmDelete(context, template),
                icon: AppIcon('trash', size: 18, color: AppColors.bad),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, MessageTemplate t) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('Delete template?',
          style: AppText.sans(size: 16, weight: FontWeight.w800)),
      content: Text('"${t.title}" will be removed.',
          style: AppText.sans(size: 14, color: AppColors.muted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel',
              style: AppText.sans(
                  weight: FontWeight.w700, color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Delete',
              style:
                  AppText.sans(weight: FontWeight.w800, color: AppColors.bad)),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    await context.read<AppState>().removeTemplate(t.id);
  }
}

/// Opens the add/edit editor. Passing [existing] switches it to edit mode.
Future<void> _openEditor(BuildContext context, {MessageTemplate? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _TemplateEditor(existing: existing),
  );
}

class _TemplateEditor extends StatefulWidget {
  const _TemplateEditor({this.existing});
  final MessageTemplate? existing;

  @override
  State<_TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<_TemplateEditor> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _body =
      TextEditingController(text: widget.existing?.body ?? '');

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _title.text.trim().isNotEmpty && _body.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;
    final state = context.read<AppState>();
    if (widget.existing != null) {
      await state.updateTemplate(
          widget.existing!.id, _title.text, _body.text);
    } else {
      await state.addTemplate(_title.text, _body.text);
    }
    if (mounted) Navigator.pop(context);
  }

  void _insertNameToken() {
    final sel = _body.selection;
    final text = _body.text;
    // Insert at the caret when there is one, otherwise append.
    final at = sel.isValid ? sel.start : text.length;
    final next = '${text.substring(0, at)}{name}${text.substring(at)}';
    _body.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: at + 6),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final editing = widget.existing != null;
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
              Text(editing ? 'Edit template' : 'New template',
                  style: AppText.sans(size: 17, weight: FontWeight.w800)),
              const SizedBox(height: 16),
              const FieldLabel('Title', hi: 'नाम'),
              _boxed(
                child: TextField(
                  controller: _title,
                  maxLength: 40,
                  onChanged: (_) => setState(() {}),
                  style: AppText.sans(size: 15, weight: FontWeight.w600),
                  decoration: _plain('e.g. Ask if free today'),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const FieldLabel('Message', hi: 'संदेश'),
                  GestureDetector(
                    onTap: _insertNameToken,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('+ {name}',
                          style: AppText.sans(
                              size: 12,
                              weight: FontWeight.w800,
                              color: AppColors.accent)),
                    ),
                  ),
                ],
              ),
              _boxed(
                child: TextField(
                  controller: _body,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 900,
                  onChanged: (_) => setState(() {}),
                  style: AppText.sans(size: 15, weight: FontWeight.w500),
                  decoration: _plain(
                      'e.g. Namaste {name}, is your truck free today?'),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '{name} becomes the driver\'s name when you send.',
                style: AppText.sans(size: 11.5, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              PrimaryBtn(
                editing ? 'Save changes' : 'Add template',
                icon: 'check',
                disabled: !_canSave,
                onTap: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _boxed({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: child,
      );

  InputDecoration _plain(String hint) => InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        counterText: '',
        hintText: hint,
        hintStyle: AppText.sans(
            size: 14.5, weight: FontWeight.w500, color: AppColors.muted),
      );
}
