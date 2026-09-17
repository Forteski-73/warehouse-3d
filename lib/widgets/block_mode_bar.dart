import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../state/warehouse_controller.dart';
import 'glass_panel.dart';

const _blockAccent = Color(0xFFB985E6);

/// Bottom-center controls for the "move whole streets as a block" sub-mode:
/// a toggle button (only while edit mode is active) and, once one or more
/// streets are selected, a small toolbar to rotate or clear the selection.
class BlockModeBar extends StatelessWidget {
  const BlockModeBar({super.key, required this.controller});

  final WarehouseController controller;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.editMode) return const SizedBox.shrink();
        final showToolbar = controller.blockMode && controller.selectedRuas.isNotEmpty;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showToolbar) ...[
              _BlockToolbar(controller: controller, palette: palette),
              const SizedBox(height: 10),
            ],
            _BlockToggleButton(controller: controller, palette: palette),
          ],
        );
      },
    );
  }
}

class _BlockToggleButton extends StatelessWidget {
  const _BlockToggleButton({required this.controller, required this.palette});

  final WarehouseController controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final active = controller.blockMode;
    return Material(
      color: active ? _blockAccent : palette.panelBg,
      borderRadius: BorderRadius.circular(999),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: controller.toggleBlockMode,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? _blockAccent : palette.panelBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? Icons.check_circle_outline_rounded : Icons.view_module_outlined,
                  size: 16, color: active ? Colors.white : palette.text),
              const SizedBox(width: 8),
              Text(
                active ? 'Concluir seleção de blocos' : 'Selecionar blocos para mover',
                style:
                    TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: active ? Colors.white : palette.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockToolbar extends StatelessWidget {
  const _BlockToolbar({required this.controller, required this.palette});

  final WarehouseController controller;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final n = controller.selectedRuas.length;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(n == 1 ? '1 rua selecionada' : '$n ruas selecionadas',
              style: TextStyle(fontSize: 11.5, color: palette.textDim)),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolbarButton(
                icon: Icons.rotate_90_degrees_ccw_rounded,
                label: 'Girar 90°',
                onTap: controller.rotateSelectedRuas,
                palette: palette,
              ),
              const SizedBox(width: 8),
              _ToolbarButton(
                icon: Icons.clear_rounded,
                label: 'Limpar seleção',
                onTap: controller.clearSelectedRuas,
                palette: palette,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon, required this.label, required this.onTap, required this.palette});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.panelBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: palette.text),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: palette.text)),
            ],
          ),
        ),
      ),
    );
  }
}
