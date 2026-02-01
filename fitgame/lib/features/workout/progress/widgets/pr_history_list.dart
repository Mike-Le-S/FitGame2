import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../models/exercise_history.dart';

/// Widget affichant la liste des records personnels
class PRHistoryList extends StatelessWidget {
  final List<ExerciseProgressEntry> prEntries;

  const PRHistoryList({
    super.key,
    required this.prEntries,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return "Aujourd'hui";
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jours';
    } else {
      final weeks = (diff.inDays / 7).round();
      return 'S${7 - weeks + 1}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trier par date décroissante (plus récent en premier)
    final sortedEntries = List<ExerciseProgressEntry>.from(prEntries)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HISTORIQUE DES PR',
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: Spacing.md),
        ...sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final pr = entry.value;
          final isFirst = index == 0;

          return _PRHistoryItem(
            entry: pr,
            dateLabel: _formatDate(pr.date),
            isLatest: isFirst,
          );
        }),
      ],
    );
  }
}

class _PRHistoryItem extends StatelessWidget {
  final ExerciseProgressEntry entry;
  final String dateLabel;
  final bool isLatest;

  const _PRHistoryItem({
    required this.entry,
    required this.dateLabel,
    this.isLatest = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: isLatest
              ? const Color(0xFFFFD700).withValues(alpha: 0.1)
              : FGColors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLatest
                ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                : FGColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            // Trophy icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isLatest
                    ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                    : FGColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.emoji_events,
                color: isLatest ? const Color(0xFFFFD700) : FGColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: Spacing.md),
            // Weight and reps
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${entry.weight.toStringAsFixed(entry.weight % 1 == 0 ? 0 : 1)}kg',
                        style: FGTypography.h3.copyWith(
                          color: isLatest
                              ? const Color(0xFFFFD700)
                              : FGColors.textPrimary,
                        ),
                      ),
                      Text(
                        ' × ${entry.reps}',
                        style: FGTypography.body.copyWith(
                          color: FGColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.sessionName ?? 'Séance',
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Date
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: FGColors.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dateLabel,
                style: FGTypography.caption.copyWith(
                  color: isLatest
                      ? const Color(0xFFFFD700)
                      : FGColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
