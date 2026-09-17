import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'vec3.dart';

/// Spherical orbit camera around a fixed [target], matching the behaviour of
/// the original Three.js prototypes: drag to orbit (theta/phi), scroll to zoom.
class OrbitCamera {
  double theta;
  double phi;
  double radius;
  Vec3 target;

  /// Small vertical offset added on top of the orbit, mirrors the "+3" bias
  /// used in the HTML prototypes so the horizon sits comfortably in frame.
  final double heightOffset;
  final double fovYDeg;
  final double minPhi;
  final double maxPhi;
  final double minRadius;
  final double maxRadius;

  OrbitCamera({
    required this.target,
    this.theta = math.pi / 4,
    this.phi = 0.95,
    this.radius = 55,
    this.heightOffset = 3,
    this.fovYDeg = 50,
    this.minPhi = 0.3,
    this.maxPhi = 1.5,
    this.minRadius = 6,
    this.maxRadius = 150,
  });

  Vec3 get eye {
    final sinPhi = math.sin(phi);
    return target +
        Vec3(
          radius * sinPhi * math.sin(theta),
          radius * math.cos(phi) + heightOffset,
          radius * sinPhi * math.cos(theta),
        );
  }

  void orbit(double dTheta, double dPhi) {
    theta -= dTheta;
    phi = (phi - dPhi).clamp(minPhi, maxPhi);
  }

  void zoom(double delta) {
    radius = (radius + delta).clamp(minRadius, maxRadius);
  }

  CameraBasis basis() {
    final eyeP = eye;
    final forward = (target - eyeP).normalized;
    var right = forward.cross(Vec3.up);
    right = right.length < 1e-6 ? const Vec3(1, 0, 0) : right.normalized;
    final up = right.cross(forward).normalized;
    return CameraBasis(eye: eyeP, forward: forward, right: right, up: up);
  }
}

class CameraBasis {
  final Vec3 eye;
  final Vec3 forward;
  final Vec3 right;
  final Vec3 up;

  const CameraBasis({
    required this.eye,
    required this.forward,
    required this.right,
    required this.up,
  });
}

class ProjectedPoint {
  final Offset screen;

  /// Distance along the camera forward axis. Used both for near-plane culling
  /// and as the depth key for painter's-algorithm sorting.
  final double depth;

  const ProjectedPoint(this.screen, this.depth);
}

/// Projects world-space points to screen space (perspective) and can build
/// unprojected rays for drag/tap interaction, without any external matrix
/// library — just camera-basis dot products.
class Projector {
  final CameraBasis cam;
  final double fovYRad;
  final Size viewport;
  final double near;

  late final double _tanHalfFov = math.tan(fovYRad / 2);
  late final double _aspect = viewport.width / math.max(1.0, viewport.height);
  late final double _focalLength = (viewport.height / 2) / _tanHalfFov;

  Projector({
    required this.cam,
    required this.fovYRad,
    required this.viewport,
    this.near = 0.2,
  });

  ProjectedPoint? project(Vec3 world) {
    final rel = world - cam.eye;
    final camZ = rel.dot(cam.forward);
    if (camZ <= near) return null;
    final camX = rel.dot(cam.right);
    final camY = rel.dot(cam.up);
    final scale = _focalLength / camZ;
    final sx = viewport.width / 2 + camX * scale;
    final sy = viewport.height / 2 - camY * scale;
    return ProjectedPoint(Offset(sx, sy), camZ);
  }

  Ray3 unproject(Offset screenPoint) {
    final ndcX = (screenPoint.dx / viewport.width) * 2 - 1;
    final ndcY = 1 - (screenPoint.dy / viewport.height) * 2;
    final dirX = ndcX * _tanHalfFov * _aspect;
    final dirY = ndcY * _tanHalfFov;
    final dir = (cam.right * dirX + cam.up * dirY + cam.forward * 1.0).normalized;
    return Ray3(origin: cam.eye, direction: dir);
  }
}
