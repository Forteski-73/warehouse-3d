import 'dart:convert';

import 'package:flutter/painting.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;

import '../models/warehouse_models.dart';

/// Loads the real inventory snapshot (11 aisles / 344 pallets) that was
/// exported from the warehouse database into `assets/data/warehouse_real.json`.
class RealDatasetLoader {
  static const _assetPath = 'assets/data/warehouse_real.json';

  Future<WarehouseDataset> load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final ruasJson = (json['RUAS'] as List).cast<Map<String, dynamic>>();
    final streets = ruasJson
        .map((r) => StreetDef(
              nome: r['nome'] as String,
              bloco: r['bloco'] as String?,
              quadra: r['quadra'] as String?,
              cor: Color(0xFF000000 | (r['cor'] as int)),
            ))
        .toList();

    final paletesJson = (json['PALETES'] as List).cast<Map<String, dynamic>>();
    final pallets = paletesJson.map((p) {
      final produtos = (p['produtos'] as List)
          .cast<Map<String, dynamic>>()
          .map((pr) => ProductLine(codigo: pr['codigo'] as String, qtd: pr['qtd'] as int))
          .toList();
      final ruaIdx = p['ruaIdx'] as int;
      return PalletData(
        id: p['unitizador'] as String,
        ruaIdx: ruaIdx,
        andar: p['andar'] as int,
        pos: p['pos'] as int,
        produtos: produtos,
        cor: streets[ruaIdx].cor,
      );
    }).toList();

    final maxPos = pallets.map((p) => p.pos).reduce((a, b) => a > b ? a : b);

    return WarehouseDataset(
      mode: DatasetMode.real,
      streets: streets,
      pallets: pallets,
      capacity: GridCapacity(
        maxRuas: streets.length + 3,
        maxPos: maxPos + 4,
        maxAndares: 4,
      ),
    );
  }
}
