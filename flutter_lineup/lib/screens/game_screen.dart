import 'package:flutter/material.dart';

import '../data/sample_matches.dart';
import '../models/match_data.dart';
import '../widgets/match_header.dart';
import '../widgets/orbit_pitch.dart';
import '../widgets/player_analysis_card.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MatchData _match = buildSampleMatch();
  late final Map<String, PlayerStats> _stats = {
    for (final slot in _match.startingXI) slot.id: seedStatsFor(slot),
  };
  PlayerSlot? _selected;

  void _select(PlayerSlot slot) => setState(() => _selected = slot);
  void _dismiss() => setState(() => _selected = null);
  void _updateStats(String slotId, PlayerStats stats) =>
      setState(() => _stats[slotId] = stats);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F0C),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 90, 16, 24),
              child: OrbitPitch(
                slots: _match.startingXI,
                selectedSlotId: _selected?.id,
                onSelect: _select,
                onBackgroundTap: _selected == null ? null : _dismiss,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MatchHeader(match: _match),
          ),
          if (_selected != null)
            Positioned.fill(
              child: PlayerAnalysisCard(
                slot: _selected!,
                stats: _stats[_selected!.id]!,
                onStatsChanged: (stats) => _updateStats(_selected!.id, stats),
                onClose: _dismiss,
              ),
            ),
        ],
      ),
    );
  }
}
