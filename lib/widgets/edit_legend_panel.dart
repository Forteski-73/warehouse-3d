import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'glass_panel.dart';

class EditLegendPanel extends StatelessWidget {
  const EditLegendPanel({super.key});

  static const _rows = [
    (Color(0xFF4CAF6F), 'Adicionar posição na rua'),
    (Color(0xFF5BC8DE), 'Empilhar mais um andar'),
    (Color(0xFFB985E6), 'Criar rua nova'),
    (Color(0xFFE05252), 'Remover (só o topo da pilha)'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return GlassPanel(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MODO DE EDIÇÃO DE LAYOUT',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: palette.textDim),
          ),
          const SizedBox(height: 8),
          for (final row in _rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: row.$1, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(row.$2, style: TextStyle(fontSize: 12, color: palette.text))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
