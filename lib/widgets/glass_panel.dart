import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Floating "glass" panel matching the HTML prototypes' translucent panel
/// styling. Uses a solid translucent fill rather than a true Gaussian blur
/// (`BackdropFilter`/`ImageFilter.blur`) — that combination is a known weak
/// spot on some Android GPU drivers (observed hanging the whole frame on a
/// MediaTek/Vulkan device), and the flat translucent look is safer across
/// devices while still reading as "glass" over the 3D scene.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = 14,
    this.constraints,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Container(
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.panelBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: palette.panelBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: palette.text),
        child: child,
      ),
    );
  }
}
