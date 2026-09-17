import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../state/warehouse_controller.dart';

class EditModeButton extends StatelessWidget {
  const EditModeButton({super.key, required this.controller});

  final WarehouseController controller;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final active = controller.editMode;
        return Material(
          color: active ? palette.accent : palette.panelBg,
          borderRadius: BorderRadius.circular(999),
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: controller.toggleEditMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: active ? palette.accent : palette.panelBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(active ? Icons.check_circle_outline_rounded : Icons.build_outlined,
                      size: 17, color: active ? Colors.white : palette.text),
                  const SizedBox(width: 8),
                  Text(
                    active ? 'Concluir edição' : 'Editar layout do armazém',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : palette.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
