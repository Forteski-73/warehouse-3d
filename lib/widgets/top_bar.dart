import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/warehouse_models.dart';
import '../state/warehouse_controller.dart';
import 'glass_panel.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.controller,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final WarehouseController controller;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final freeSlots = controller.built.length - controller.occupied.length;
        final mismatchCount = controller.pallets.where((p) => p.mismatch).length;

        return GlassPanel(
          borderRadius: 16,
          padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
          child: Wrap(
            spacing: 20,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.view_in_ar_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('WMS 3D — Painel do Engenheiro',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: palette.text)),
                      SizedBox(
                        width: 320,
                        child: Text(
                          controller.mode.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: palette.textDim),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _KpiChip(icon: Icons.inventory_2_outlined, label: '${controller.pallets.length}', tooltip: 'Paletes'),
                  const SizedBox(width: 8),
                  _KpiChip(icon: Icons.grid_view_rounded, label: '$freeSlots', tooltip: 'Vagas livres conhecidas'),
                  const SizedBox(width: 8),
                  _KpiChip(icon: Icons.signpost_outlined, label: '${controller.streets.length}', tooltip: 'Ruas'),
                  if (mismatchCount > 0) ...[
                    const SizedBox(width: 8),
                    _KpiChip(
                      icon: Icons.warning_amber_rounded,
                      label: '$mismatchCount',
                      tooltip: 'Paletes fora do setor',
                      color: palette.warn,
                    ),
                  ],
                ],
              ),
              SegmentedButton<DatasetMode>(
                segments: const [
                  ButtonSegment(value: DatasetMode.real, label: Text('Estoque real'), icon: Icon(Icons.storage_rounded, size: 15)),
                  ButtonSegment(
                      value: DatasetMode.simulated, label: Text('Protótipo simulado'), icon: Icon(Icons.science_outlined, size: 15)),
                ],
                selected: {controller.mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => controller.switchDataset(s.first),
              ),
              IconButton.filledTonal(
                tooltip: themeMode == ThemeMode.dark ? 'Tema claro' : 'Tema escuro',
                onPressed: onToggleTheme,
                icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({required this.icon, required this.label, required this.tooltip, this.color});

  final IconData icon;
  final String label;
  final String tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final c = color ?? palette.accent;
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
          ],
        ),
      ),
    );
  }
}
