/// A single tactical-board slot: a position on the pitch plus the player
/// assigned to it.
class PlayerSlot {
  PlayerSlot({
    required this.id,
    required this.fullName,
    required this.shortName,
    required this.shirtNumber,
    required this.nationality,
    required this.x,
    required this.y,
    required this.photoAssetSlug,
  });

  /// Tactical position code, e.g. "GK", "ST", "CB".
  final String id;
  final String fullName;
  final String shortName;
  final int shirtNumber;
  final String nationality;

  /// Normalized tactical pitch coordinates in [-1, 1], mapped straight onto
  /// [Alignment] for placement on the board.
  final double x;
  final double y;

  /// File-name stem under `assets/players/<slug>.jpg` (or `.png`). The photo
  /// card falls back to a placeholder avatar when that file isn't bundled.
  final String photoAssetSlug;
}

/// What you've logged for a player so far this half. Starts empty — these
/// are your own live observations, not pre-filled/invented figures.
class PlayerStats {
  PlayerStats({
    this.touches = 0,
    this.passesCompleted = 0,
    this.shots = 0,
    this.tackles = 0,
    this.rating,
  });

  int touches;
  int passesCompleted;
  int shots;
  int tackles;

  /// Your own 1-10 rating so far, or null if you haven't set one.
  double? rating;

  PlayerStats copyWith({
    int? touches,
    int? passesCompleted,
    int? shots,
    int? tackles,
    double? rating,
  }) {
    return PlayerStats(
      touches: touches ?? this.touches,
      passesCompleted: passesCompleted ?? this.passesCompleted,
      shots: shots ?? this.shots,
      tackles: tackles ?? this.tackles,
      rating: rating ?? this.rating,
    );
  }
}

class MatchData {
  MatchData({
    required this.id,
    required this.title,
    required this.formation,
    required this.startingXI,
  });

  final String id;
  final String title;
  final String formation;
  final List<PlayerSlot> startingXI;
}
