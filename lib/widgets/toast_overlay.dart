import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../state/toast_controller.dart';
import 'glass_panel.dart';

class ToastOverlay extends StatelessWidget {
  const ToastOverlay({super.key, required this.toasts});

  final ToastController toasts;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return AnimatedBuilder(
      animation: toasts,
      builder: (context, _) {
        final msg = toasts.message;
        return AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: msg == null ? const Offset(0, -1.6) : Offset.zero,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: msg == null ? 0 : 1,
            child: GlassPanel(
              borderRadius: 10,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Text(msg ?? '', style: TextStyle(fontSize: 12.5, color: palette.text)),
            ),
          ),
        );
      },
    );
  }
}
