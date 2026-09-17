import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../state/warehouse_controller.dart';
import 'glass_panel.dart';

class DetailPanel extends StatelessWidget {
  const DetailPanel({super.key, required this.controller});

  final WarehouseController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final p = controller.selectedPallet;
        return AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: p == null ? const Offset(0, 1.3) : Offset.zero,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: p == null ? 0 : 1,
            child: p == null
                ? const SizedBox(height: 0, width: 260)
                : _DetailContent(controller: controller, palletId: p.id),
          ),
        );
      },
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.controller, required this.palletId});

  final WarehouseController controller;
  final String palletId;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final p = controller.pallets.where((x) => x.id == palletId).firstOrNull;
    if (p == null) return const SizedBox.shrink();
    final street = controller.streets[p.ruaIdx];

    return GlassPanel(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 300, maxHeight: 420),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.mode.name == 'real' ? 'Palete ${p.id}' : (p.produtos.first.nome ?? p.id),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.text),
                  ),
                ),
                InkWell(
                  onTap: controller.deselect,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 17, color: palette.textDim),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (controller.mode.name != 'real') _Row('SKU', p.produtos.first.codigo, palette),
            if (controller.mode.name != 'real' && p.setorEsperado != null) _Row('Setor do produto', p.setorEsperado!, palette),
            _Row('Rua atual', street.nome, palette),
            _Row('Andar', '${p.andar}', palette),
            _Row('Posição', '${p.pos}', palette),
            _Row('Qtd. total', '${_fmt(p.totalQtd)} un.', palette),
            if (p.mismatch)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: palette.warn.withValues(alpha: 0.16),
                  border: Border.all(color: palette.warn.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 15, color: palette.warn),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Palete fora do setor correto',
                          style: TextStyle(fontSize: 11.5, color: palette.warn, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            if (p.produtos.length > 1) ...[
              const SizedBox(height: 12),
              Text('PRODUTOS NESTE PALETE',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: palette.textDim)),
              const SizedBox(height: 6),
              for (final prod in p.produtos)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(prod.codigo,
                            style: TextStyle(fontSize: 11.5, fontFamily: 'monospace', color: palette.textDim)),
                      ),
                      Text('${_fmt(prod.qtd)} un.', style: TextStyle(fontSize: 12, color: palette.text)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Row extends StatelessWidget {
  const _Row(this.k, this.v, this.palette);

  final String k;
  final String v;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: palette.panelBorder))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(fontSize: 12, color: palette.textDim)),
          Text(v, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: palette.text)),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
