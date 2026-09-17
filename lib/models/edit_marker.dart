enum EditMarkerType { addPos, addAndar, addRua, remove }

/// A clickable "build mode" marker: green = new position, cyan = stack a
/// floor, purple = new aisle, red = remove the top (empty) cell of a stack.
class EditMarker {
  final EditMarkerType type;
  final int ruaIdx;
  final int andar;
  final int pos;

  const EditMarker.addPos(this.ruaIdx, this.pos)
      : type = EditMarkerType.addPos,
        andar = 0;

  const EditMarker.addAndar(this.ruaIdx, this.pos, this.andar) : type = EditMarkerType.addAndar;

  const EditMarker.addRua(this.ruaIdx)
      : type = EditMarkerType.addRua,
        andar = 0,
        pos = 0;

  const EditMarker.remove(this.ruaIdx, this.andar, this.pos) : type = EditMarkerType.remove;
}

class VacancySlot {
  final int ruaIdx;
  final int andar;
  final int pos;

  const VacancySlot({required this.ruaIdx, required this.andar, required this.pos});

  String get key => '${ruaIdx}_${andar}_$pos';
}
