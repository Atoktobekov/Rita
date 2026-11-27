import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/palette.dart';

// Original SVG paths from the supplied Figma export, in a 24 × 24 viewBox.
enum DesignSymbol {
  sun,
  archive,
  chart,
  award,
  plus,
  arrow,
  chevron,
  calendar,
  check,
  copy,
  close,
  edit,
  trash,
  settings,
  moon,
  bell,
  download,
  upload,
  lock,
  flame,
  star,
  bolt,
  target,
  leaf,
  coffee,
  trophy,
  today,
  bow,
}

const _pickMePaths = {
  DesignSymbol.archive: '<path d="M5 8v12h14V8M3 4h18v4H3zM10 12h4" />',
  DesignSymbol.chart: '<path d="M4 19.5h16M7 15v-4m5 4V5m5 10V8" />',
  DesignSymbol.award:
      '<path d="m12 3 2.7 5.5 6.1.9-4.4 4.3 1 6.1-5.4-2.9-5.4 2.9 1-6.1L3.2 9.4l6.1-.9z" />',
  DesignSymbol.calendar:
      '<rect x="3.5" y="5.5" width="17" height="15" rx="2.5" /><path d="M7.5 3.5v4m9-4v4m-13 3h17m-13 4h2m4 0h2" />',
};

const _paths = {
  DesignSymbol.today:
      '<path d="M5 4h14a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1Z" /><path d="m8 12 2.5 2.5L16 9" />',
  DesignSymbol.bow:
      '<path d="M42 26C32 12 13 5 9 15s8 21 20 19c5-.5 9-2 12-4m5-4C54 13 71 4 78 13c8 10-7 22-18 21-6 0-11-2-13-4M41 29c-8 7-9 24-23 25l7-6-8-1c11-3 15-10 16-13m14-5c2 14 4 22 20 28l-4-8 10 1c-12-5-17-10-19-17" /><path d="M40 23c2-2 6-2 8 0l1 6c-1 4-8 5-10 1zM16 17c7-2 15.5 3 21 8m34-9c-7-1-13 4-19 9" />',
  DesignSymbol.sun:
      '<circle cx="12" cy="12" r="4" /><path d="M12 2v2m0 16v2M2 12h2m16 0h2M5 5l1.5 1.5m11 11L19 19M5 19l1.5-1.5m11-11L19 5" />',
  DesignSymbol.archive:
      '<rect x="4" y="7" width="16" height="14" rx="2" /><path d="M3 3h18v4H3zM9 12h6" />',
  DesignSymbol.chart: '<path d="M4 3v18h17M9 16v-5m5 5V6m5 10V9" />',
  DesignSymbol.award:
      '<circle cx="12" cy="9" r="6" /><path d="m8 14-2 8 6-3 6 3-2-8m-6-5 1.4 1.4L14 8" />',
  DesignSymbol.plus: '<path d="M12 5v14M5 12h14" />',
  DesignSymbol.arrow: '<path d="M4 12h16m-6-6 6 6-6 6" />',
  DesignSymbol.chevron: '<path d="m9 5 7 7-7 7" />',
  DesignSymbol.calendar:
      '<rect x="3" y="5" width="18" height="16" rx="3" /><path d="M7 2v6m10-6v6M3 11h18m-14 4h2m4 0h2" />',
  DesignSymbol.check: '<path d="m5 12 4 4L19 6" />',
  DesignSymbol.copy:
      '<rect x="8" y="8" width="12" height="13" rx="2" /><path d="M15 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h3" />',
  DesignSymbol.close: '<path d="m6 6 12 12M6 18 18 6" />',
  DesignSymbol.edit:
      '<path d="m15 4 5 5-11 11H4v-5L15 4Z" /><path d="m12 7 5 5" />',
  DesignSymbol.trash:
      '<path d="M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7m4-7v7" />',
  DesignSymbol.settings:
      '<path d="M4 6h16M4 18h16M4 12h16" /><circle cx="9" cy="6" r="2" /><circle cx="15" cy="12" r="2" /><circle cx="9" cy="18" r="2" />',
  DesignSymbol.moon: '<path d="M20 15A9 9 0 0 1 9 4a9 9 0 1 0 11 11Z" />',
  DesignSymbol.bell: '<path d="M5 17h14l-2-4V9A5 5 0 0 0 7 9v4l-2 4Zm5 4h4" />',
  DesignSymbol.download: '<path d="M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5" />',
  DesignSymbol.upload: '<path d="M12 16V4m-5 5 5-5 5 5M4 16v5h16v-5" />',
  DesignSymbol.lock:
      '<rect x="5" y="10" width="14" height="11" rx="3" /><path d="M8 10V7a4 4 0 0 1 8 0v3m-4 5v2" />',
  DesignSymbol.flame:
      '<path d="M13 2c2 6-4 6-2 11 2-1 3-3 3-5 9 8 4 14-2 14S2 16 6 10c0 4 2 4 2 4C6 7 12 7 13 2Z" />',
  DesignSymbol.star:
      '<path d="m12 3 2.8 5.7 6.2.9-4.5 4.4 1 6.2-5.5-2.9-5.5 2.9 1-6.2L3 9.6l6.2-.9L12 3Z" />',
  DesignSymbol.bolt: '<path d="m13 2-9 12h7l-1 8 10-13h-7l1-7Z" />',
  DesignSymbol.target:
      '<circle cx="12" cy="12" r="9" /><circle cx="12" cy="12" r="5" /><circle cx="12" cy="12" r="1" />',
  DesignSymbol.leaf: '<path d="M20 3C5 1 1 10 6 16S22 17 20 3ZM4 21 16 8" />',
  DesignSymbol.coffee:
      '<path d="M4 8h13v9a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4V8Zm13 1h2a3 3 0 1 1 0 6h-2M7 2v2m5-2v2" />',
  DesignSymbol.trophy:
      '<circle cx="12" cy="9" r="6" /><path d="m8 14-2 8 6-3 6 3-2-8m-6-5 1.4 1.4L14 8" />',
};

class DesignIcon extends StatelessWidget {
  const DesignIcon(
    this.symbol, {
    super.key,
    this.size = 24,
    this.color,
    this.filled = false,
    this.stroke = 1.7,
  });

  final DesignSymbol symbol;
  final double size;
  final Color? color;
  final bool filled;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final path =
        (palette.pickMe ? _pickMePaths[symbol] : null) ?? _paths[symbol];
    final bow = symbol == DesignSymbol.bow;
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="${bow ? '0 0 88 64' : '0 0 24 24'}" fill="${filled ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="${bow ? 2.1 * stroke : stroke}" stroke-linecap="round" stroke-linejoin="round">${path}</svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color ?? palette.ink, BlendMode.srcIn),
    );
  }
}
