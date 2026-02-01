import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../models/challenge.dart';
import '../models/friend.dart';

/// Multi-step bottom sheet for creating a challenge
class CreateChallengeSheet extends StatefulWidget {
  const CreateChallengeSheet({
    super.key,
    required this.friends,
    required this.onCreate,
  });

  final List<Friend> friends;
  final Function(Map<String, dynamic>) onCreate;

  @override
  State<CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<CreateChallengeSheet> {
  int _currentStep = 0;

  // Step 1: Type
  ChallengeType _selectedType = ChallengeType.weight;

  // Step 2: Configuration
  String _selectedExercise = 'Développé couché';
  double _targetValue = 100;
  DateTime? _deadline;

  // Step 3: Invitations
  final Set<String> _selectedFriendIds = {};

  final List<String> _exercises = [
    'Développé couché',
    'Squat',
    'Soulevé de terre',
    'Développé militaire',
    'Rowing barre',
    'Curl biceps',
    'Dips',
    'Tractions',
  ];

  void _nextStep() {
    HapticFeedback.selectionClick();
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      _createChallenge();
    }
  }

  void _previousStep() {
    HapticFeedback.selectionClick();
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _createChallenge() {
    HapticFeedback.mediumImpact();

    final challengeData = {
      'type': _selectedType,
      'exercise': _selectedExercise,
      'targetValue': _targetValue,
      'deadline': _deadline,
      'friendIds': _selectedFriendIds.toList(),
    };

    widget.onCreate(challengeData);
    Navigator.pop(context);
  }

  String get _typeDescription {
    switch (_selectedType) {
      case ChallengeType.weight:
        return 'Premier à atteindre le poids cible';
      case ChallengeType.reps:
        return 'Maximum de répétitions à un poids donné';
      case ChallengeType.time:
        return 'Meilleur temps pour X répétitions';
      case ChallengeType.custom:
        return 'Défi personnalisé avec description';
    }
  }

  String get _unit {
    switch (_selectedType) {
      case ChallengeType.weight:
        return 'kg';
      case ChallengeType.reps:
        return 'reps';
      case ChallengeType.time:
        return 'sec';
      case ChallengeType.custom:
        return '';
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _previousStep,
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: FGColors.glassSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _currentStep == 0 ? Icons.close : Icons.arrow_back,
                      color: FGColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    _getStepTitle(),
                    style: FGTypography.h3,
                  ),
                ),
                // Step indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(4, (index) {
                    return Container(
                      width: index == _currentStep ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? FGColors.accent
                            : FGColors.glassBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: _buildStepContent(),
            ),
          ),

          // Action Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: GestureDetector(
                onTap: _canProceed() ? _nextStep : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  decoration: BoxDecoration(
                    gradient: _canProceed()
                        ? LinearGradient(
                            colors: [
                              FGColors.accent,
                              FGColors.accent.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: !_canProceed() ? FGColors.glassSurface : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _canProceed()
                        ? [
                            BoxShadow(
                              color: FGColors.accent.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _currentStep < 3 ? 'CONTINUER' : 'LANCER LE DÉFI',
                      style: FGTypography.button.copyWith(
                        color: _canProceed()
                            ? FGColors.textOnAccent
                            : FGColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Type de défi';
      case 1:
        return 'Configuration';
      case 2:
        return 'Inviter des amis';
      case 3:
        return 'Confirmation';
      default:
        return '';
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return true;
      case 1:
        return _targetValue > 0;
      case 2:
        return _selectedFriendIds.isNotEmpty;
      case 3:
        return true;
      default:
        return false;
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildTypeStep();
      case 1:
        return _buildConfigStep();
      case 2:
        return _buildInviteStep();
      case 3:
        return _buildConfirmStep();
      default:
        return const SizedBox();
    }
  }

  // ================ STEP 1: TYPE ================
  Widget _buildTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quel type de défi veux-tu lancer ?',
          style: FGTypography.body.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        ...ChallengeType.values.map((type) => _buildTypeOption(type)),
      ],
    );
  }

  Widget _buildTypeOption(ChallengeType type) {
    final isSelected = _selectedType == type;
    final icon = switch (type) {
      ChallengeType.weight => Icons.fitness_center,
      ChallengeType.reps => Icons.repeat,
      ChallengeType.time => Icons.timer,
      ChallengeType.custom => Icons.edit_note,
    };
    final title = switch (type) {
      ChallengeType.weight => 'Défi poids',
      ChallengeType.reps => 'Défi reps',
      ChallengeType.time => 'Défi temps',
      ChallengeType.custom => 'Défi libre',
    };
    final description = switch (type) {
      ChallengeType.weight => 'Premier à atteindre X kg',
      ChallengeType.reps => 'Max reps à X kg',
      ChallengeType.time => 'Meilleur temps pour X reps',
      ChallengeType.custom => 'Description personnalisée',
    };

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? FGColors.accent.withValues(alpha: 0.1)
              : FGColors.glassSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? FGColors.accent : FGColors.glassBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? FGColors.accent.withValues(alpha: 0.2)
                    : FGColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? FGColors.accent : FGColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? FGColors.textPrimary
                          : FGColors.textSecondary,
                    ),
                  ),
                  Text(
                    description,
                    style: FGTypography.caption.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: FGColors.accent,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // ================ STEP 2: CONFIG ================
  Widget _buildConfigStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise picker
        Text(
          'EXERCICE',
          style: FGTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          decoration: BoxDecoration(
            color: FGColors.glassSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: FGColors.glassBorder,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedExercise,
              isExpanded: true,
              dropdownColor: FGColors.background,
              style: FGTypography.body,
              icon: const Icon(Icons.keyboard_arrow_down, color: FGColors.textSecondary),
              items: _exercises.map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedExercise = value;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // Target value
        Text(
          'OBJECTIF',
          style: FGTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            // Decrement
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _targetValue = (_targetValue - 5).clamp(0, 500);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: FGColors.glassSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: FGColors.glassBorder,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.remove,
                  color: FGColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            // Value display
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                decoration: BoxDecoration(
                  color: FGColors.glassSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: FGColors.accent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${_targetValue.toInt()} $_unit',
                    style: FGTypography.h2.copyWith(
                      color: FGColors.accent,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            // Increment
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _targetValue = (_targetValue + 5).clamp(0, 500);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: FGColors.glassSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: FGColors.glassBorder,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  color: FGColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),

        // Deadline (optional)
        Text(
          'DATE LIMITE (OPTIONNEL)',
          style: FGTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: FGColors.accent,
                      surface: FGColors.background,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                _deadline = date;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: FGColors.glassSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: FGColors.glassBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: FGColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: Spacing.md),
                Text(
                  _deadline != null
                      ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                      : 'Aucune limite',
                  style: FGTypography.body.copyWith(
                    color: _deadline != null
                        ? FGColors.textPrimary
                        : FGColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (_deadline != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _deadline = null;
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      color: FGColors.textSecondary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.xl),
      ],
    );
  }

  // ================ STEP 3: INVITE ================
  Widget _buildInviteStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélectionne les amis à défier',
          style: FGTypography.body.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        ...widget.friends.map((friend) {
          final isSelected = _selectedFriendIds.contains(friend.id);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isSelected) {
                  _selectedFriendIds.remove(friend.id);
                } else {
                  _selectedFriendIds.add(friend.id);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: Spacing.sm),
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? FGColors.accent.withValues(alpha: 0.1)
                    : FGColors.glassSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? FGColors.accent : FGColors.glassBorder,
                  width: 1,
                ),
              ),
              child: Row(
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
                      ),
                    ),
                    child: Center(
                      child: Text(
                        friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                        style: FGTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: FGColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      friend.name,
                      style: FGTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? FGColors.accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? FGColors.accent : FGColors.glassBorder,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: FGColors.textOnAccent,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: Spacing.xl),
      ],
    );
  }

  // ================ STEP 4: CONFIRM ================
  Widget _buildConfirmStep() {
    final selectedFriends = widget.friends
        .where((f) => _selectedFriendIds.contains(f.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview card
        Container(
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                FGColors.accent.withValues(alpha: 0.15),
                FGColors.accent.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: FGColors.accent.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bolt,
                    color: FGColors.accent,
                    size: 24,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'NOUVEAU DÉFI',
                    style: FGTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: FGColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Text(
                '"${_targetValue.toInt()}$_unit au $_selectedExercise"',
                style: FGTypography.h3,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                _typeDescription,
                style: FGTypography.bodySmall.copyWith(
                  color: FGColors.textSecondary,
                ),
              ),
              const SizedBox(height: Spacing.md),
              const Divider(color: FGColors.glassBorder),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  const Icon(
                    Icons.people,
                    color: FGColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    '${selectedFriends.length} participant${selectedFriends.length > 1 ? 's' : ''} invité${selectedFriends.length > 1 ? 's' : ''}',
                    style: FGTypography.bodySmall.copyWith(
                      color: FGColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (_deadline != null) ...[
                const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: FGColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      'Limite: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                      style: FGTypography.bodySmall.copyWith(
                        color: FGColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // Participants
        Text(
          'PARTICIPANTS',
          style: FGTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: selectedFriends.map((friend) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: FGColors.glassSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: FGColors.glassBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FGColors.accent,
                    ),
                    child: Center(
                      child: Text(
                        friend.name[0].toUpperCase(),
                        style: FGTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: FGColors.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    friend.name,
                    style: FGTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: Spacing.xxl),
      ],
    );
  }
}
