import 'package:flutter/material.dart';

import '../models/match_data.dart';
import 'player_photo.dart';

/// The bottom analysis panel: slides up when a marker is tapped, showing
/// identity plus a live stats panel you fill in yourself while watching.
/// The big dynamic photo lives out on the pitch, at the player's own
/// position — see [PlayerActionSpotlight].
class PlayerAnalysisCard extends StatefulWidget {
  const PlayerAnalysisCard({
    super.key,
    required this.slot,
    required this.stats,
    required this.onStatsChanged,
    required this.onClose,
  });

  final PlayerSlot slot;
  final PlayerStats stats;
  final ValueChanged<PlayerStats> onStatsChanged;
  final VoidCallback onClose;

  @override
  State<PlayerAnalysisCard> createState() => _PlayerAnalysisCardState();
}

class _PlayerAnalysisCardState extends State<PlayerAnalysisCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  String get _initials {
    final parts = widget.slot.fullName.split(' ').where((p) => p.isNotEmpty);
    return parts.map((p) => p[0]).take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final stats = widget.stats;
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: _entrance,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(_entrance.value.clamp(0, 1));
          return Transform.translate(
            offset: Offset(0, (1 - t) * 50),
            child: Opacity(opacity: t, child: child),
          );
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.5,
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF14141A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          PlayerPhoto(
                            slug: slot.photoAssetSlug,
                            initials: _initials,
                            size: 52,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  slot.fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${slot.nationality} · #${slot.shirtNumber} · ${slot.id}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: widget.onClose,
                            icon: const Icon(Icons.close_rounded),
                            color: Colors.white70,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _SectionLabel('1ST HALF — YOUR NOTES'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCounter(
                              label: 'Touches',
                              value: stats.touches,
                              onChanged: (v) => widget.onStatsChanged(
                                stats.copyWith(touches: v),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCounter(
                              label: 'Passes',
                              value: stats.passesCompleted,
                              onChanged: (v) => widget.onStatsChanged(
                                stats.copyWith(passesCompleted: v),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCounter(
                              label: 'Shots',
                              value: stats.shots,
                              onChanged: (v) => widget.onStatsChanged(
                                stats.copyWith(shots: v),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCounter(
                              label: 'Tackles',
                              value: stats.tackles,
                              onChanged: (v) => widget.onStatsChanged(
                                stats.copyWith(tackles: v),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _RatingStepper(
                        rating: stats.rating,
                        onChanged: (v) =>
                            widget.onStatsChanged(stats.copyWith(rating: v)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// A tap-to-log counter: a label, the current count, and +/- buttons — the
/// analyst (you) is the one filling this in, live.
class _StatCounter extends StatelessWidget {
  const _StatCounter({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundIconButton(
                icon: Icons.remove_rounded,
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
              ),
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              _RoundIconButton(
                icon: Icons.add_rounded,
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingStepper extends StatelessWidget {
  const _RatingStepper({required this.rating, required this.onChanged});

  final double? rating;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Your rating',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.remove_rounded,
                onPressed: rating == null
                    ? null
                    : () =>
                        onChanged(rating! - 0.5 <= 0 ? null : rating! - 0.5),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  rating == null ? '–' : rating!.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _RoundIconButton(
                icon: Icons.add_rounded,
                onPressed: () =>
                    onChanged(((rating ?? 5.0) + 0.5).clamp(0.5, 10.0)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: onPressed == null ? 0.03 : 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: onPressed == null ? Colors.white24 : Colors.white70,
          ),
        ),
      ),
    );
  }
}
