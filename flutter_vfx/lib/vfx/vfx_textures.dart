import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// A soft, round white dot with a Gaussian falloff (slope zero at the rim),
/// used as the base sprite for every particle effect in this playground.
///
/// This is a pure radial gradient — no noise involved — so, unlike a
/// flipbook baked from CPU noise, it renders identically on every platform
/// including web (see the caveat on `FastNoiseLite` in flutter_scene's
/// `noise.dart`: its 32-bit hashing can overflow in Dart-on-web).
Future<ui.Image> bakeSoftDot({int size = 64}) {
  final pixels = Uint8List(size * size * 4);
  final half = size / 2;
  final sigma = size * 0.20;
  final rim = _gaussian(half, sigma);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x + 0.5 - half;
      final dy = y + 0.5 - half;
      final r = math.sqrt(dx * dx + dy * dy);
      final g = _gaussian(r, sigma);
      final a = ((g - rim) / (1.0 - rim)).clamp(0.0, 1.0);
      final i = (y * size + x) * 4;
      pixels[i] = 255;
      pixels[i + 1] = 255;
      pixels[i + 2] = 255;
      pixels[i + 3] = (a * 255).round();
    }
  }
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    size,
    size,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

double _gaussian(double r, double sigma) {
  final z = r / sigma;
  return math.exp(-0.5 * z * z);
}
