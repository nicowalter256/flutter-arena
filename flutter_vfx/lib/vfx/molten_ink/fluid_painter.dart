import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'fluid_simulation.dart';

/// Temperature ramp stops as `(heat, r, g, b, a)`, from cold/transparent
/// through cool ash gray, deep crimson, bright yellow, to white-hot.
const _rampStops = <(double, int, int, int, int)>[
  (0.0, 8, 6, 10, 0),
  (0.12, 70, 46, 42, 130),
  (0.4, 150, 24, 16, 220),
  (0.7, 255, 140, 25, 255),
  (1.0, 255, 250, 225, 255),
];

(int, int, int, int) _rampColor(double heat) {
  final h = heat.clamp(0.0, 1.0);
  for (var i = 1; i < _rampStops.length; i++) {
    final a = _rampStops[i - 1];
    final b = _rampStops[i];
    if (h <= b.$1) {
      final span = b.$1 - a.$1;
      final f = span <= 0 ? 0.0 : (h - a.$1) / span;
      return (
        _lerpInt(a.$2, b.$2, f),
        _lerpInt(a.$3, b.$3, f),
        _lerpInt(a.$4, b.$4, f),
        _lerpInt(a.$5, b.$5, f),
      );
    }
  }
  final last = _rampStops.last;
  return (last.$2, last.$3, last.$4, last.$5);
}

int _lerpInt(int a, int b, double t) => (a + (b - a) * t).round();

/// Converts a [FluidSimulation]'s heat grid into an RGBA pixel buffer via
/// the temperature ramp above, then hands it to [ui.decodeImageFromPixels]
/// for upload. This is async, so it's driven from the tick loop rather
/// than from [CustomPainter.paint] (which is synchronous) — see
/// `MoltenInkScreen`.
Future<ui.Image> renderHeatFieldToImage(FluidSimulation sim) {
  final n = sim.resolution;
  final heatField = sim.heat;
  final pixels = Uint8List(n * n * 4);
  for (var i = 0; i < n * n; i++) {
    final (r, g, b, a) = _rampColor(heatField[i]);
    final o = i * 4;
    pixels[o] = r;
    pixels[o + 1] = g;
    pixels[o + 2] = b;
    pixels[o + 3] = a;
  }
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    n,
    n,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

/// Paints the latest decoded heat-field image full-bleed over a dark base,
/// with a second blurred additive pass layered on top for a cheap glow —
/// standard fake-bloom, no HDR needed since it's plain `dart:ui` Canvas.
class FluidPainter extends CustomPainter {
  FluidPainter({required this.image, super.repaint});

  final ui.Image? image;

  @override
  void paint(Canvas canvas, Size size) {
    // No opaque base fill here deliberately: this paints on top of the
    // debris SceneView (see MoltenInkScreen), so anywhere the heat field is
    // cold (alpha 0 at the ramp's first stop) needs to stay genuinely
    // transparent, not paint over the 3D layer beneath it. The Scaffold's
    // own black background is the "dark, moody" base.
    final bounds = Offset.zero & size;
    final img = image;
    if (img == null) return;

    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());

    canvas.drawImageRect(
      img,
      src,
      bounds,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.drawImageRect(
      img,
      src,
      bounds,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..blendMode = BlendMode.plus
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
    );
  }

  @override
  bool shouldRepaint(covariant FluidPainter oldDelegate) =>
      !identical(oldDelegate.image, image);
}
