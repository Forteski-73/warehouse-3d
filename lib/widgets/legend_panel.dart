import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../state/warehouse_controller.dart';
import 'glass_panel.dart';

class LegendPanel extends StatelessWidget {
  const LegendPanel({super.key, required this.controller});

  final WarehouseController controller;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return GlassPanel(
          constraints: const BoxConstraints(maxWidth: 230, maxHeight: 320),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.mode.name == 'real' ? 'RUAS (BLOCO / QUADRA)' : 'SETORES',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: palette.textDim,
                  ),
                ),
                const SizedBox(height: 8),
                for (final s in controller.streets)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: s.cor, borderRadius: BorderRadius.circular(3)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.nome,
                            style: TextStyle(fontSize: 12, color: palette.text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
