import 'dart:math' as math;

/// Minimal immutable 3D vector used by the warehouse scene engine.
class Vec3 {
  final double x, y, z;

  const Vec3(this.x, this.y, this.z);

  static const zero = Vec3(0, 0, 0);
  static const up = Vec3(0, 1, 0);

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);
  Vec3 operator -() => Vec3(-x, -y, -z);

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;

  Vec3 cross(Vec3 o) =>
      Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);

  double get length => math.sqrt(x * x + y * y + z * z);

  Vec3 get normalized {
    final l = length;
    if (l < 1e-9) return this;
    return Vec3(x / l, y / l, z / l);
  }

  Vec3 withY(double newY) => Vec3(x, newY, z);

  @override
  String toString() =>
      'Vec3(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${z.toStringAsFixed(2)})';
}

/// A world-space ray, used to unproject screen taps/drags back into the 3D scene.
class Ray3 {
  final Vec3 origin;
  final Vec3 direction;

  const Ray3({required this.origin, required this.direction});

  /// Intersects the ray with the horizontal plane `y = planeY`.
  /// Returns null if the ray is parallel to the plane or the intersection is behind it.
  Vec3? intersectHorizontalPlane(double planeY) {
    if (direction.y.abs() < 1e-9) return null;
    final t = (planeY - origin.y) / direction.y;
    if (t < 0) return null;
    return origin + direction * t;
  }
}
