import 'package:flutter_scene/scene.dart';

/// A self-contained visual effect: builds its own node(s) into a [Scene].
///
/// One-shot effects (bursts) override [trigger]; continuous effects run on
/// their own once loaded and may expose their own on/off toggle beyond this
/// shared interface (see `EmbersEffect.enabled`) since only one of the
/// effects in this playground needs one.
abstract class VfxEffect {
  String get label;

  Future<void> load(Scene scene);

  /// Fires a one-shot burst. No-op for continuous effects.
  void trigger() {}

  /// Per-frame update hook for effects that need custom motion (e.g. a
  /// trail's moving anchor). No-op by default.
  void tick(double t, double deltaSeconds) {}
}
