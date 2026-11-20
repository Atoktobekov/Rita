import 'dart:ui' show FontVariation, ImageFilter;
import 'package:flutter/material.dart';
import '../theme/palette.dart';
import 'design_icon.dart';

TextStyle designText(
  double size, {
  Color? color,
  double height = 1.5,
  double weight = 400,
  double spacing = 0,
  String font = 'Golos Text',
}) => TextStyle(
  fontFamily: font,
  fontFamilyFallback: font == 'DM Sans' ? const ['Golos Text'] : null,
  fontSize: size,
  height: height,
  letterSpacing: spacing,
  fontVariations: [FontVariation('wght', weight)],
  color: color,
);

class DesignHeader extends StatelessWidget {
  const DesignHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.mark,
    this.action,
    this.day = false,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? mark;
  final Widget? action;
  final bool day;

  @override
  Widget build(BuildContext context) {
    final c = AppPalette.of(context);
    return Padding(
      padding: EdgeInsets.only(top: day ? 19 : 27, bottom: day ? 16 : 25),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: designText(
                    10,
                    color: c.muted,
                    weight: 500,
                    spacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(child: Text(title, style: c.heading)),
                    if (mark != null) ...[
                      SizedBox(width: day ? 17 : 14),
                      mark!,
                    ],
                  ],
                ),
                SizedBox(height: day && c.editorial ? 10 : 6),
                Text(
                  subtitle,
                  style:
                      designText(
                        13,
                        color: c.muted,
                        height: 1.6,
                        font: day && c.editorial ? 'Literata' : 'Golos Text',
                      ).copyWith(
                        fontStyle: day && c.editorial
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class DesignButton extends StatelessWidget {
  const DesignButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final DesignSymbol icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = AppPalette.of(context);
    final radius = BorderRadius.circular(
      primary
          ? 13
          : c.editorial
          ? 5
          : c.radius,
    );
    final ink = primary ? (c.dark ? c.paper : c.ink) : c.onAction;
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: c.playful && !primary
            ? [const BoxShadow(color: Color(0xFFAA96D7), offset: Offset(0, 3))]
            : null,
      ),
      child: Material(
        color: primary ? c.accent : c.action,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: Container(
            constraints: BoxConstraints(
              minHeight: primary
                  ? 54
                  : c.strict
                  ? 52
                  : c.playful
                  ? 49
                  : 50,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!primary) ...[
                  DesignIcon(icon, size: 21, color: ink),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: designText(
                      13,
                      weight: c.strict && !primary ? 650 : 550,
                      color: ink,
                    ),
                  ),
                ),
                if (primary) ...[
                  const SizedBox(width: 12),
                  DesignIcon(icon, size: 19, color: ink),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showDesignSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool enableDrag = true,
}) {
  final navigator = Navigator.of(context);
  final localizations = MaterialLocalizations.of(context);
  return navigator.push(
    _DesignSheetRoute<T>(
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      barrierLabel: localizations.scrimLabel,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: builder(context),
      ),
      enableDrag: enableDrag,
    ),
  );
}

class _DesignSheetRoute<T> extends ModalBottomSheetRoute<T> {
  _DesignSheetRoute({
    required super.builder,
    required super.capturedThemes,
    required super.barrierLabel,
    required super.enableDrag,
  }) : super(
         isScrollControlled: true,
         useSafeArea: true,
         modalBarrierColor: const Color(0x55221D28),
         constraints: const BoxConstraints(maxWidth: 430),
         sheetAnimationStyle: const AnimationStyle(
           duration: Duration(milliseconds: 250),
         ),
       );

  @override
  Widget buildModalBarrier() => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
    child: super.buildModalBarrier(),
  );
}

class DesignSheet extends StatelessWidget {
  const DesignSheet({
    super.key,
    required this.title,
    required this.children,
    this.controller,
  });

  final String title;
  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final c = AppPalette.of(context);
    return SingleChildScrollView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 35,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 35,
              height: 4,
              decoration: BoxDecoration(
                color: c.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: designText(
                    20,
                    weight: 550,
                    spacing: -.5,
                    color: c.ink,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Закрыть',
                onPressed: () => Navigator.maybePop(context),
                icon: DesignIcon(DesignSymbol.close, size: 20, color: c.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class SheetAction extends StatelessWidget {
  const SheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final DesignSymbol icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = AppPalette.of(context);
    final ink = danger ? const Color(0xFFB45F4E) : c.ink;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 65),
        decoration: BoxDecoration(
          border: danger ? null : Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            DesignIcon(icon, size: 22, color: ink),
            const SizedBox(width: 13),
            Expanded(
              child: Text(label, style: designText(14, color: ink)),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
