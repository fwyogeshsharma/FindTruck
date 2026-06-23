import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'kit.dart';

/// Password input styled to match the kit [Field], with a show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    required this.hi,
    required this.controller,
    this.hint = '••••••••',
  });

  final String label;
  final String hi;
  final TextEditingController controller;
  final String hint;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  final _focus = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _focus.hasFocus;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(widget.label, hi: widget.hi),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: active ? AppColors.accent : AppColors.line, width: 1.5),
              boxShadow: active
                  ? [const BoxShadow(color: AppColors.accentSoft, spreadRadius: 3)]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    obscureText: _obscure,
                    style: AppText.sans(size: 15.5, weight: FontWeight.w600),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: widget.hint,
                      hintStyle: AppText.sans(
                          size: 15.5,
                          weight: FontWeight.w500,
                          color: AppColors.muted),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Plain text input wired to an external controller (matches the kit [Field]).
class TextFieldBox extends StatefulWidget {
  const TextFieldBox({
    super.key,
    required this.label,
    required this.hi,
    required this.controller,
    this.placeholder,
    this.keyboardType,
    this.hint,
  });

  final String label;
  final String hi;
  final TextEditingController controller;
  final String? placeholder;
  final TextInputType? keyboardType;
  final String? hint;

  @override
  State<TextFieldBox> createState() => _TextFieldBoxState();
}

class _TextFieldBoxState extends State<TextFieldBox> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _focus.hasFocus;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(widget.label, hi: widget.hi),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: active ? AppColors.accent : AppColors.line, width: 1.5),
              boxShadow: active
                  ? [const BoxShadow(color: AppColors.accentSoft, spreadRadius: 3)]
                  : null,
            ),
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: widget.keyboardType,
              style: AppText.sans(size: 15.5, weight: FontWeight.w600),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.placeholder,
                hintStyle: AppText.sans(
                    size: 15.5, weight: FontWeight.w500, color: AppColors.muted),
              ),
            ),
          ),
          if (widget.hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(widget.hint!,
                  style: AppText.sans(size: 11.5, color: AppColors.muted)),
            ),
        ],
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.badBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bad.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          AppIcon('info', size: 18, color: AppColors.bad),
          const SizedBox(width: 9),
          Expanded(
            child: Text(message,
                style: AppText.sans(
                    size: 12.5, weight: FontWeight.w600, color: AppColors.bad)),
          ),
        ],
      ),
    );
  }
}
