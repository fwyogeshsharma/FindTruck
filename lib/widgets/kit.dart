import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_icon.dart';

export 'app_icon.dart';

/// ─── Bilingual label (kit.jsx `Bi`) ──────────────────────────────────
class Bi extends StatelessWidget {
  const Bi({super.key, required this.en, this.hi, this.big = false});

  final String en;
  final String? hi;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(en,
            style: AppText.sans(
                size: 14,
                weight: big ? FontWeight.w700 : FontWeight.w600,
                height: 1.15)),
        if (hi != null)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(hi!, style: AppText.deva(size: 11)),
          ),
      ],
    );
  }
}

/// Diagonal-stripe placeholder fill (`repeating-linear-gradient(135deg…)`).
class _StripePainter extends CustomPainter {
  _StripePainter(this.dark);
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = dark ? const Color(0xFF1A1A1A) : AppColors.ph;
    canvas.drawRect(Offset.zero & size, bgPaint);
    final stripe = Paint()
      ..color = dark ? const Color(0xFF222222) : AppColors.ph2
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    const gap = 14.0;
    for (double d = -size.height; d < size.width + size.height; d += gap) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), stripe);
    }
  }

  @override
  bool shouldRepaint(covariant _StripePainter old) => old.dark != dark;
}

/// Square thumbnail placeholder (kit.jsx `Thumb`).
class ThumbBox extends StatelessWidget {
  const ThumbBox({super.key, this.size = 52, this.label = 'truck', this.radius = 12});

  final double size;
  final String label;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _StripePainter(false)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                    color: AppColors.card, borderRadius: BorderRadius.circular(4)),
                child: Text(label,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8.5,
                        color: AppColors.muted)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flexible placeholder (kit.jsx `Ph`).
class Ph extends StatelessWidget {
  const Ph(
      {super.key,
      this.width = double.infinity,
      this.height = 120,
      this.radius = 16,
      this.label = 'image',
      this.dark = false});

  final double width;
  final double height;
  final double radius;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
            color: dark ? Colors.white.withValues(alpha: 0.12) : AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _StripePainter(dark)),
          if (label.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: dark ? Colors.black.withValues(alpha: 0.4) : AppColors.card,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(label,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: dark
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppColors.muted)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Primary CTA button (kit.jsx `PrimaryBtn`).
class PrimaryBtn extends StatelessWidget {
  const PrimaryBtn(this.label,
      {super.key, this.icon, this.disabled = false, this.onTap});

  final String label;
  final String? icon;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = disabled ? AppColors.muted : Colors.white;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? AppColors.line : AppColors.accent,
          disabledBackgroundColor: AppColors.line,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              AppIcon(icon!, size: 20, color: fg),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: AppText.sans(size: 16, weight: FontWeight.w800, color: fg)),
          ],
        ),
      ),
    );
  }
}

class GhostBtn extends StatelessWidget {
  const GhostBtn(this.label, {super.key, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: TextButton(
        onPressed: onTap,
        child: Text(label,
            style:
                AppText.sans(size: 15, weight: FontWeight.w700, color: AppColors.muted)),
      ),
    );
  }
}

/// Round icon button (kit.jsx `IconBtn`).
class IconBtn extends StatelessWidget {
  const IconBtn(this.icon,
      {super.key, this.onDark = false, this.size = 40, this.onTap});

  final String icon;
  final bool onDark;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: onDark ? Colors.white.withValues(alpha: 0.25) : AppColors.line),
          color: onDark ? Colors.white.withValues(alpha: 0.12) : AppColors.card,
        ),
        child: AppIcon(icon, size: 20, color: onDark ? Colors.white : AppColors.ink),
      ),
    );
  }
}

/// Field label with optional Devanagari hint (kit.jsx `FieldLabel`).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key, this.hi});
  final String label;
  final String? hi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(label, style: AppText.sans(size: 13, weight: FontWeight.w700)),
          if (hi != null) ...[
            const SizedBox(width: 6),
            Text(hi!, style: AppText.deva(size: 11.5)),
          ],
        ],
      ),
    );
  }
}

/// Boxed text field. When [onChanged] is null it renders as the static
/// wireframe display field; otherwise it is a live input.
class Field extends StatefulWidget {
  const Field({
    super.key,
    this.label,
    this.hi,
    this.value,
    this.placeholder,
    this.prefix,
    this.hint,
    this.keyboardType,
    this.onChanged,
  });

  final String? label;
  final String? hi;
  final String? value;
  final String? placeholder;
  final String? prefix;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  State<Field> createState() => _FieldState();
}

class _FieldState extends State<Field> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.value);
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _focus.hasFocus;
    final interactive = widget.onChanged != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) FieldLabel(widget.label!, hi: widget.hi),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: active ? AppColors.accent : AppColors.line, width: 1.5),
              boxShadow: active
                  ? [const BoxShadow(color: AppColors.accentSoft, blurRadius: 0, spreadRadius: 3)]
                  : null,
            ),
            child: Row(
              children: [
                if (widget.prefix != null) ...[
                  Text(widget.prefix!,
                      style: AppText.sans(weight: FontWeight.w700)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: interactive
                      ? TextField(
                          controller: _ctrl,
                          focusNode: _focus,
                          keyboardType: widget.keyboardType,
                          onChanged: widget.onChanged,
                          style: AppText.sans(size: 15.5, weight: FontWeight.w600),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: widget.placeholder,
                            hintStyle: AppText.sans(
                                size: 15.5,
                                weight: FontWeight.w500,
                                color: AppColors.muted),
                          ),
                        )
                      : Text(
                          (widget.value?.isNotEmpty ?? false)
                              ? widget.value!
                              : (widget.placeholder ?? ''),
                          style: AppText.sans(
                              size: 15.5,
                              weight: (widget.value?.isNotEmpty ?? false)
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: (widget.value?.isNotEmpty ?? false)
                                  ? AppColors.ink
                                  : AppColors.muted),
                        ),
                ),
              ],
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

/// Segmented control (kit.jsx `SegToggle`).
class SegToggle extends StatelessWidget {
  const SegToggle({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final o in options) ...[
          if (o != options.first) const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(o),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: o == value ? AppColors.accent : AppColors.line,
                      width: 1.5),
                  color: o == value ? AppColors.accentSoft : AppColors.card,
                ),
                child: Center(
                  child: Text(o,
                      textAlign: TextAlign.center,
                      style: AppText.sans(
                          size: 15,
                          weight: FontWeight.w800,
                          color: o == value ? AppColors.accent : AppColors.ink)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Wrapping chip row (kit.jsx `ChipRow`).
class ChipRow extends StatelessWidget {
  const ChipRow({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        for (final o in options)
          GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(o),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: o == value ? AppColors.accent : AppColors.line,
                    width: 1.5),
                color: o == value ? AppColors.accent : AppColors.card,
              ),
              child: Text(o,
                  style: AppText.sans(
                      size: 15,
                      weight: FontWeight.w700,
                      color: o == value ? Colors.white : AppColors.ink)),
            ),
          ),
      ],
    );
  }
}

/// iOS-style switch (kit.jsx `Toggle`).
class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.on, this.onChanged});
  final bool on;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 46,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: on ? AppColors.accent : AppColors.line,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              top: 3,
              left: on ? 21 : 3,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2), blurRadius: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top header with optional back/close lead button (kit.jsx `FlowHeader`).
class FlowHeader extends StatelessWidget {
  const FlowHeader({
    super.key,
    this.title,
    this.hi,
    this.lead,
    this.step,
    this.onLead,
  });

  final String? title;
  final String? hi;
  final String? lead; // 'back' | 'close'
  final String? step;
  final VoidCallback? onLead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          if (lead != null) ...[
            IconBtn(lead == 'close' ? 'close' : 'back', onTap: onLead),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(title!,
                      style: AppText.sans(size: 18, weight: FontWeight.w800)),
                if (hi != null) Text(hi!, style: AppText.deva(size: 12.5)),
              ],
            ),
          ),
          if (step != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: AppColors.bg, borderRadius: BorderRadius.circular(999)),
              child: Text(step!,
                  style: AppText.sans(
                      size: 12, weight: FontWeight.w700, color: AppColors.muted)),
            ),
        ],
      ),
    );
  }
}

/// Footer action bar (kit.jsx `BottomBar`).
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in children) ...[
            if (c != children.first) const SizedBox(height: 9),
            c,
          ],
        ],
      ),
    );
  }
}
