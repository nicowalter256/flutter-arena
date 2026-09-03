import 'dart:math';

import '../models/match_data.dart';

/// A plausible, role-appropriate 45th-minute starting point for [slot] —
/// not real match data, just a believable seed so the stats panel doesn't
/// open on a wall of zeros. Deterministic per player (seeded on shirt
/// number) so re-opening a card doesn't reshuffle it; edit away from there.
PlayerStats seedStatsFor(PlayerSlot slot) {
  final rng = Random(slot.shirtNumber * 97 + slot.id.length);
  int between(int min, int max) => min + rng.nextInt(max - min + 1);
  double rating(double min, double max) {
    final value = min + rng.nextDouble() * (max - min);
    return (value * 2).round() / 2;
  }

  switch (slot.id) {
    case 'GK':
      return PlayerStats(
        touches: between(14, 24),
        passesCompleted: between(9, 18),
        shots: 0,
        tackles: between(0, 1),
        rating: rating(6.2, 7.4),
      );
    case 'RCB':
    case 'LCB':
      return PlayerStats(
        touches: between(38, 58),
        passesCompleted: between(32, 48),
        shots: between(0, 1),
        tackles: between(2, 4),
        rating: rating(6.4, 7.6),
      );
    case 'RB':
    case 'LB':
      return PlayerStats(
        touches: between(34, 52),
        passesCompleted: between(26, 40),
        shots: between(0, 1),
        tackles: between(1, 3),
        rating: rating(6.5, 7.8),
      );
    case 'RCM':
    case 'LCM':
      return PlayerStats(
        touches: between(42, 62),
        passesCompleted: between(33, 52),
        shots: between(0, 2),
        tackles: between(2, 4),
        rating: rating(6.6, 8.0),
      );
    case 'CAM':
      return PlayerStats(
        touches: between(32, 48),
        passesCompleted: between(23, 38),
        shots: between(1, 3),
        tackles: between(0, 2),
        rating: rating(6.8, 8.4),
      );
    case 'RW':
    case 'LW':
      return PlayerStats(
        touches: between(22, 38),
        passesCompleted: between(14, 26),
        shots: between(1, 3),
        tackles: between(0, 1),
        rating: rating(6.6, 8.2),
      );
    case 'ST':
      return PlayerStats(
        touches: between(14, 26),
        passesCompleted: between(7, 16),
        shots: between(2, 4),
        tackles: between(0, 1),
        rating: rating(6.4, 8.0),
      );
    default:
      return PlayerStats(rating: rating(6.5, 7.5));
  }
}

/// Manchester United's 2026/27 squad, current as of 5 August 2026 (per the
/// club's official squad list), arranged in a plausible 4-3-3.
MatchData buildSampleMatch() {
  return MatchData(
    id: 'manutd-2026-27',
    title: 'Manchester United — 2026/27',
    formation: '4-3-3',
    startingXI: [
      PlayerSlot(
        id: 'GK',
        fullName: 'Senne Lammens',
        shortName: 'Lammens',
        shirtNumber: 31,
        nationality: 'Belgium',
        x: 0.0,
        y: -0.92,
        photoAssetSlug: 'lammens',
      ),
      PlayerSlot(
        id: 'RB',
        fullName: 'Diogo Dalot',
        shortName: 'Dalot',
        shirtNumber: 2,
        nationality: 'Portugal',
        x: 0.65,
        y: -0.55,
        photoAssetSlug: 'dalot',
      ),
      PlayerSlot(
        id: 'RCB',
        fullName: 'Matthijs de Ligt',
        shortName: 'De Ligt',
        shirtNumber: 4,
        nationality: 'Netherlands',
        x: 0.22,
        y: -0.62,
        photoAssetSlug: 'de_ligt',
      ),
      PlayerSlot(
        id: 'LCB',
        fullName: 'Lisandro Martínez',
        shortName: 'Martínez',
        shirtNumber: 6,
        nationality: 'Argentina',
        x: -0.22,
        y: -0.62,
        photoAssetSlug: 'martinez',
      ),
      PlayerSlot(
        id: 'LB',
        fullName: 'Patrick Dorgu',
        shortName: 'Dorgu',
        shirtNumber: 13,
        nationality: 'Denmark',
        x: -0.65,
        y: -0.55,
        photoAssetSlug: 'dorgu',
      ),
      PlayerSlot(
        id: 'RCM',
        fullName: 'Youri Tielemans',
        shortName: 'Tielemans',
        shirtNumber: 18,
        nationality: 'Belgium',
        x: 0.3,
        y: -0.1,
        photoAssetSlug: 'tielemans',
      ),
      PlayerSlot(
        id: 'LCM',
        fullName: 'Kobbie Mainoo',
        shortName: 'Mainoo',
        shirtNumber: 37,
        nationality: 'England',
        x: -0.3,
        y: -0.1,
        photoAssetSlug: 'mainoo',
      ),
      PlayerSlot(
        id: 'CAM',
        fullName: 'Bruno Fernandes',
        shortName: 'Fernandes',
        shirtNumber: 8,
        nationality: 'Portugal',
        x: 0.0,
        y: 0.12,
        photoAssetSlug: 'fernandes',
      ),
      PlayerSlot(
        id: 'RW',
        fullName: 'Bryan Mbeumo',
        shortName: 'Mbeumo',
        shirtNumber: 19,
        nationality: 'Cameroon',
        x: 0.65,
        y: 0.55,
        photoAssetSlug: 'mbeumo',
      ),
      PlayerSlot(
        id: 'ST',
        fullName: 'Benjamin Šeško',
        shortName: 'Šeško',
        shirtNumber: 30,
        nationality: 'Slovenia',
        x: 0.0,
        y: 0.72,
        photoAssetSlug: 'sesko',
      ),
      PlayerSlot(
        id: 'LW',
        fullName: 'Marcus Rashford',
        shortName: 'Rashford',
        shirtNumber: 14,
        nationality: 'England',
        x: -0.65,
        y: 0.55,
        photoAssetSlug: 'rashford',
      ),
    ],
  );
}
