import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;

import '../data/real_dataset_loader.dart';
import '../data/simulated_dataset_loader.dart';
import '../engine/vec3.dart';
import '../models/edit_marker.dart';
import '../models/grid_metrics.dart';
import '../models/warehouse_models.dart';
import 'toast_controller.dart';

class WarehouseController extends ChangeNotifier {
  WarehouseController({required this.toasts});

  final ToastController toasts;
  final RealDatasetLoader _realLoader = RealDatasetLoader();
  final SimulatedDatasetLoader _simulatedLoader = SimulatedDatasetLoader();

  DatasetMode mode = DatasetMode.real;
  bool isLoading = true;
  List<StreetDef> streets = [];
  List<PalletData> pallets = [];

  // Sane placeholders so the viewport can render an empty scene on the very
  // first frame, before the async dataset load resolves.
  static const _emptyCapacity = GridCapacity(maxRuas: 1, maxPos: 1, maxAndares: 1);
  GridCapacity capacity = _emptyCapacity;
  GridMetrics metrics = GridMetrics.forMode(DatasetMode.real, _emptyCapacity);
  Vec3 cameraTarget = Vec3.zero;

  final Set<String> built = {};
  final Map<String, PalletData> occupied = {};

  bool editMode = false;
  String? selectedPalletId;

  /// Sub-mode of edit mode: select whole streets and drag/rotate them as a
  /// rigid block, instead of moving individual pallets slot by slot.
  bool blockMode = false;
  final Set<int> selectedRuas = {};

  static String slotKey(int ruaIdx, int andar, int pos) => '${ruaIdx}_${andar}_$pos';

  PalletData? get selectedPallet =>
      selectedPalletId == null ? null : pallets.where((p) => p.id == selectedPalletId).firstOrNull;

  Future<void> loadInitial() => switchDataset(DatasetMode.real, announce: false);

  Future<void> switchDataset(DatasetMode newMode, {bool announce = true}) async {
    isLoading = true;
    notifyListeners();

    final dataset = newMode == DatasetMode.real ? await _realLoader.load() : _simulatedLoader.load();
    _applyDataset(dataset);

    isLoading = false;
    if (announce) {
      toasts.show('Modo alterado para "${newMode.label}"');
    }
    notifyListeners();
  }

  void _applyDataset(WarehouseDataset dataset) {
    mode = dataset.mode;
    streets = List.of(dataset.streets);
    pallets = List.of(dataset.pallets);
    capacity = dataset.capacity;
    metrics = GridMetrics.forMode(mode, capacity);
    editMode = false;
    selectedPalletId = null;
    blockMode = false;
    selectedRuas.clear();

    for (var i = 0; i < streets.length; i++) {
      final origin = metrics.defaultOriginForIndex(i);
      streets[i].originX = origin.x;
      streets[i].originZ = origin.z;
      streets[i].orientation = StreetOrientation.eastWest;
    }

    built.clear();
    occupied.clear();
    for (final p in pallets) {
      final key = p.slotKey;
      built.add(key);
      occupied[key] = p;
    }

    cameraTarget = _computeCentroid();
  }

  Vec3 _computeCentroid() {
    if (pallets.isEmpty) {
      final c = metrics.defaultOriginForIndex((capacity.maxRuas - 1) ~/ 2);
      return Vec3(c.x, 2.2, c.z);
    }
    var sx = 0.0, sz = 0.0;
    for (final p in pallets) {
      final w = metrics.slotToWorld(streets[p.ruaIdx], p.andar, p.pos);
      sx += w.x;
      sz += w.z;
    }
    return Vec3(sx / pallets.length, 2.2, sz / pallets.length);
  }

  // ---------------- Selection ----------------

  void selectPallet(String? id) {
    selectedPalletId = id;
    notifyListeners();
  }

  void deselect() => selectPallet(null);

  // ---------------- Edit mode / layout building ----------------

  void toggleEditMode() {
    editMode = !editMode;
    selectedPalletId = null;
    if (!editMode && blockMode) {
      blockMode = false;
      selectedRuas.clear();
    }
    notifyListeners();
  }

  int? ruaNextPos(int r) {
    for (var pos = 1; pos <= capacity.maxPos; pos++) {
      if (!built.contains(slotKey(r, 1, pos))) return pos;
    }
    return null;
  }

  int columnTopAndar(int r, int pos) {
    var top = 0;
    for (var a = 1; a <= capacity.maxAndares; a++) {
      if (built.contains(slotKey(r, a, pos))) top = a;
    }
    return top;
  }

  void addRua() {
    if (streets.length >= capacity.maxRuas) {
      toasts.show('Limite de ruas do protótipo atingido');
      return;
    }
    final palette = [
      0xFF5B8DEF, 0xFF4CAF6F, 0xFFE6A23C, 0xFF9B6FE0, 0xFFE05252,
      0xFF2BB8A3, 0xFFD88AD0, 0xFFC9A227, 0xFF6FA8DC, 0xFFEF8354, 0xFF8FCE9A,
    ];
    final idx = streets.length;
    final origin = metrics.defaultOriginForIndex(idx);
    streets = List.of(streets)
      ..add(StreetDef(
        nome: 'Rua nova ${idx + 1}',
        cor: Color(palette[idx % palette.length]),
        originX: origin.x,
        originZ: origin.z,
      ));
    built.add(slotKey(idx, 1, 1));
    toasts.show('Rua nova criada');
    notifyListeners();
  }

  void addPosToRua(int r) {
    final pos = ruaNextPos(r);
    if (pos == null) {
      toasts.show('Essa rua já está no limite de posições');
      return;
    }
    built.add(slotKey(r, 1, pos));
    toasts.show('Nova posição adicionada em ${streets[r].nome}');
    notifyListeners();
  }

  void addAndarToColumn(int r, int pos) {
    final top = columnTopAndar(r, pos);
    if (top == 0 || top >= capacity.maxAndares) return;
    built.add(slotKey(r, top + 1, pos));
    toasts.show('Andar ${top + 1} adicionado em ${streets[r].nome}, posição $pos');
    notifyListeners();
  }

  void removeCell(int r, int a, int pos) {
    final key = slotKey(r, a, pos);
    if (!built.contains(key)) return;
    if (occupied.containsKey(key)) {
      toasts.show('Tem um palete aqui — mova-o antes de remover');
      return;
    }
    if (a != columnTopAndar(r, pos)) {
      toasts.show('Só dá pra remover o andar mais alto da pilha');
      return;
    }
    built.remove(key);
    toasts.show('Removido: ${streets[r].nome}, andar $a, posição $pos');
    notifyListeners();
  }

  List<EditMarker> computeEditMarkers() {
    final markers = <EditMarker>[];
    if (!editMode) return markers;

    for (var r = 0; r < streets.length; r++) {
      final pos = ruaNextPos(r);
      if (pos != null) markers.add(EditMarker.addPos(r, pos));
    }

    final columns = <String>{};
    for (final key in built) {
      final parts = key.split('_');
      columns.add('${parts[0]}_${parts[2]}');
    }
    for (final colKey in columns) {
      final parts = colKey.split('_');
      final r = int.parse(parts[0]);
      final pos = int.parse(parts[1]);
      final top = columnTopAndar(r, pos);
      if (top >= 1 && top < capacity.maxAndares) {
        markers.add(EditMarker.addAndar(r, pos, top + 1));
      }
      final topKey = slotKey(r, top, pos);
      if (top >= 1 && !occupied.containsKey(topKey)) {
        markers.add(EditMarker.remove(r, top, pos));
      }
    }

    if (streets.length < capacity.maxRuas) {
      markers.add(EditMarker.addRua(streets.length));
    }
    return markers;
  }

  List<VacancySlot> computeVacancySlots() {
    final slots = <VacancySlot>[];
    for (final key in built) {
      if (occupied.containsKey(key)) continue;
      final parts = key.split('_').map(int.parse).toList();
      slots.add(VacancySlot(ruaIdx: parts[0], andar: parts[1], pos: parts[2]));
    }
    return slots;
  }

  // ---------------- Block mode: move/rotate whole streets ----------------

  void toggleBlockMode() {
    if (!editMode) return;
    blockMode = !blockMode;
    if (!blockMode) selectedRuas.clear();
    notifyListeners();
  }

  void toggleRuaSelection(int ruaIdx) {
    if (!selectedRuas.remove(ruaIdx)) selectedRuas.add(ruaIdx);
    notifyListeners();
  }

  void clearSelectedRuas() {
    selectedRuas.clear();
    notifyListeners();
  }

  String _worldKey(double x, int andar, double z) => '${(x * 100).round()}_${andar}_${(z * 100).round()}';

  /// World-space cells (rounded, collision-comparable) occupied by the given
  /// streets' built slots, optionally shifted by a proposed (dx, dz).
  Set<String> _cellsForStreets(Iterable<int> ruaIdxs, {double dx = 0, double dz = 0}) {
    final idxSet = ruaIdxs.toSet();
    final cells = <String>{};
    for (final key in built) {
      final parts = key.split('_').map(int.parse).toList();
      if (!idxSet.contains(parts[0])) continue;
      final w = metrics.slotToWorld(streets[parts[0]], parts[1], parts[2]);
      cells.add(_worldKey(w.x + dx, parts[1], w.z + dz));
    }
    return cells;
  }

  Iterable<int> _allIndicesExcept(Set<int> exclude) sync* {
    for (var i = 0; i < streets.length; i++) {
      if (!exclude.contains(i)) yield i;
    }
  }

  /// Attempts to move every selected street by a grid-snapped (dx, dz),
  /// reverting with a toast if the destination would overlap another street.
  void moveSelectedRuas(double dx, double dz) {
    if (selectedRuas.isEmpty || (dx == 0 && dz == 0)) return;
    final proposed = _cellsForStreets(selectedRuas, dx: dx, dz: dz);
    final blocked = _cellsForStreets(_allIndicesExcept(selectedRuas));
    if (proposed.any(blocked.contains)) {
      toasts.show('Não dá pra mover ali — colidiria com outra rua');
      notifyListeners();
      return;
    }
    for (final r in selectedRuas) {
      streets[r].originX += dx;
      streets[r].originZ += dz;
    }
    toasts.show('Bloco(s) movido(s)');
    notifyListeners();
  }

  /// Rotates every selected street 90° (swapping which axis "pos" advances
  /// along), skipping any street whose rotated footprint would collide with
  /// an unselected street.
  void rotateSelectedRuas() {
    if (selectedRuas.isEmpty) return;
    final failures = <String>[];
    for (final r in selectedRuas) {
      final street = streets[r];
      final newOrientation =
          street.orientation == StreetOrientation.eastWest ? StreetOrientation.northSouth : StreetOrientation.eastWest;
      final proposed = <String>{};
      for (final key in built) {
        final parts = key.split('_').map(int.parse).toList();
        if (parts[0] != r) continue;
        final d = (parts[2] - 1) * metrics.posSpacing;
        final x = newOrientation == StreetOrientation.eastWest ? street.originX + d : street.originX;
        final z = newOrientation == StreetOrientation.northSouth ? street.originZ + d : street.originZ;
        proposed.add(_worldKey(x, parts[1], z));
      }
      final blocked = _cellsForStreets(_allIndicesExcept({r}));
      if (proposed.any(blocked.contains)) {
        failures.add(street.nome);
        continue;
      }
      street.orientation = newOrientation;
    }
    toasts.show(failures.isEmpty
        ? 'Bloco(s) girado(s) 90°'
        : 'Giradas as ruas possíveis — bloqueado por colisão: ${failures.join(", ")}');
    notifyListeners();
  }

  // ---------------- Pallet movement ----------------

  void movePallet(PalletData p, VacancySlot target) {
    final oldKey = p.slotKey;
    occupied.remove(oldKey);
    p.ruaIdx = target.ruaIdx;
    p.andar = target.andar;
    p.pos = target.pos;

    final street = streets[target.ruaIdx];
    p.mismatch = p.setorEsperado != null && street.setor != null && street.setor != p.setorEsperado;

    final newKey = p.slotKey;
    occupied[newKey] = p;

    toasts.show(p.mismatch
        ? 'Movido para ${street.nome}, andar ${p.andar}, posição ${p.pos} — atenção: fora do setor de ${p.setorEsperado}'
        : 'Movido para ${street.nome}, andar ${p.andar}, posição ${p.pos}');

    _persistToServer(p);
    selectedPalletId = p.id;
    notifyListeners();
  }

  void _persistToServer(PalletData p) {
    // Placeholder for the real WMS API integration, mirrors the prototypes'
    // `PUT /api/paletes/:id` call.
    debugPrint('PUT /api/paletes/${p.id} rua=${p.rua(streets)} andar=${p.andar} pos=${p.pos}');
  }
}

extension on PalletData {
  String rua(List<StreetDef> streets) => streets[ruaIdx].nome;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
