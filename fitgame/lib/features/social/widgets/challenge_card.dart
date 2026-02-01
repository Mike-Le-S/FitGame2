import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';
import '../models/challenge.dart';
import 'participant_avatars.dart';

/// Card displaying a challenge in the challenges tab
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.onTap,
    required this.onParticipate,
  });

  final Challenge challenge;
  final VoidCallback onTap;
  final VoidCallback onParticipate;

  Color get _statusColor {
    switch (challenge.status) {
      case ChallengeStatus.active:
        return FGColors.accent;
      case ChallengeStatus.completed:
        return FGColors.success;
      case ChallengeStatus.expired:
        return FGColors.textSecondary;
    }
  }

  String get _statusLabel {
    switch (challenge.status) {
      case ChallengeStatus.active:
        return 'DÉFI ACTIF';
      case ChallengeStatus.completed:
        return 'TERMINÉ';
      case ChallengeStatus.expired:
        return 'EXPIRÉ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FGGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          _buildHeader(),
          const SizedBox(height: Spacing.md),

          // Challenge title and exercise
          _buildTitleSection(),
          const SizedBox(height: Spacing.md),

          // Creator and participants
          _buildParticipantsSection(),
          const SizedBox(height: Spacing.md),

          // Leaderboard (top 3)
          _buildLeaderboard(),
          const SizedBox(height: Spacing.md),

          // Action buttons
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.bolt,
          color: _statusColor,
          size: 18,
        ),
        const SizedBox(width: Spacing.xs),
        Text(
          _statusLabel,
          style: FGTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: _statusColor,
          ),
        ),
        const Spacer(),
        if (challenge.daysRemaining >= 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${challenge.daysRemaining}j restants',
              style: FGTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '"${challenge.title}"',
          style: FGTypography.h3.copyWith(
            fontSize: 18,
            color: FGColors.textPrimary,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          challenge.exerciseName,
          style: FGTypography.bodySmall.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    return Row(
      children: [
        Text(
          'Créé par ${challenge.creatorName}',
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
        const Spacer(),
        ParticipantAvatars(
          participants: challenge.participants,
          maxVisible: 3,
          size: 28,
        ),
      ],
    );
  }

  Widget _buildLeaderboard() {
    final sortedParticipants = List<ChallengeParticipant>.from(challenge.participants)
      ..sort((a, b) => b.currentValue.compareTo(a.currentValue));

    final topThree = sortedParticipants.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FGColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < topThree.length; i++) ...[
            if (i > 0) const SizedBox(height: Spacing.sm),
            _buildLeaderboardRow(i + 1, topThree[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(int rank, ChallengeParticipant participant) {
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank.',
    };

    final progress = participant.progressPercent(challenge.targetValue);

    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            medal,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            participant.name,
            style: FGTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: rank == 1 ? FGColors.textPrimary : FGColors.textSecondary,
            ),
          ),
        ),
        if (participant.hasCompleted)
          Icon(
            Icons.check_circle,
            size: 16,
            color: FGColors.success,
          )
        else
          Text(
            '${(progress * 100).toInt()}%',
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
            ),
          ),
        const SizedBox(width: Spacing.sm),
        Text(
          '${participant.currentValue.toStringAsFixed(participant.currentValue.truncateToDouble() == participant.currentValue ? 0 : 1)}${challenge.unit}',
          style: FGTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: participant.hasCompleted ? FGColors.success : FGColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              decoration: BoxDecoration(
                color: FGColors.glassSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: FGColors.glassBorder,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'VOIR DÉTAILS',
                  style: FGTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: FGColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        if (challenge.status == ChallengeStatus.active)
          Expanded(
            child: GestureDetector(
              onTap: onParticipate,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      FGColors.accent,
                      FGColors.accent.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: FGColors.accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'PARTICIPER',
                    style: FGTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: FGColors.textOnAccent,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
