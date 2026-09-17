import '../engine/vec3.dart';
import 'warehouse_models.dart';

/// Converts (ruaIdx, andar, pos) grid coordinates into fixed world-space
/// positions. The grid spans the full [GridCapacity] (not just the currently
/// built cells), so growing the structure via edit mode never shifts
/// anything that already exists — same guarantee as the HTML prototypes.
class GridMetrics {
  final double ruaSpacing;
  final double posSpacing;
  final double andarHeight;
  final double cargoSize;
  final GridCapacity capacity;
  final double startX;
  final double startZ;

  GridMetrics({
    required this.ruaSpacing,
    required this.posSpacing,
    required this.andarHeight,
    required this.cargoSize,
    required this.capacity,
  })  : startX = -((capacity.maxPos - 1) * posSpacing) / 2,
        startZ = -((capacity.maxRuas - 1) * ruaSpacing) / 2;

  factory GridMetrics.forMode(DatasetMode mode, GridCapacity capacity) {
    return switch (mode) {
      DatasetMode.real => GridMetrics(
          ruaSpacing: 4.6,
          posSpacing: 1.55,
          andarHeight: 1.9,
          cargoSize: 1.05,
          capacity: capacity,
        ),
      DatasetMode.simulated => GridMetrics(
          ruaSpacing: 6.0,
          posSpacing: 2.2,
          andarHeight: 2.0,
          cargoSize: 1.35,
          capacity: capacity,
        ),
    };
  }

  /// World position of a slot within [street], honoring that street's own
  /// origin and orientation — not a fixed row derived from its index, so
  /// this stays correct after the street has been dragged/rotated as a block.
  Vec3 slotToWorld(StreetDef street, num andar, num pos) {
    final d = (pos - 1) * posSpacing;
    final x = street.orientation == StreetOrientation.eastWest ? street.originX + d : street.originX;
    final z = street.orientation == StreetOrientation.northSouth ? street.originZ + d : street.originZ;
    return Vec3(x, (andar - 1) * andarHeight, z);
  }

  /// The default (row, index-based) origin a street would occupy if it had
  /// never been moved. Used to seed a freshly-loaded street's placement and
  /// to preview where a brand-new street (from edit mode) would land.
  Vec3 defaultOriginForIndex(int ruaIdx) => Vec3(startX, 0, startZ + ruaIdx * ruaSpacing);

  double get floorWidth => capacity.maxPos * posSpacing + 12;
  double get floorDepth => capacity.maxRuas * ruaSpacing + 12;
}
