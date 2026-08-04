import 'dart:math' as math;
import 'dart:typed_data';

/// A cooling event: cell ([gridX], [gridY]) just dropped below the
/// solidification threshold after having been hot, in grid-normalized
/// coordinates ([0, 1]).
class CoolingEvent {
  const CoolingEvent(this.gridX, this.gridY);
  final double gridX;
  final double gridY;
}

/// A CPU implementation of Jos Stam's "Stable Fluids" on a square grid —
/// semi-Lagrangian advection, a Jacobi-iterated pressure projection to keep
/// the velocity field divergence-free, and vorticity confinement layered on
/// top to restore the swirls/tendrils the projection step's numerical
/// diffusion would otherwise smooth away.
///
/// This runs entirely in Dart on a modest grid (see [resolution]) rather
/// than as a GPU compute shader — a deliberate scope choice: it's the same
/// underlying math, verifiable and debuggable as plain code, at a
/// resolution that comfortably fits a 16ms frame budget.
class FluidSimulation {
  FluidSimulation({this.resolution = 48});

  /// Cells per side. `resolution * resolution` floats per field.
  final int resolution;

  late final Float32List _velX = Float32List(_cellCount);
  late final Float32List _velY = Float32List(_cellCount);
  late final Float32List _velX0 = Float32List(_cellCount);
  late final Float32List _velY0 = Float32List(_cellCount);
  late final Float32List _heat = Float32List(_cellCount);
  late final Float32List _heat0 = Float32List(_cellCount);
  late final Float32List _pressure = Float32List(_cellCount);
  late final Float32List _divergence = Float32List(_cellCount);
  late final Float32List _curl = Float32List(_cellCount);
  late final Float32List _absCurl = Float32List(_cellCount);

  /// Whether each cell was hot enough to count as "burning" as of the last
  /// step, so a single threshold crossing fires exactly one [CoolingEvent]
  /// (hysteresis prevents it firing repeatedly while hovering near the
  /// threshold).
  late final List<bool> _wasBurning = List.filled(_cellCount, false);

  int get _cellCount => resolution * resolution;

  /// Public read access to the heat field for rendering, in row-major
  /// order, values roughly in `[0, 1]` (can exceed it briefly near a fresh
  /// splat before the next step's clamp).
  Float32List get heat => _heat;

  static const double _coolingRate = 0.62; // per second
  static const double _velocityDamping = 0.18; // per second
  static const double _vorticityStrength = 10.0;
  // Kept low deliberately: this runs on Dart's unoptimized debug web
  // compiler (DDC) too, not just release builds, and a full Jos Stam
  // "project twice" pass at a large grid/iteration count was slow enough
  // there to peg the CPU and stall the browser's event loop entirely
  // (measured directly — not a hypothetical). One projection pass at a
  // modest grid/iteration count is still recognizably fluid and stays
  // inside a 16ms frame budget in debug mode.
  static const int _pressureIterations = 10;
  static const double _debrisThreshold = 0.22;
  static const double _reigniteThreshold = 0.34;

  int _idx(int x, int y) => y * resolution + x;

  int _clampCoord(int v) => v < 0 ? 0 : (v >= resolution ? resolution - 1 : v);

  /// Injects heat and a directional velocity impulse centered at
  /// ([gridX], [gridY]) (grid-normalized `[0, 1]`), falling off over
  /// [radiusCells]. [dirX]/[dirY] should already be scaled by drag speed.
  void splat({
    required double gridX,
    required double gridY,
    required double dirX,
    required double dirY,
    double radiusCells = 4.0,
    double heatAmount = 1.4,
  }) {
    final cx = gridX * resolution;
    final cy = gridY * resolution;
    final r = radiusCells;
    final minX = _clampCoord((cx - r).floor());
    final maxX = _clampCoord((cx + r).ceil());
    final minY = _clampCoord((cy - r).floor());
    final maxY = _clampCoord((cy + r).ceil());

    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final dx = x - cx;
        final dy = y - cy;
        final dist2 = dx * dx + dy * dy;
        final falloff = _gaussian(dist2, r * r);
        if (falloff <= 0.001) continue;
        final i = _idx(x, y);
        _heat[i] += heatAmount * falloff;
        _velX[i] += dirX * falloff;
        _velY[i] += dirY * falloff;
      }
    }
  }

  double _gaussian(double dist2, double sigma2) {
    if (sigma2 <= 0) return 0;
    final v = dist2 / sigma2;
    if (v > 6) return 0;
    return math.exp(-v);
  }

  /// Advances the simulation by [dt] seconds. Returns the cells that just
  /// solidified this step, if any (usually empty on most frames).
  List<CoolingEvent> step(double dt) {
    if (dt <= 0) return const [];

    _applyVorticityConfinement(dt);
    _dampVelocity(dt);

    // The textbook Jos Stam velocity step projects both before and after
    // advection. One pass, after advection (so the field used to carry
    // heat is the divergence-free one), is the cheaper half of that and
    // still reads as fluid at this grid size/frame budget.
    _advectVelocity(dt);
    _project();

    _advectHeat(dt);
    _coolHeat(dt);

    return _detectCoolingEvents();
  }

  void _applyVorticityConfinement(double dt) {
    final n = resolution;
    for (var y = 1; y < n - 1; y++) {
      for (var x = 1; x < n - 1; x++) {
        final i = _idx(x, y);
        final dvyDx = (_velY[_idx(x + 1, y)] - _velY[_idx(x - 1, y)]) * 0.5;
        final dvxDy = (_velX[_idx(x, y + 1)] - _velX[_idx(x, y - 1)]) * 0.5;
        _curl[i] = dvyDx - dvxDy;
        _absCurl[i] = _curl[i].abs();
      }
    }
    for (var y = 1; y < n - 1; y++) {
      for (var x = 1; x < n - 1; x++) {
        final i = _idx(x, y);
        var gx = (_absCurl[_idx(x + 1, y)] - _absCurl[_idx(x - 1, y)]) * 0.5;
        var gy = (_absCurl[_idx(x, y + 1)] - _absCurl[_idx(x, y - 1)]) * 0.5;
        final len = _sqrt(gx * gx + gy * gy) + 1e-5;
        gx /= len;
        gy /= len;
        final c = _curl[i];
        // N x (0, 0, c) in 2D reduces to (gy*c, -gx*c).
        _velX[i] += _vorticityStrength * gy * c * dt;
        _velY[i] += -_vorticityStrength * gx * c * dt;
      }
    }
  }

  void _dampVelocity(double dt) {
    final factor = (1.0 - _velocityDamping * dt).clamp(0.0, 1.0);
    for (var i = 0; i < _cellCount; i++) {
      _velX[i] *= factor;
      _velY[i] *= factor;
    }
  }

  /// Makes the velocity field (approximately) divergence-free: computes the
  /// divergence, solves the discrete Poisson equation for a pressure field
  /// via Jacobi relaxation, then subtracts the pressure gradient.
  void _project() {
    final n = resolution;
    for (var y = 1; y < n - 1; y++) {
      for (var x = 1; x < n - 1; x++) {
        final i = _idx(x, y);
        _divergence[i] =
            -0.5 *
            ((_velX[_idx(x + 1, y)] - _velX[_idx(x - 1, y)]) +
                (_velY[_idx(x, y + 1)] - _velY[_idx(x, y - 1)]));
        _pressure[i] = 0;
      }
    }
    for (var iter = 0; iter < _pressureIterations; iter++) {
      for (var y = 1; y < n - 1; y++) {
        for (var x = 1; x < n - 1; x++) {
          final i = _idx(x, y);
          _pressure[i] =
              (_divergence[i] +
                  _pressure[_idx(x - 1, y)] +
                  _pressure[_idx(x + 1, y)] +
                  _pressure[_idx(x, y - 1)] +
                  _pressure[_idx(x, y + 1)]) /
              4.0;
        }
      }
    }
    for (var y = 1; y < n - 1; y++) {
      for (var x = 1; x < n - 1; x++) {
        final i = _idx(x, y);
        _velX[i] -=
            0.5 * (_pressure[_idx(x + 1, y)] - _pressure[_idx(x - 1, y)]);
        _velY[i] -=
            0.5 * (_pressure[_idx(x, y + 1)] - _pressure[_idx(x, y - 1)]);
      }
    }
  }

  void _advectVelocity(double dt) {
    _velX0.setAll(0, _velX);
    _velY0.setAll(0, _velY);
    _advectField(_velX, _velX0, dt);
    _advectField(_velY, _velY0, dt);
  }

  void _advectHeat(double dt) {
    _heat0.setAll(0, _heat);
    _advectField(_heat, _heat0, dt);
  }

  /// Semi-Lagrangian advection: each cell samples the previous field at the
  /// position the flow would have carried it *from*, bilinearly
  /// interpolated. Open (clamped) boundaries — the field is free to bleed
  /// toward the edges rather than bouncing off solid walls.
  void _advectField(Float32List dst, Float32List src, double dt) {
    final n = resolution;
    final dtScaled = dt * n;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final i = _idx(x, y);
        var px = x - dtScaled * _velX[i];
        var py = y - dtScaled * _velY[i];
        px = px.clamp(0.0, (n - 1).toDouble());
        py = py.clamp(0.0, (n - 1).toDouble());

        final x0 = px.floor();
        final x1 = _clampCoord(x0 + 1);
        final y0 = py.floor();
        final y1 = _clampCoord(y0 + 1);
        final sx = px - x0;
        final sy = py - y0;

        final v00 = src[_idx(x0, y0)];
        final v10 = src[_idx(x1, y0)];
        final v01 = src[_idx(x0, y1)];
        final v11 = src[_idx(x1, y1)];
        final top = v00 + (v10 - v00) * sx;
        final bottom = v01 + (v11 - v01) * sx;
        dst[i] = top + (bottom - top) * sy;
      }
    }
  }

  void _coolHeat(double dt) {
    final factor = (1.0 - _coolingRate * dt).clamp(0.0, 1.0);
    for (var i = 0; i < _cellCount; i++) {
      final v = _heat[i] * factor;
      _heat[i] = v < 0.002 ? 0.0 : (v > 2.0 ? 2.0 : v);
    }
  }

  List<CoolingEvent> _detectCoolingEvents() {
    List<CoolingEvent>? events;
    final n = resolution;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final i = _idx(x, y);
        final h = _heat[i];
        final wasBurning = _wasBurning[i];
        if (!wasBurning && h > _reigniteThreshold) {
          _wasBurning[i] = true;
        } else if (wasBurning && h < _debrisThreshold) {
          _wasBurning[i] = false;
          (events ??= []).add(CoolingEvent(x / n, y / n));
        }
      }
    }
    return events ?? const [];
  }

  double _sqrt(double x) => x <= 0 ? 0 : math.sqrt(x);
}
