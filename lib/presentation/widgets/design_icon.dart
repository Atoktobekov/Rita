import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/palette.dart';

// Original SVG paths from the supplied Figma export, in a 24 × 24 viewBox.
enum DesignSymbol {
  check,
  plus,
  sun,
  archive,
  chart,
  trophy,
  bell,
  moon,
  trash,
  flame,
  chevron,
  settings,
  calendar,
}

const _paths = {
  DesignSymbol.calendar:
      'M8 2v4m8-4v4M3 10h18M5 4h14a2 2 0 012 2v14a2 2 0 01-2 2H5a2 2 0 01-2-2V6a2 2 0 012-2z',
  DesignSymbol.settings:
      'M19.4 15a1.7 1.7 0 00.3 1.8l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.7 1.7 0 00-1.8-.3 1.7 1.7 0 00-1 1.5V21a2 2 0 11-4 0v-.1a1.7 1.7 0 00-1.1-1.5 1.7 1.7 0 00-1.8.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.7 1.7 0 00.3-1.8 1.7 1.7 0 00-1.5-1H3a2 2 0 110-4h.1a1.7 1.7 0 001.5-1.1 1.7 1.7 0 00-.3-1.8l-.1-.1a2 2 0 112.8-2.8l.1.1a1.7 1.7 0 001.8.3H9a1.7 1.7 0 001-1.5V3a2 2 0 114 0v.1a1.7 1.7 0 001 1.5 1.7 1.7 0 001.8-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.7 1.7 0 00-.3 1.8V9a1.7 1.7 0 001.5 1H21a2 2 0 110 4h-.1a1.7 1.7 0 00-1.5 1z M15 12a3 3 0 1 0-6 0a3 3 0 1 0 6 0',
  DesignSymbol.check: 'M5 12.5l4.5 4.5L19 7.5',
  DesignSymbol.plus: 'M12 5v14M5 12h14',
  DesignSymbol.sun:
      'M12 4V2m0 20v-2m8-8h2M2 12h2m13.7-5.7l1.4-1.4M4.9 19.1l1.4-1.4m0-11.4L4.9 4.9m14.2 14.2l-1.4-1.4M12 8a4 4 0 100 8 4 4 0 000-8z',
  DesignSymbol.archive: 'M4 7h16v3H4zM5 10v9h14v-9M10 14h4',
  DesignSymbol.chart: 'M5 20V10m7 10V4m7 16v-7',
  DesignSymbol.trophy:
      'M8 4h8v6a4 4 0 01-8 0V4zM8 6H4v1a4 4 0 004 4m8-5h4v1a4 4 0 01-4 4M12 14v4m-3 2h6',
  DesignSymbol.bell: 'M6 16V11a6 6 0 1112 0v5l2 2H4l2-2zm4 4a2 2 0 004 0',
  DesignSymbol.moon: 'M20 14.5A8 8 0 019.5 4a8 8 0 1010.5 10.5z',
  DesignSymbol.trash: 'M5 7h14M10 7V4h4v3m-7 0l1 13h8l1-13',
  DesignSymbol.flame:
      'M12 3c1 4 5 5.5 5 10a5 5 0 01-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-3-1-6 1-9z',
  DesignSymbol.chevron: 'M9 6l6 6-6 6',
};

class DesignIcon extends StatelessWidget {
  const DesignIcon(
    this.symbol, {
    super.key,
    this.size = 24,
    this.color,
    this.filled = false,
    this.stroke = 1.8,
  });

  final DesignSymbol symbol;
  final double size;
  final Color? color;
  final bool filled;
  final double stroke;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="${filled ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="$stroke" stroke-linecap="round" stroke-linejoin="round"><path d="${_paths[symbol]}"/></svg>',
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(
      color ?? AppPalette.of(context).ink,
      BlendMode.srcIn,
    ),
  );
}
