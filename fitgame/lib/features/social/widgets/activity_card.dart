import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_glass_card.dart';
import '../models/activity.dart';
import 'pr_badge.dart';
import 'respect_button.dart';

/// Card displaying a workout activity in the social feed
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    required this.onRespect,
  });

  final Activity activity;
  final VoidCallback onTap;
  final VoidCallback onRespect;

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    return 'il y a ${(diff.inDays / 7).floor()}sem';
  }

  String _formatVolume(double volumeKg) {
    if (volumeKg >= 1000) {
      return '${(volumeKg / 1000).toStringAsFixed(1)}t';
    }
    return '${volumeKg.toStringAsFixed(0)}kg';
  }

  @override
  Widget build(BuildContext context) {
    return FGGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Time
          _buildHeader(),
          const SizedBox(height: Spacing.md),

          // PR Badge (if applicable)
          if (activity.pr != null) ...[
            PRBadge(pr: activity.pr!),
            const SizedBox(height: Spacing.md),
          ],

          // Muscles & Stats
          _buildMusclesAndStats(),
          const SizedBox(height: Spacing.md),

          // Top 3 Exercises
          if (activity.topExercises.isNotEmpty) ...[
            _buildTopExercises(),
            const SizedBox(height: Spacing.md),
          ],

          // Respect section
          _buildRespectSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
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
            child: activity.userAvatarUrl.isNotEmpty
                ? Image.network(
                    activity.userAvatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildInitials(),
                  )
                : _buildInitials(),
          ),
        ),
        const SizedBox(width: Spacing.md),
        // Name & Workout
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.userName,
                style: FGTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: FGColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                activity.workoutName,
                style: FGTypography.bodySmall.copyWith(
                  color: FGColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Timestamp
        Text(
          _formatTimeAgo(activity.timestamp),
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInitials() {
    final initials = activity.userName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    return Center(
      child: Text(
        initials,
        style: FGTypography.body.copyWith(
          fontWeight: FontWeight.w700,
          color: FGColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildMusclesAndStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activity.muscles,
          style: FGTypography.bodySmall.copyWith(
            color: FGColors.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Row(
          children: [
            Flexible(child: _buildStatItem(Icons.timer_outlined, '${activity.durationMinutes} min')),
            const SizedBox(width: Spacing.md),
            Flexible(child: _buildStatItem(Icons.fitness_center, _formatVolume(activity.volumeKg))),
            const SizedBox(width: Spacing.md),
            Flexible(child: _buildStatItem(Icons.format_list_numbered, '${activity.exerciseCount} exos')),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: FGColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTopExercises() {
    return Row(
      children: [
        for (int i = 0; i < activity.topExercises.length && i < 3; i++) ...[
          if (i > 0) const SizedBox(width: Spacing.sm),
          Expanded(child: _buildExerciseChip(activity.topExercises[i])),
        ],
      ],
    );
  }

  Widget _buildExerciseChip(ExerciseSummary exercise) {
    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: FGColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.shortName,
            style: FGTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: FGColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            exercise.display,
            style: FGTypography.caption.copyWith(
              color: FGColors.textSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRespectSection() {
    return Row(
      children: [
        Icon(
          Icons.fitness_center,
          size: 16,
          color: FGColors.textSecondary,
        ),
        const SizedBox(width: Spacing.xs),
        Text(
          '${activity.respectCount} respect',
          style: FGTypography.bodySmall.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
        const Spacer(),
        RespectButton(
          count: activity.respectCount,
          hasGivenRespect: activity.hasGivenRespect,
          onTap: onRespect,
        ),
      ],
    );
  }
}
