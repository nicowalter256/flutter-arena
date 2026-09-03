import 'package:flutter/material.dart';

/// Loads `assets/players/<slug>` trying `.jpg`, `.jpeg`, then `.png` in
/// turn; falls back to an initials avatar when none exist. Drop a real
/// photo at any of those paths and it's picked up automatically — no code
/// changes.
class PlayerPhoto extends StatelessWidget {
  const PlayerPhoto({
    super.key,
    required this.slug,
    required this.initials,
    this.size = 96,
    double? width,
    double? height,
    this.round = true,
    this.fadeBottom = false,
  }) : width = width ?? size,
       height = height ?? size;

  final String slug;
  final String initials;
  final double size;
  final double width;
  final double height;

  /// Circular avatar when true; a plain rectangle (for the on-pitch cutout)
  /// when false.
  final bool round;

  /// Fades the photo to transparent at the bottom — a cheap way to suggest
  /// a standing cutout without real background removal.
  final bool fadeBottom;

  static const _placeholderStart = Color(0xFFDA291C);
  static const _placeholderEnd = Color(0xFF6E0E0E);

  static const _extensions = ['jpg', 'jpeg', 'png'];

  @override
  Widget build(BuildContext context) {
    Widget content = SizedBox(
      width: width,
      height: height,
      child: _imageChain(0),
    );

    if (fadeBottom) {
      content = ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0, 0.72, 1],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: content,
      );
    }

    return round
        ? ClipOval(child: content)
        : ClipRRect(borderRadius: BorderRadius.circular(14), child: content);
  }

  Widget _imageChain(int index) {
    if (index >= _extensions.length) return _placeholder();
    return Image.asset(
      'assets/players/$slug.${_extensions[index]}',
      fit: BoxFit.cover,
      // Most bundled photos are taller action/lineup shots; anchoring the
      // crop to the top keeps the face in frame instead of centering on a
      // torso.
      alignment: Alignment.topCenter,
      errorBuilder: (context, error, stackTrace) => _imageChain(index + 1),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_placeholderStart, _placeholderEnd],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: (width < height ? width : height) * 0.32,
        ),
      ),
    );
  }
}
