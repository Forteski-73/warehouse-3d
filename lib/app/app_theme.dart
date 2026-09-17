import 'package:flutter/material.dart';

/// Design tokens ported from the two HTML prototypes' `:root` CSS variables,
/// exposed as a [ThemeExtension] so any widget can reach them via
/// `Theme.of(context).extension<AppPalette>()!`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color panelBg;
  final Color panelBorder;
  final Color text;
  final Color textDim;
  final Color accent;
  final Color warn;

  const AppPalette({
    required this.background,
    required this.panelBg,
    required this.panelBorder,
    required this.text,
    required this.textDim,
    required this.accent,
    required this.warn,
  });

  static const dark = AppPalette(
    background: Color(0xFF0F1420),
    panelBg: Color(0xEB141A28),
    panelBorder: Color(0x1FFFFFFF),
    text: Color(0xFFEEF1F8),
    textDim: Color(0xFF9AA4B8),
    accent: Color(0xFF5B8DEF),
    warn: Color(0xFFE05252),
  );

  static const light = AppPalette(
    background: Color(0xFFEEF1F6),
    panelBg: Color(0xF0FFFFFF),
    panelBorder: Color(0x1A000000),
    text: Color(0xFF1A2030),
    textDim: Color(0xFF5A6478),
    accent: Color(0xFF3A6FD8),
    warn: Color(0xFFC92F2F),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? panelBg,
    Color? panelBorder,
    Color? text,
    Color? textDim,
    Color? accent,
    Color? warn,
  }) {
    return AppPalette(
      background: background ?? this.background,
      panelBg: panelBg ?? this.panelBg,
      panelBorder: panelBorder ?? this.panelBorder,
      text: text ?? this.text,
      textDim: textDim ?? this.textDim,
      accent: accent ?? this.accent,
      warn: warn ?? this.warn,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      panelBg: Color.lerp(panelBg, other.panelBg, t)!,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t)!,
      text: Color.lerp(text, other.text, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
    );
  }
}

ThemeData buildAppTheme(Brightness brightness) {
  final palette = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final scheme = ColorScheme.fromSeed(seedColor: palette.accent, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    textTheme: Typography.material2021(platform: TargetPlatform.windows).black.apply(
          bodyColor: palette.text,
          displayColor: palette.text,
        ),
    extensions: [palette],
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    ),
    tooltipTheme: const TooltipThemeData(waitDuration: Duration(milliseconds: 400)),
  );
}
