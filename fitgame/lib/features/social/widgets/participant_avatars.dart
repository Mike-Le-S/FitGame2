import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../models/challenge.dart';

/// Stacked avatar display for challenge participants
class ParticipantAvatars extends StatelessWidget {
  const ParticipantAvatars({
    super.key,
    required this.participants,
    this.maxVisible = 3,
    this.size = 32,
  });

  final List<ChallengeParticipant> participants;
  final int maxVisible;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visibleCount = participants.length.clamp(0, maxVisible);
    final extraCount = participants.length - maxVisible;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size + (visibleCount - 1) * (size * 0.6),
          height: size,
          child: Stack(
            children: [
              for (int i = visibleCount - 1; i >= 0; i--)
                Positioned(
                  left: i * (size * 0.6),
                  child: _buildAvatar(participants[i]),
                ),
            ],
          ),
        ),
        if (extraCount > 0) ...[
          const SizedBox(width: 8),
          Text(
            '+$extraCount',
            style: FGTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: FGColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar(ChallengeParticipant participant) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: FGColors.background,
          width: 2,
        ),
        gradient: LinearGradient(
          colors: [
            FGColors.accent,
            FGColors.accent.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipOval(
        child: participant.avatarUrl.isNotEmpty
            ? Image.network(
                participant.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildInitials(participant.name),
              )
            : _buildInitials(participant.name),
      ),
    );
  }

  Widget _buildInitials(String name) {
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    return Center(
      child: Text(
        initials,
        style: FGTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
          color: FGColors.textPrimary,
        ),
      ),
    );
  }
}
