import 'package:flutter/material.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_neon_button.dart';

class GenerateAISheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onGenerate;

  const GenerateAISheet({super.key, required this.onGenerate});

  @override
  State<GenerateAISheet> createState() => GenerateAISheetState();
}

class GenerateAISheetState extends State<GenerateAISheet> {
  bool _adjustForTraining = true;
  int _mealsPerDay = 4;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [FGColors.accent, FGColors.accent.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: FGColors.textOnAccent,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Text('Générer ma semaine', style: FGTypography.h3),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'L\'IA va créer un plan nutritionnel personnalisé basé sur ton objectif et tes jours d\'entraînement.',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
          const SizedBox(height: Spacing.xl),

          // Adjust for training toggle
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: FGColors.glassSurface,
              borderRadius: BorderRadius.circular(Spacing.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ajuster selon l\'entraînement',
                        style: FGTypography.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Plus de glucides les jours de training',
                        style: FGTypography.caption.copyWith(color: FGColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _adjustForTraining,
                  onChanged: (v) => setState(() => _adjustForTraining = v),
                  activeTrackColor: FGColors.accent.withValues(alpha: 0.5),
                  activeThumbColor: FGColors.accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Meals per day
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: FGColors.glassSurface,
              borderRadius: BorderRadius.circular(Spacing.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repas par jour',
                  style: FGTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: Spacing.md),
                Row(
                  children: [3, 4, 5, 6].map((n) {
                    final isSelected = _mealsPerDay == n;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mealsPerDay = n),
                        child: Container(
                          margin: EdgeInsets.only(right: n < 6 ? Spacing.sm : 0),
                          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? FGColors.accent.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(Spacing.sm),
                            border: Border.all(
                              color: isSelected ? FGColors.accent : FGColors.glassBorder,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$n',
                              style: FGTypography.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? FGColors.accent : FGColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),

          FGNeonButton(
            label: 'Générer le plan',
            isExpanded: true,
            onPressed: () {
              widget.onGenerate({
                'adjustForTraining': _adjustForTraining,
                'mealsPerDay': _mealsPerDay,
              });
            },
          ),
          const SizedBox(height: Spacing.lg),
        ],
      ),
    );
  }
}
