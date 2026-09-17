import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'glass_panel.dart';

class HintPanel extends StatelessWidget {
  const HintPanel({super.key, required this.editMode, this.blockMode = false});

  final bool editMode;
  final bool blockMode;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final text = blockMode
        ? 'Clique num palete ou vaga pra selecionar a rua inteira (amarelo) · Clique em outra pra somar à seleção\nArraste o fundo pra mover o(s) bloco(s) selecionado(s)'
        : editMode
            ? 'Arraste o fundo para girar · Scroll ou pinça para zoom\n🟢 nova posição · 🔵 empilhar andar · 🟣 nova rua · 🔴 remover topo da pilha'
            : 'Arraste o fundo para girar · Scroll ou pinça para zoom\nArraste um palete: vagas livres acendem em verde — solte em cima de uma para mover';
    return GlassPanel(
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 280),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 11.5, color: palette.textDim, height: 1.4),
      ),
    );
  }
}
