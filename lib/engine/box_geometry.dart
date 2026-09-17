import 'vec3.dart';

/// One axis-aligned face of a [Box3], with its outward normal.
class BoxFace {
  final List<Vec3> corners; // 4 corners, consistent winding
  final Vec3 normal;

  const BoxFace(this.corners, this.normal);
}

/// Axis-aligned box anchored at [base] (its bottom-center point), extending
/// [size] up/around it. Mirrors how pallets/markers are positioned in the
/// original prototypes (slot world position = bottom-center of the stack).
class Box3 {
  final Vec3 base; // bottom-center
  final Vec3 size; // (width=x, height=y, depth=z)

  const Box3({required this.base, required this.size});

  Vec3 get center => Vec3(base.x, base.y + size.y / 2, base.z);

  List<Vec3> get corners {
    final hx = size.x / 2, hz = size.z / 2;
    return [
      Vec3(base.x - hx, base.y, base.z - hz), // 0 bottom back-left
      Vec3(base.x + hx, base.y, base.z - hz), // 1 bottom back-right
      Vec3(base.x + hx, base.y, base.z + hz), // 2 bottom front-right
      Vec3(base.x - hx, base.y, base.z + hz), // 3 bottom front-left
      Vec3(base.x - hx, base.y + size.y, base.z - hz), // 4 top back-left
      Vec3(base.x + hx, base.y + size.y, base.z - hz), // 5 top back-right
      Vec3(base.x + hx, base.y + size.y, base.z + hz), // 6 top front-right
      Vec3(base.x - hx, base.y + size.y, base.z + hz), // 7 top front-left
    ];
  }

  /// All 6 faces (CCW winding as seen from outside), with outward normals.
  List<BoxFace> get faces {
    final c = corners;
    return [
      BoxFace([c[3], c[2], c[6], c[7]], const Vec3(0, 0, 1)), // +Z front
      BoxFace([c[1], c[0], c[4], c[5]], const Vec3(0, 0, -1)), // -Z back
      BoxFace([c[2], c[1], c[5], c[6]], const Vec3(1, 0, 0)), // +X right
      BoxFace([c[0], c[3], c[7], c[4]], const Vec3(-1, 0, 0)), // -X left
      BoxFace([c[4], c[5], c[6], c[7]], const Vec3(0, 1, 0)), // +Y top
      BoxFace([c[3], c[2], c[1], c[0]], const Vec3(0, -1, 0)), // -Y bottom
    ];
  }

  /// The 12 edges of the box, as corner index pairs.
  static const List<List<int>> edgeIndices = [
    [0, 1], [1, 2], [2, 3], [3, 0], // bottom
    [4, 5], [5, 6], [6, 7], [7, 4], // top
    [0, 4], [1, 5], [2, 6], [3, 7], // verticals
  ];

  List<List<Vec3>> get edges {
    final c = corners;
    return edgeIndices.map((pair) => [c[pair[0]], c[pair[1]]]).toList();
  }

  /// Faces whose outward normal points (at least partly) toward [eye] —
  /// i.e. the faces a viewer at [eye] would actually be able to see.
  List<BoxFace> visibleFaces(Vec3 eye) {
    final result = <BoxFace>[];
    for (final f in faces) {
      final faceCenter = Vec3(
        (f.corners[0].x + f.corners[2].x) / 2,
        (f.corners[0].y + f.corners[2].y) / 2,
        (f.corners[0].z + f.corners[2].z) / 2,
      );
      final toEye = eye - faceCenter;
      if (f.normal.dot(toEye) > 0) result.add(f);
    }
    return result;
  }
}

/// A single flat, horizontal quad (used for floor vacancy / edit markers).
class FlatQuad {
  final Vec3 center;
  final double width;
  final double depth;
  final double y;

  const FlatQuad({required this.center, required this.width, required this.depth, this.y = 0});

  List<Vec3> get corners {
    final hx = width / 2, hz = depth / 2;
    final by = center.y + y;
    return [
      Vec3(center.x - hx, by, center.z - hz),
      Vec3(center.x + hx, by, center.z - hz),
      Vec3(center.x + hx, by, center.z + hz),
      Vec3(center.x - hx, by, center.z + hz),
    ];
  }
}

/// Simple directional-light Lambert shading factor in [minFactor, 1.0],
/// used to give the isometric boxes a believable sense of depth.
double shadeFactor(Vec3 normal, {Vec3 light = const Vec3(0.42, 0.78, 0.32), double minFactor = 0.45}) {
  final l = light.normalized;
  final d = normal.dot(l).clamp(0.0, 1.0);
  return minFactor + (1 - minFactor) * d;
}
