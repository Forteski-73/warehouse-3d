import 'package:flutter/painting.dart' show Color;

enum DatasetMode { real, simulated }

extension DatasetModeLabel on DatasetMode {
  String get label => switch (this) {
        DatasetMode.real => 'Estoque real',
        DatasetMode.simulated => 'Protótipo simulado',
      };

  String get description => switch (this) {
        DatasetMode.real =>
          'Dados reais carregados do arquivo de estoque (Bloco / Quadra). Arraste um palete até uma vaga livre.',
        DatasetMode.simulated =>
          'Armazém simulado por setor de produto. Arraste um palete: setores incompatíveis geram alerta.',
      };
}

/// One product line inside a pallet (a pallet may carry more than one SKU).
class ProductLine {
  final String codigo;
  final String? nome;
  final int qtd;

  const ProductLine({required this.codigo, this.nome, required this.qtd});
}

/// Which axis a street's position ("pos") advances along in world space.
enum StreetOrientation { eastWest, northSouth }

/// One warehouse aisle ("rua"). In real data this maps to Bloco/Quadra; in
/// simulated data it maps to a product sector used for compliance checks.
///
/// [originX]/[originZ]/[orientation] are mutable: a street owns its own
/// world-space placement (rather than a fixed row derived from its index),
/// so a whole aisle — and every pallet in it — can be dragged or rotated as
/// one rigid block. [WarehouseController] assigns the initial origin right
/// after loading a dataset, matching the classic fixed-row layout until the
/// engineer moves something.
class StreetDef {
  final String nome;
  final String? bloco;
  final String? quadra;
  final String? setor;
  final Color cor;
  double originX;
  double originZ;
  StreetOrientation orientation;

  StreetDef({
    required this.nome,
    this.bloco,
    this.quadra,
    this.setor,
    required this.cor,
    this.originX = 0,
    this.originZ = 0,
    this.orientation = StreetOrientation.eastWest,
  });
}

/// One pallet occupying a (rua, andar, pos) slot.
class PalletData {
  final String id;
  int ruaIdx;
  int andar;
  int pos;
  final List<ProductLine> produtos;

  /// The sector this pallet's cargo belongs to (simulated dataset only).
  /// Used to detect a misplaced pallet after a move, mirroring demo2.
  final String? setorEsperado;

  /// Fixed at load time from the pallet's original aisle — kept unchanged
  /// after a move so a relocated pallet still visually "carries" the color
  /// of where it came from (reinforces a sector mismatch at a glance).
  final Color cor;
  bool mismatch;

  PalletData({
    required this.id,
    required this.ruaIdx,
    required this.andar,
    required this.pos,
    required this.produtos,
    required this.cor,
    this.setorEsperado,
    this.mismatch = false,
  });

  int get totalQtd => produtos.fold(0, (sum, p) => sum + p.qtd);

  String get slotKey => '${ruaIdx}_${andar}_$pos';
}

class GridCapacity {
  final int maxRuas;
  final int maxPos;
  final int maxAndares;

  const GridCapacity({required this.maxRuas, required this.maxPos, required this.maxAndares});
}

class WarehouseDataset {
  final DatasetMode mode;
  final List<StreetDef> streets;
  final List<PalletData> pallets;
  final GridCapacity capacity;

  const WarehouseDataset({
    required this.mode,
    required this.streets,
    required this.pallets,
    required this.capacity,
  });
}
