import 'package:flutter/painting.dart' show Color;

import '../models/warehouse_models.dart';

class _SectorDef {
  final String nome;
  final Color cor;
  final List<String> produtos;

  const _SectorDef({required this.nome, required this.cor, required this.produtos});
}

/// Generates the sector-driven simulated warehouse used in the compliance
/// prototype (demo 2): a handful of aisles, each dedicated to a product
/// sector, seeded with pallets and a couple of intentional violations.
class SimulatedDatasetLoader {
  static const _sectors = [
    _SectorDef(
      nome: 'Eletrônicos',
      cor: Color(0xFF5B8DEF),
      produtos: ['Monitor 24"', 'Teclado Mecânico', 'Cabo HDMI 2m', 'Roteador Wi-Fi', 'Fonte ATX 650W'],
    ),
    _SectorDef(
      nome: 'Alimentos',
      cor: Color(0xFF4CAF6F),
      produtos: ['Arroz 5kg', 'Feijão 1kg', 'Óleo de Soja', 'Café Torrado 500g', 'Macarrão Espaguete'],
    ),
    _SectorDef(
      nome: 'Higiene',
      cor: Color(0xFFE6A23C),
      produtos: ['Sabonete Líquido', 'Papel Higiênico', 'Shampoo 400ml', 'Desinfetante 1L', 'Álcool Gel'],
    ),
    _SectorDef(
      nome: 'Bebidas',
      cor: Color(0xFF9B6FE0),
      produtos: ['Água Mineral 1,5L', 'Refrigerante 2L', 'Suco Concentrado', 'Cerveja Lata', 'Energético 250ml'],
    ),
  ];

  static const _initialAndares = 3;
  static const _initialPos = 6;

  int _seed = 42;
  double _rnd() {
    _seed = (_seed * 9301 + 49297) % 233280;
    return _seed / 233280;
  }

  WarehouseDataset load() {
    _seed = 42;
    final streets = _sectors
        .map((s) => StreetDef(nome: 'Rua ${_sectors.indexOf(s) + 1} — ${s.nome}', setor: s.nome, cor: s.cor))
        .toList();

    final pallets = <PalletData>[];
    var seq = 1;
    for (var r = 0; r < streets.length; r++) {
      final sector = _sectors[r];
      for (var andar = 1; andar <= _initialAndares; andar++) {
        for (var pos = 1; pos <= _initialPos; pos++) {
          if (_rnd() <= 0.32) continue; // vaga livre
          final produto = sector.produtos[(_rnd() * sector.produtos.length).floor()];
          pallets.add(PalletData(
            id: 'SIM-${seq.toString().padLeft(4, '0')}',
            ruaIdx: r,
            andar: andar,
            pos: pos,
            produtos: [
              ProductLine(
                codigo: 'SKU-${1000 + (_rnd() * 9000).floor()}',
                nome: produto,
                qtd: 20 + (_rnd() * 180).floor(),
              ),
            ],
            setorEsperado: sector.nome,
            cor: sector.cor,
          ));
          seq++;
        }
      }
    }

    return WarehouseDataset(
      mode: DatasetMode.simulated,
      streets: streets,
      pallets: pallets,
      capacity: const GridCapacity(maxRuas: 8, maxPos: 10, maxAndares: 5),
    );
  }
}
