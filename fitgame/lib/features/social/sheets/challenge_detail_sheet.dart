import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../models/challenge.dart';
import '../painters/challenge_progress_painter.dart';

/// Bottom sheet showing full challenge details
class ChallengeDetailSheet extends StatelessWidget {
  const ChallengeDetailSheet({
    super.key,
    required this.challenge,
    required this.onParticipate,
  });

  final Challenge challenge;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: FGColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: Spacing.lg),

                  // Progress Circle
                  _buildProgressSection(),
                  const SizedBox(height: Spacing.lg),

                  // Challenge Info
                  _buildInfoSection(),
                  const SizedBox(height: Spacing.lg),

                  // Full Leaderboard
                  _buildLeaderboard(),
                  const SizedBox(height: Spacing.lg),

                  // Action Button
                  if (challenge.status == ChallengeStatus.active) ...[
                    _buildActionButton(context),
                    const SizedBox(height: Spacing.lg),
                  ],

                  const SizedBox(height: Spacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.bolt,
              color: _statusColor,
              size: 24,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                '"${challenge.title}"',
                style: FGTypography.h2.copyWith(
                  fontSize: 24,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          challenge.exerciseName,
          style: FGTypography.body.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          'Créé par ${challenge.creatorName}',
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    final leader = challenge.leader;
    final leaderProgress = leader?.progressPercent(challenge.targetValue) ?? 0.0;

    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(180, 180),
              painter: ChallengeProgressPainter(
                progress: leaderProgress,
                strokeWidth: 12,
                progressColor: _statusColor,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(leaderProgress * 100).toInt()}%',
                  style: FGTypography.numbers.copyWith(
                    fontSize: 40,
                    color: _statusColor,
                  ),
                ),
                Text(
                  'Leader',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FGColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow('Objectif', '${challenge.targetValue.toStringAsFixed(challenge.targetValue.truncateToDouble() == challenge.targetValue ? 0 : 1)} ${challenge.unit}'),
          const Divider(color: FGColors.glassBorder, height: Spacing.lg),
          _buildInfoRow('Participants', '${challenge.participants.length}'),
          if (challenge.deadline != null) ...[
            const Divider(color: FGColors.glassBorder, height: Spacing.lg),
            _buildInfoRow(
              'Temps restant',
              challenge.daysRemaining >= 0 ? '${challenge.daysRemaining} jours' : 'Expiré',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: FGTypography.body.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: FGTypography.body.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard() {
    final sortedParticipants = List<ChallengeParticipant>.from(challenge.participants)
      ..sort((a, b) => b.currentValue.compareTo(a.currentValue));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CLASSEMENT',
          style: FGTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.md),
        ...sortedParticipants.asMap().entries.map((entry) {
          final index = entry.key;
          final participant = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: _buildLeaderboardRow(index + 1, participant),
          );
        }),
      ],
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
    final isTop3 = rank <= 3;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: isTop3 ? FGColors.glassSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isTop3
            ? Border.all(
                color: rank == 1 ? _statusColor.withValues(alpha: 0.3) : FGColors.glassBorder,
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              medal,
              style: TextStyle(fontSize: isTop3 ? 20 : 14),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  FGColors.accent,
                  FGColors.accent.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Center(
              child: Text(
                participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
                style: FGTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: FGColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  style: FGTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: FGColors.glassBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      participant.hasCompleted ? FGColors.success : _statusColor,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${participant.currentValue.toStringAsFixed(participant.currentValue.truncateToDouble() == participant.currentValue ? 0 : 1)} ${challenge.unit}',
                style: FGTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: participant.hasCompleted ? FGColors.success : FGColors.textPrimary,
                ),
              ),
              if (participant.hasCompleted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: FGColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Complété',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.success,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onParticipate();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              FGColors.accent,
              FGColors.accent.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: FGColors.accent.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'PARTICIPER AU DÉFI',
            style: FGTypography.button.copyWith(
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
