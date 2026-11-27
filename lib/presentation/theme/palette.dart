import 'dart:ui' show FontVariation;
import 'package:flutter/material.dart';

enum AppDesign {
  warm('Уют', 'Персиковое тепло и мягкие формы'),
  strict('Фокус', 'Графит, лайм и чёткие линии'),
  play('Искра', 'Сирень, объём и маленькие победы'),
  editorial('Лист', 'Бумага, чернила и книжные заголовки'),
  pickMe('Пикми', 'Вишнёвые чернила, кремовая бумага и бантики');

  const AppDesign(this.title, this.description);
  final String title;
  final String description;

  static AppDesign fromStorage(Object? value) =>
      values.firstWhere((design) => design.name == value, orElse: () => warm);
}

/// Shared visual tokens for the application designs. Stored on ThemeData,
/// so routes, dialogs and bottom sheets inherit the selected design as well.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette._({
    required this.design,
    required this.dark,
    required this.paper,
    required this.card,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.cream,
    required this.sage,
    required this.sand,
    required this.line,
    required this.done,
    required this.strong,
    required this.positive,
    required this.celebration,
  });

  factory AppPalette(bool dark, {AppDesign design = AppDesign.warm}) {
    return switch ((design, dark)) {
      (AppDesign.pickMe, false) => AppPalette._(
        design: design,
        dark: dark,
        paper: const Color(0xFFFFF8EF),
        card: const Color(0xFFFAF0EC),
        ink: const Color(0xFF502334),
        muted: const Color(0xFF744655),
        accent: const Color(0xFF802342),
        cream: const Color(0xFFF6E4E5),
        sage: const Color(0xFFF2DAE0),
        sand: const Color(0xFFF8EDEF),
        line: const Color(0xFFD6A3AE),
        done: const Color(0xFFF4E8E6),
        strong: const Color(0xFF9D3157),
        positive: const Color(0xFFF6E4E5),
        celebration: const Color(0xFFF2DAE0),
      ),
      (AppDesign.pickMe, true) => AppPalette._(
        design: design,
        dark: dark,
        paper: const Color(0xFF291B29),
        card: const Color(0xFF332030),
        ink: const Color(0xFFF7DEDC),
        muted: const Color(0xFFD5AEB9),
        accent: const Color(0xFFE9A0B7),
        cream: const Color(0xFF392435),
        sage: const Color(0xFF513045),
        sand: const Color(0xFF30202F),
        line: const Color(0xFF82566D),
        done: const Color(0xFF362633),
        strong: const Color(0xFFF0A3BD),
        positive: const Color(0xFF392435),
        celebration: const Color(0xFF513045),
      ),
      (AppDesign.warm, false) => AppPalette._(
        design: design,
        dark: dark,
        paper: const Color(0xFFFFFDFA),
        card: const Color(0xFFFFFFFF),
        ink: const Color(0xFF473A31),
        muted: const Color(0xFF7B6D61),
        accent: const Color(0xFFFFCF94),
        cream: const Color(0xFFFFF1DF),
        sage: const Color(0xFFFFEAD0),
        sand: const Color(0xFFFBF7F0),
        line: const Color(0xFFEEE6DB),
        done: const Color(0xFFF4F2EE),
        strong: const Color(0xFF98602B),
        positive: const Color(0xFFEDF1E4),
        celebration: const Color(0xFFFBEBDD),
      ),
      (AppDesign.warm, true) => AppPalette._(
        design: design,
        dark: dark,
        paper: const Color(0xFF25221F),
        card: const Color(0xFF302B27),
        ink: const Color(0xFFF3E8DA),
        muted: const Color(0xFFBCAD9D),
        accent: const Color(0xFFE8B879),
        cream: const Color(0xFF49392B),
        sage: const Color(0xFF51412B),
        sand: const Color(0xFF302B25),
        line: const Color(0xFF443B32),
        done: const Color(0xFF2D2925),
        strong: const Color(0xFFE8B879),
        positive: const Color(0xFF303A2D),
        celebration: const Color(0xFF483327),
      ),
      (AppDesign.strict, true) => AppPalette._(
        design: design,
        dark: dark,
        paper: const Color(0xFF191C18),
        card: const Color(0xFF242922),
        ink: const Color(0xFFEDF2E6),
        muted: const Color(0xFFAFC0A6),
        accent: const Color(0xFFC7E870),
        cream: const Color(0xFF323C2A),
        sage: const Color(0xFF38452B),
        sand: const Color(0xFF2A3027),
        line: const Color(0xFF414B3B),
        done: const Color(0xFF252A23),
        strong: const Color(0xFFC7E870),
        positive: const Color(0xFF2D3E29),
        celebration: const Color(0xFF394329),
      ),
      (AppDesign.play, true) => AppPalette._(
        design: design,
        dark: dark,
        paper: const Color(0xFF241C30),
        card: const Color(0xFF30263F),
        ink: const Color(0xFFF4EAFF),
        muted: const Color(0xFFCBBADB),
        accent: const Color(0xFFCCB2FF),
        cream: const Color(0xFF403050),
        sage: const Color(0xFF49355C),
        sand: const Color(0xFF362B46),
        line: const Color(0xFF51435F),
        done: const Color(0xFF302939),
        strong: const Color(0xFFD3B9FF),
        positive: const Color(0xFF293C38),
        celebration: const Color(0xFF4B3044),
      ),
      (AppDesign.editorial, true) => AppPalette._(
        design: design,
        dark: dark,
        paper: const Color(0xFF192328),
        card: const Color(0xFF232F35),
        ink: const Color(0xFFE6F0F2),
        muted: const Color(0xFFAFC1C7),
        accent: const Color(0xFFA3CCDF),
        cream: const Color(0xFF2E4048),
        sage: const Color(0xFF30464F),
        sand: const Color(0xFF29373E),
        line: const Color(0xFF40535A),
        done: const Color(0xFF263137),
        strong: const Color(0xFFA3CCDF),
        positive: const Color(0xFF2A3C38),
        celebration: const Color(0xFF30414C),
      ),
      (AppDesign.strict, false) => AppPalette._(
        design: design,
        dark: dark,
        paper: const Color(0xFFF5F5EF),
        card: const Color(0xFFFDFDF9),
        ink: const Color(0xFF282B27),
        muted: const Color(0xFF696E62),
        accent: const Color(0xFFD5EF78),
        cream: const Color(0xFFEAF0D8),
        sage: const Color(0xFFD5EF78),
        sand: const Color(0xFFEDEEE5),
        line: const Color(0xFFDDDFD4),
        done: const Color(0xFFE9EAE3),
        strong: const Color(0xFF526900),
        positive: const Color(0xFFEAF0D8),
        celebration: const Color(0xFFEAF0D8),
      ),
      (AppDesign.play, false) => AppPalette._(
        design: design,
        dark: dark,
        paper: const Color(0xFFFBF9FF),
        card: const Color(0xFFFFFFFF),
        ink: const Color(0xFF413652),
        muted: const Color(0xFF796889),
        accent: const Color(0xFFC5B5F4),
        cream: const Color(0xFFEEE7FF),
        sage: const Color(0xFFEEE7FF),
        sand: const Color(0xFFF0EAF9),
        line: const Color(0xFFE9E2F3),
        done: const Color(0xFFF0ECF6),
        strong: const Color(0xFF7655A2),
        positive: const Color(0xFFEDF1E4),
        celebration: const Color(0xFFFBEBDD),
      ),
      (AppDesign.editorial, false) => AppPalette._(
        design: design,
        dark: dark,
        paper: const Color(0xFFF4F3ED),
        card: const Color(0xFFFAFAF6),
        ink: const Color(0xFF2E4650),
        muted: const Color(0xFF637579),
        accent: const Color(0xFFAEC8D4),
        cream: const Color(0xFFE3EBEB),
        sage: const Color(0xFFE3EBEB),
        sand: const Color(0xFFE9EEEA),
        line: const Color(0xFFDFE3DD),
        done: const Color(0xFFE9ECE6),
        strong: const Color(0xFF4E7282),
        positive: const Color(0xFFE3E9E4),
        celebration: const Color(0xFFE3EBEB),
      ),
    };
  }

  final AppDesign design;
  final bool dark;
  final Color paper;
  final Color card;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color cream;
  final Color sage;
  final Color sand;
  final Color line;
  final Color done;
  final Color strong;
  final Color positive;
  final Color celebration;

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ??
      AppPalette(Theme.of(context).brightness == Brightness.dark);

  bool get lined => design == AppDesign.strict || design == AppDesign.editorial;
  bool get pickMe => design == AppDesign.pickMe;
  bool get playful => design == AppDesign.play;
  double get radius => switch (design) {
    AppDesign.pickMe => 7,
    AppDesign.warm => 17,
    AppDesign.strict => 5,
    AppDesign.play => 21,
    AppDesign.editorial => 9,
  };
  double get navRadius => lined
      ? 4
      : pickMe
      ? 6
      : playful
      ? 19
      : 14;
  Color get navHighlight => design == AppDesign.strict ? accent : cream;
  double get taskGap => lined
      ? 0
      : playful
      ? 9
      : 8;
  double get chartRadius => lined ? 1 : 6;
  bool get editorial => design == AppDesign.editorial;
  bool get strict => design == AppDesign.strict;
  Color get action => design == AppDesign.editorial ? ink : accent;
  Color get onAction => pickMe
      ? (dark ? const Color(0xFF371726) : const Color(0xFFFFF7F3))
      : editorial || dark
      ? paper
      : ink;
  Color get selectedSegment => dark ? accent : card;
  Color get onSelectedSegment => dark ? paper : ink;
  Color get hero => strict && !dark
      ? ink
      : playful && !dark
      ? const Color(0xFFE9E0FA)
      : cream;
  Color get onHero => strict && !dark ? paper : ink;
  Color get heroAccent => pickMe
      ? strong
      : playful
      ? const Color(0xFFA58BDC)
      : accent;
  static const pickMeFont = 'Cormorant Garamond';

  Color pickMeChartBar({required bool latest}) => latest
      ? (dark ? const Color(0xFFF5ABCD) : const Color(0xFF922B53))
      : (dark ? const Color(0xFFC17C9F) : const Color(0xFFBA6885));

  TextStyle get heading => pickMe
      ? TextStyle(
          fontFamily: pickMeFont,
          fontSize: 36,
          height: 1.08,
          letterSpacing: -.8,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
          color: ink,
        )
      : TextStyle(
          fontFamily: editorial ? 'Literata' : 'Golos Text',
          fontSize: strict
              ? 33
              : playful
              ? 31
              : 29,
          height: 1.3,
          letterSpacing: strict
              ? -1.5
              : playful
              ? -1.2
              : -1,
          fontWeight: editorial
              ? FontWeight.w400
              : strict || playful
              ? FontWeight.w700
              : FontWeight.w600,
          fontVariations: [
            FontVariation(
              'wght',
              editorial
                  ? 400
                  : strict || playful
                  ? 750
                  : 600,
            ),
          ],
          color: ink,
        );

  BoxDecoration panel({Color? color, bool flat = false}) => BoxDecoration(
    color: flat ? Colors.transparent : color ?? card,
    borderRadius: flat ? null : BorderRadius.circular(radius),
    border: flat
        ? Border(bottom: BorderSide(color: line))
        : Border.all(color: line),
    boxShadow: playful && !flat
        ? [BoxShadow(color: line, offset: const Offset(0, 3))]
        : null,
  );

  Color inkOpacity(double opacity) => ink.withValues(alpha: opacity);

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette._(
      design: t < .5 ? design : other.design,
      dark: t < .5 ? dark : other.dark,
      paper: Color.lerp(paper, other.paper, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      sand: Color.lerp(sand, other.sand, t)!,
      line: Color.lerp(line, other.line, t)!,
      done: Color.lerp(done, other.done, t)!,
      strong: Color.lerp(strong, other.strong, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      celebration: Color.lerp(celebration, other.celebration, t)!,
    );
  }
}
