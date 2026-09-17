import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../engine/orbit_camera.dart';
import '../engine/scene_builder.dart';
import '../engine/vec3.dart';
import '../models/edit_marker.dart';
import '../models/warehouse_models.dart';
import '../state/warehouse_controller.dart';

class WarehouseViewport extends StatefulWidget {
  const WarehouseViewport({super.key, required this.controller});

  final WarehouseController controller;

  @override
  State<WarehouseViewport> createState() => _WarehouseViewportState();
}

class _WarehouseViewportState extends State<WarehouseViewport> with SingleTickerProviderStateMixin {
  late OrbitCamera _camera;
  late AnimationController _pulse;
  DatasetMode? _lastMode;
  Size _lastSize = Size.zero;

  bool _isDraggingCamera = false;
  Offset _lastPointer = Offset.zero;
  double _movedAccum = 0;

  PalletData? _draggingPallet;
  double _dragFallbackY = 0;
  Vec3? _dragWorld;
  VacancySlot? _hoveredSlot;

  // Whole-street ("block") drag, active only in edit mode's block sub-mode
  // with at least one street selected.
  bool _groupDragActive = false;
  Vec3? _groupDragStartWorld;
  double _groupDragDx = 0;
  double _groupDragDz = 0;

  // Two-finger pinch-to-zoom (touch devices have no scroll wheel).
  final Map<int, Offset> _activePointers = {};
  double? _pinchStartDistance;
  double? _pinchStartRadius;

  WarehouseController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _camera = OrbitCamera(target: _c.cameraTarget, radius: _c.mode == DatasetMode.real ? 55 : 24);
    _lastMode = _c.mode;
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _c.addListener(_onControllerChanged);
    _syncPulse();
  }

  @override
  void dispose() {
    _c.removeListener(_onControllerChanged);
    _pulse.dispose();
    super.dispose();
  }

  /// The pulse animation only needs to run while something on screen is
  /// actually pulsing (edit-mode markers, mismatch outlines) — otherwise it
  /// sits idle instead of driving a needless 90Hz repaint loop forever.
  void _syncPulse() {
    final needsPulse = _c.editMode || _c.pallets.any((p) => p.mismatch);
    if (needsPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!needsPulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0.5;
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    _syncPulse();
    if (_lastMode != _c.mode) {
      _lastMode = _c.mode;
      setState(() {
        _camera = OrbitCamera(target: _c.cameraTarget, radius: _c.mode == DatasetMode.real ? 55 : 24);
        _draggingPallet = null;
        _dragWorld = null;
        _hoveredSlot = null;
        _groupDragActive = false;
      });
    } else {
      setState(() {});
    }
  }

  Projector _projector() =>
      Projector(cam: _camera.basis(), fovYRad: _camera.fovYDeg * math.pi / 180, viewport: _lastSize);

  SceneFrame _buildFrame() {
    final drag = _draggingPallet == null
        ? null
        : DragPreview(pallet: _draggingPallet!, worldPos: _dragWorld!, hoveredSlot: _hoveredSlot);
    final blockDrag = _groupDragActive
        ? BlockDragPreview(ruaIdxs: _c.selectedRuas, dx: _groupDragDx, dz: _groupDragDz)
        : null;
    return SceneBuilder.build(
        controller: _c, projector: _projector(), drag: drag, blockDrag: blockDrag, pulse: _pulse.value);
  }

  bool _pointInPolygon(Offset pt, List<Offset> poly) {
    var sign = 0;
    for (var i = 0; i < poly.length; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % poly.length];
      final cross = (b.dx - a.dx) * (pt.dy - a.dy) - (b.dy - a.dy) * (pt.dx - a.dx);
      final s = cross > 0 ? 1 : (cross < 0 ? -1 : 0);
      if (s == 0) continue;
      if (sign == 0) {
        sign = s;
      } else if (s != sign) {
        return false;
      }
    }
    return true;
  }

  T? _hitTest<T extends SceneHit>(SceneFrame frame, Offset point) {
    for (final poly in frame.hitCandidates) {
      final hit = poly.hit;
      if (hit is T && _pointInPolygon(point, poly.points)) return hit;
    }
    return null;
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;

    // A second finger landing (while not mid-drag) starts a pinch gesture
    // and takes over from whatever single-finger orbit was doing.
    if (_activePointers.length == 2 && _draggingPallet == null && !_groupDragActive) {
      _isDraggingCamera = false;
      _pinchStartDistance = _pointerDistance();
      _pinchStartRadius = _camera.radius;
      return;
    }
    if (_activePointers.length > 2) return;

    _movedAccum = 0;
    _lastPointer = event.localPosition;

    if (_c.editMode && _c.blockMode) {
      if (_c.selectedRuas.isNotEmpty) {
        final startPt = _projector().unproject(event.localPosition).intersectHorizontalPlane(0);
        if (startPt != null) {
          _groupDragActive = true;
          _groupDragStartWorld = startPt;
          _groupDragDx = 0;
          _groupDragDz = 0;
          return;
        }
      }
      _isDraggingCamera = true;
      return;
    }

    if (_c.editMode) {
      _isDraggingCamera = true;
      return;
    }

    final frame = _buildFrame();
    final hit = _hitTest<PalletHit>(frame, event.localPosition);
    if (hit != null) {
      final p = hit.pallet;
      final w = _c.metrics.slotToWorld(_c.streets[p.ruaIdx], p.andar, p.pos);
      _draggingPallet = p;
      _dragWorld = w;
      _dragFallbackY = w.y;
      _hoveredSlot = null;
      if (_c.computeVacancySlots().isEmpty) {
        _c.toasts.show("Não há vagas livres conhecidas — use 'Editar layout' para criar capacidade");
      }
      setState(() {});
    } else {
      _isDraggingCamera = true;
    }
  }

  double _pointerDistance() {
    final pts = _activePointers.values.toList();
    return (pts[0] - pts[1]).distance;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activePointers.containsKey(event.pointer)) {
      _activePointers[event.pointer] = event.localPosition;
    }

    if (_pinchStartDistance != null && _activePointers.length >= 2) {
      final dist = _pointerDistance();
      if (_pinchStartDistance! > 1) {
        final scale = dist / _pinchStartDistance!;
        _camera.radius = (_pinchStartRadius! / scale).clamp(_camera.minRadius, _camera.maxRadius);
        setState(() {});
      }
      return;
    }

    final delta = event.localPosition - _lastPointer;
    _movedAccum += delta.dx.abs() + delta.dy.abs();
    _lastPointer = event.localPosition;

    if (_groupDragActive) {
      final pt = _projector().unproject(event.localPosition).intersectHorizontalPlane(0);
      if (pt != null && _groupDragStartWorld != null) {
        _groupDragDx = pt.x - _groupDragStartWorld!.x;
        _groupDragDz = pt.z - _groupDragStartWorld!.z;
      }
      setState(() {});
      return;
    }

    if (_draggingPallet != null) {
      final frame = _buildFrame();
      final vacancy = _hitTest<VacancyHit>(frame, event.localPosition);
      if (vacancy != null) {
        _hoveredSlot = vacancy.slot;
        final w = _c.metrics.slotToWorld(_c.streets[vacancy.slot.ruaIdx], vacancy.slot.andar, vacancy.slot.pos);
        _dragWorld = Vec3(w.x, w.y + 0.25, w.z);
      } else {
        _hoveredSlot = null;
        final ray = _projector().unproject(event.localPosition);
        final pt = ray.intersectHorizontalPlane(_dragFallbackY);
        if (pt != null) _dragWorld = Vec3(pt.x, _dragFallbackY, pt.z);
      }
      setState(() {});
      return;
    }

    if (_isDraggingCamera) {
      _camera.orbit(delta.dx * 0.006, delta.dy * 0.006);
      setState(() {});
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);

    if (_pinchStartDistance != null) {
      if (_activePointers.length < 2) {
        _pinchStartDistance = null;
        _pinchStartRadius = null;
        if (_activePointers.length == 1) {
          // Resume single-finger orbit smoothly from the remaining finger,
          // and mark this as "already moved" so lifting it isn't read as a tap.
          _isDraggingCamera = true;
          _lastPointer = _activePointers.values.first;
          _movedAccum = 999;
        }
      }
      setState(() {});
      return;
    }

    if (_groupDragActive) {
      _groupDragActive = false;
      final wasTap = _movedAccum <= 6;
      if (!wasTap) {
        final posSpacing = _c.metrics.posSpacing;
        final snappedDx = (_groupDragDx / posSpacing).round() * posSpacing;
        final snappedDz = (_groupDragDz / posSpacing).round() * posSpacing;
        _c.moveSelectedRuas(snappedDx, snappedDz);
      }
      _groupDragStartWorld = null;
      _groupDragDx = 0;
      _groupDragDz = 0;
      // A tap (no real drag) is still a valid "select this street" click.
      if (wasTap) _handleTap(event.localPosition);
      setState(() {});
      return;
    }

    if (_draggingPallet != null) {
      final p = _draggingPallet!;
      if (_hoveredSlot != null) {
        _c.movePallet(p, _hoveredSlot!);
      }
      _draggingPallet = null;
      _dragWorld = null;
      _hoveredSlot = null;
      setState(() {});
      return;
    }

    _isDraggingCamera = false;
    if (_movedAccum <= 6) _handleTap(event.localPosition);
    setState(() {});
  }

  /// If the OS/engine cancels an in-progress gesture (e.g. another surface
  /// steals the touch), drop every drag state instead of leaving the camera
  /// (or a pallet/block drag) stuck mid-gesture forever.
  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    _pinchStartDistance = null;
    _pinchStartRadius = null;
    _isDraggingCamera = false;
    _groupDragActive = false;
    _groupDragStartWorld = null;
    _groupDragDx = 0;
    _groupDragDz = 0;
    if (_draggingPallet != null) {
      _draggingPallet = null;
      _dragWorld = null;
      _hoveredSlot = null;
    }
    setState(() {});
  }

  void _handleTap(Offset position) {
    debugPrint('VIEWPORT _handleTap at $position editMode=${_c.editMode} blockMode=${_c.blockMode}');
    final frame = _buildFrame();

    if (_c.editMode && _c.blockMode) {
      final palletHit = _hitTest<PalletHit>(frame, position);
      if (palletHit != null) {
        _c.toggleRuaSelection(palletHit.pallet.ruaIdx);
        return;
      }
      final cellHit = _hitTest<StructureCellHit>(frame, position);
      if (cellHit != null) _c.toggleRuaSelection(cellHit.ruaIdx);
      return;
    }

    if (_c.editMode) {
      final hit = _hitTest<EditMarkerHit>(frame, position);
      if (hit == null) return;
      final m = hit.marker;
      switch (m.type) {
        case EditMarkerType.addPos:
          _c.addPosToRua(m.ruaIdx);
        case EditMarkerType.addAndar:
          _c.addAndarToColumn(m.ruaIdx, m.pos);
        case EditMarkerType.addRua:
          _c.addRua();
        case EditMarkerType.remove:
          _c.removeCell(m.ruaIdx, m.andar, m.pos);
      }
      return;
    }
    final hit = _hitTest<PalletHit>(frame, position);
    if (hit != null) {
      _c.selectPallet(hit.pallet.id);
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _camera.zoom(event.scrollDelta.dy * 0.045);
      setState(() {});
    }
  }

  MouseCursor get _cursor {
    if (_draggingPallet != null || _isDraggingCamera || _groupDragActive) return SystemMouseCursors.grabbing;
    if (_c.editMode && _c.blockMode) return SystemMouseCursors.click;
    if (_c.editMode) return SystemMouseCursors.precise;
    return SystemMouseCursors.grab;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _lastSize = constraints.biggest;
        return AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final frame = _buildFrame();
            return MouseRegion(
              cursor: _cursor,
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                onPointerSignal: _onPointerSignal,
                child: CustomPaint(
                  size: _lastSize,
                  painter: _WarehousePainter(frame),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WarehousePainter extends CustomPainter {
  _WarehousePainter(this.frame);

  final SceneFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()..style = PaintingStyle.stroke;

    if (frame.floor != null) {
      fillPaint.color = frame.floor!.color;
      canvas.drawPath(_path(frame.floor!.points), fillPaint);
    }

    linePaint.strokeWidth = 1;
    for (final l in frame.gridLines) {
      linePaint.color = l.color;
      canvas.drawLine(l.a, l.b, linePaint);
    }

    for (final l in frame.structureLines) {
      linePaint.color = l.color;
      linePaint.strokeWidth = l.strokeWidth;
      canvas.drawLine(l.a, l.b, linePaint);
    }

    for (final f in frame.fills) {
      fillPaint.color = f.color;
      canvas.drawPath(_path(f.points), fillPaint);
    }

    for (final l in frame.selectionLines) {
      linePaint.color = l.color;
      linePaint.strokeWidth = l.strokeWidth;
      canvas.drawLine(l.a, l.b, linePaint);
    }
    for (final l in frame.mismatchLines) {
      linePaint.color = l.color;
      linePaint.strokeWidth = l.strokeWidth;
      canvas.drawLine(l.a, l.b, linePaint);
    }
    for (final l in frame.blockLines) {
      linePaint.color = l.color;
      linePaint.strokeWidth = l.strokeWidth;
      canvas.drawLine(l.a, l.b, linePaint);
    }
  }

  Path _path(List<Offset> points) {
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _WarehousePainter oldDelegate) => true;
}
