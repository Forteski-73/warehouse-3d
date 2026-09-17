import 'dart:ui';

import '../models/edit_marker.dart';
import '../models/warehouse_models.dart';
import '../state/warehouse_controller.dart';
import 'box_geometry.dart';
import 'orbit_camera.dart';
import 'vec3.dart';

/// What a filled polygon in the scene represents, for hit-testing.
sealed class SceneHit {}

class PalletHit extends SceneHit {
  final PalletData pallet;
  PalletHit(this.pallet);
}

class VacancyHit extends SceneHit {
  final VacancySlot slot;
  VacancyHit(this.slot);
}

class EditMarkerHit extends SceneHit {
  final EditMarker marker;
  EditMarkerHit(this.marker);
}

/// An empty built cell, hit-testable only in block-select mode so tapping a
/// vacant slot can still select the whole street it belongs to.
class StructureCellHit extends SceneHit {
  final int ruaIdx;
  StructureCellHit(this.ruaIdx);
}

class ScenePolygon {
  final List<Offset> points;
  final double depth;
  final Color color;
  final SceneHit? hit;

  const ScenePolygon({required this.points, required this.depth, required this.color, this.hit});
}

class SceneLine {
  final Offset a;
  final Offset b;
  final Color color;
  final double strokeWidth;

  const SceneLine(this.a, this.b, this.color, {this.strokeWidth = 1.2});
}

/// Transient (per-frame, non-domain) interaction state supplied by the
/// viewport widget: the pallet currently being dragged and where its
/// preview should render.
class DragPreview {
  final PalletData pallet;
  final Vec3 worldPos;
  final VacancySlot? hoveredSlot;

  const DragPreview({required this.pallet, required this.worldPos, this.hoveredSlot});
}

/// Transient preview of an in-progress whole-street ("block") drag: every
/// pallet belonging to one of [ruaIdxs] is rendered offset by (dx, dz) from
/// its committed slot position, without touching the underlying street
/// origins until the drag is released.
class BlockDragPreview {
  final Set<int> ruaIdxs;
  final double dx;
  final double dz;

  const BlockDragPreview({required this.ruaIdxs, required this.dx, required this.dz});
}

class SceneFrame {
  final ScenePolygon? floor;
  final List<SceneLine> gridLines;
  final List<SceneLine> structureLines;
  final List<ScenePolygon> fills; // painter order: back-to-front
  final List<SceneLine> selectionLines;
  final List<SceneLine> mismatchLines;
  final List<SceneLine> blockLines;

  const SceneFrame({
    required this.floor,
    required this.gridLines,
    required this.structureLines,
    required this.fills,
    required this.selectionLines,
    required this.mismatchLines,
    required this.blockLines,
  });

  /// Nearest-first, for pointer hit-testing.
  List<ScenePolygon> get hitCandidates =>
      fills.where((f) => f.hit != null).toList()..sort((a, b) => a.depth.compareTo(b.depth));
}

class SceneBuilder {
  static const _skidHeight = 0.2;
  static const _cargoHeight = 0.95;

  static SceneFrame build({
    required WarehouseController controller,
    required Projector projector,
    DragPreview? drag,
    BlockDragPreview? blockDrag,
    double pulse = 0.5,
  }) {
    final metrics = controller.metrics;
    final eye = projector.cam.eye;

    // ---- floor ----
    final floorQuad = FlatQuad(center: Vec3.zero, width: metrics.floorWidth, depth: metrics.floorDepth);
    final floorPoly = _projectFlat(projector, floorQuad.corners, const Color(0xFF2A3142), null);

    // ---- grid lines ----
    final gridLines = <SceneLine>[];
    final halfW = metrics.floorWidth / 2, halfD = metrics.floorDepth / 2;
    for (var r = 0; r <= controller.capacity.maxRuas; r++) {
      final z = metrics.startZ - metrics.ruaSpacing / 2 + r * metrics.ruaSpacing;
      _addLine(gridLines, projector, Vec3(-halfW, 0, z), Vec3(halfW, 0, z), const Color(0xFF3A4256));
    }
    for (var p = 0; p <= controller.capacity.maxPos; p += 2) {
      final x = metrics.startX - metrics.posSpacing / 2 + p * metrics.posSpacing;
      _addLine(gridLines, projector, Vec3(x, 0, -halfD), Vec3(x, 0, halfD), const Color(0xFF3A4256));
    }

    final fills = <ScenePolygon>[];

    // ---- empty built structure (outline only, or hit-testable in block mode) ----
    final structureLines = <SceneLine>[];
    for (final key in controller.built) {
      if (controller.occupied.containsKey(key)) continue;
      final parts = key.split('_').map(int.parse).toList();
      final ruaIdx = parts[0];
      final w = metrics.slotToWorld(controller.streets[ruaIdx], parts[1], parts[2]);
      final selected = controller.blockMode && controller.selectedRuas.contains(ruaIdx);
      final box = Box3(
        base: Vec3(w.x, w.y, w.z),
        size: Vec3(metrics.cargoSize + 0.2, _skidHeight + _cargoHeight, metrics.cargoSize + 0.2),
      );
      final lineColor = selected ? const Color(0xFFF5D442) : const Color(0xFF46506A);
      for (final edge in box.edges) {
        _addLine(structureLines, projector, edge[0], edge[1], lineColor);
      }

      if (controller.blockMode) {
        // Invisible but hit-testable, so tapping an empty slot also selects
        // the street it belongs to.
        _addFlatMarker(fills, projector, Vec3(w.x, w.y + 0.58, w.z), metrics.cargoSize + 0.2,
            const Color(0x00000000), StructureCellHit(ruaIdx));
      }
    }

    // ---- pallets ----
    final selectionLines = <SceneLine>[];
    final mismatchLines = <SceneLine>[];
    final blockLines = <SceneLine>[];

    for (final p in controller.pallets) {
      final isDragging = drag != null && drag.pallet.id == p.id;
      var w = isDragging ? drag.worldPos : metrics.slotToWorld(controller.streets[p.ruaIdx], p.andar, p.pos);
      if (!isDragging && blockDrag != null && blockDrag.ruaIdxs.contains(p.ruaIdx)) {
        w = Vec3(w.x + blockDrag.dx, w.y, w.z + blockDrag.dz);
      }

      final skid = Box3(base: w, size: Vec3(metrics.cargoSize + 0.15, _skidHeight, metrics.cargoSize + 0.15));
      final cargo = Box3(
        base: Vec3(w.x, w.y + _skidHeight, w.z),
        size: Vec3(metrics.cargoSize, _cargoHeight, metrics.cargoSize),
      );

      _appendBoxFaces(fills, projector, eye, skid, const Color(0xFF8A6A45), PalletHit(p));
      _appendBoxFaces(fills, projector, eye, cargo, p.cor, PalletHit(p));

      final highlightBox = Box3(
        base: Vec3(w.x, w.y - 0.02, w.z),
        size: Vec3(metrics.cargoSize * 1.08 + 0.15, _skidHeight + _cargoHeight * 1.08, metrics.cargoSize * 1.08 + 0.15),
      );
      if (p.id == controller.selectedPalletId) {
        for (final edge in highlightBox.edges) {
          _addLine(selectionLines, projector, edge[0], edge[1], const Color(0xFFFFFFFF), width: 1.6);
        }
      }
      if (p.mismatch) {
        final warnOpacity = 0.35 + pulse * 0.65;
        for (final edge in highlightBox.edges) {
          _addLine(
            mismatchLines,
            projector,
            edge[0],
            edge[1],
            const Color(0xFFE05252).withValues(alpha: warnOpacity),
            width: 1.6,
          );
        }
      }
      if (controller.blockMode && controller.selectedRuas.contains(p.ruaIdx)) {
        for (final edge in highlightBox.edges) {
          _addLine(blockLines, projector, edge[0], edge[1], const Color(0xFFF5D442), width: 1.6);
        }
      }
    }

    // ---- vacancy markers (only while dragging a single pallet) ----
    if (drag != null) {
      for (final slot in controller.computeVacancySlots()) {
        final w = metrics.slotToWorld(controller.streets[slot.ruaIdx], slot.andar, slot.pos);
        final isHovered = drag.hoveredSlot?.key == slot.key;
        final quad = FlatQuad(
          center: Vec3(w.x, w.y, w.z),
          width: metrics.cargoSize + 0.35,
          depth: metrics.cargoSize + 0.35,
          y: 0.02,
        );
        final opacity = isHovered ? 0.85 : 0.4;
        final poly = _projectFlat(
          projector,
          quad.corners,
          const Color(0xFF4CAF6F).withValues(alpha: opacity),
          VacancyHit(slot),
        );
        if (poly != null) fills.add(poly);
      }
    }

    // ---- edit-mode markers (hidden while selecting/dragging blocks) ----
    if (controller.editMode && !controller.blockMode) {
      final markerOpacity = 0.4 + pulse * 0.35;
      for (final marker in controller.computeEditMarkers()) {
        switch (marker.type) {
          case EditMarkerType.addPos:
            _addFlatMarker(
                fills,
                projector,
                metrics.slotToWorld(controller.streets[marker.ruaIdx], 1, marker.pos),
                metrics.cargoSize + 0.3,
                const Color(0xFF4CAF6F).withValues(alpha: markerOpacity),
                EditMarkerHit(marker));
          case EditMarkerType.addAndar:
            _addFlatMarker(
                fills,
                projector,
                metrics.slotToWorld(controller.streets[marker.ruaIdx], marker.andar, marker.pos),
                metrics.cargoSize + 0.3,
                const Color(0xFF5BC8DE).withValues(alpha: markerOpacity),
                EditMarkerHit(marker));
          case EditMarkerType.addRua:
            final origin = metrics.defaultOriginForIndex(marker.ruaIdx);
            _addFlatMarker(fills, projector, origin, metrics.cargoSize + 0.3,
                const Color(0xFFB985E6).withValues(alpha: markerOpacity), EditMarkerHit(marker));
          case EditMarkerType.remove:
            final w = metrics.slotToWorld(controller.streets[marker.ruaIdx], marker.andar, marker.pos);
            final box = Box3(
              base: w,
              size: Vec3(metrics.cargoSize + 0.25, _skidHeight + _cargoHeight, metrics.cargoSize + 0.25),
            );
            _appendBoxFaces(fills, projector, eye, box, const Color(0xFFE05252).withValues(alpha: 0.4),
                EditMarkerHit(marker));
        }
      }
    }

    fills.sort((a, b) => b.depth.compareTo(a.depth));

    return SceneFrame(
      floor: floorPoly,
      gridLines: gridLines,
      structureLines: structureLines,
      fills: fills,
      selectionLines: selectionLines,
      mismatchLines: mismatchLines,
      blockLines: blockLines,
    );
  }

  static void _appendBoxFaces(
    List<ScenePolygon> out,
    Projector projector,
    Vec3 eye,
    Box3 box,
    Color baseColor,
    SceneHit hit,
  ) {
    for (final face in box.visibleFaces(eye)) {
      final factor = shadeFactor(face.normal);
      final shaded = Color.from(
        alpha: baseColor.a,
        red: baseColor.r * factor,
        green: baseColor.g * factor,
        blue: baseColor.b * factor,
      );
      final poly = _projectFlat(projector, face.corners, shaded, hit);
      if (poly != null) out.add(poly);
    }
  }

  static void _addFlatMarker(
    List<ScenePolygon> out,
    Projector projector,
    Vec3 center,
    double size,
    Color color,
    SceneHit hit,
  ) {
    final quad = FlatQuad(center: center, width: size, depth: size, y: 0.03);
    final poly = _projectFlat(projector, quad.corners, color, hit);
    if (poly != null) out.add(poly);
  }

  static ScenePolygon? _projectFlat(
    Projector projector,
    List<Vec3> corners,
    Color color,
    SceneHit? hit,
  ) {
    final points = <Offset>[];
    var depthSum = 0.0;
    for (final c in corners) {
      final pp = projector.project(c);
      if (pp == null) return null;
      points.add(pp.screen);
      depthSum += pp.depth;
    }
    return ScenePolygon(points: points, depth: depthSum / corners.length, color: color, hit: hit);
  }

  static void _addLine(List<SceneLine> out, Projector projector, Vec3 a, Vec3 b, Color color, {double width = 1.0}) {
    final pa = projector.project(a);
    final pb = projector.project(b);
    if (pa == null || pb == null) return;
    out.add(SceneLine(pa.screen, pb.screen, color, strokeWidth: width));
  }
}
