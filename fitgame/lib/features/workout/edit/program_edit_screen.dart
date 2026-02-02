import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/spacing.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/fg_glass_card.dart';

/// Écran d'édition d'un programme d'entraînement
class ProgramEditScreen extends StatefulWidget {
  const ProgramEditScreen({
    super.key,
    required this.programId,
  });

  final String programId;

  @override
  State<ProgramEditScreen> createState() => _ProgramEditScreenState();
}

class _ProgramEditScreenState extends State<ProgramEditScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late TextEditingController _nameController;

  bool _hasChanges = false;
  bool _isLoading = true;
  bool _isSaving = false;

  // Program data from Supabase
  Map<String, dynamic>? _program;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameController.addListener(() {
      setState(() => _hasChanges = true);
    });

    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.05, end: 0.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadProgram();
  }

  Future<void> _loadProgram() async {
    try {
      final program = await SupabaseService.getProgram(widget.programId);
      if (program != null && mounted) {
        final days = program['days'] as List? ?? [];
        setState(() {
          _program = program;
          _nameController.text = program['name'] ?? '';
          _sessions = days.map((d) {
            final day = d as Map<String, dynamic>;
            final exercises = day['exercises'] as List? ?? [];
            return {
              'name': day['name'] ?? 'Séance',
              'muscles': _extractMuscles(exercises),
              'exercises': exercises.map((e) {
                final ex = e as Map<String, dynamic>;
                return {
                  'name': ex['name'] ?? '',
                  'sets': '${ex['sets'] ?? 3}x${ex['reps'] ?? 10}',
                };
              }).toList(),
            };
          }).toList();
          _isLoading = false;
          _hasChanges = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _extractMuscles(List exercises) {
    final muscles = <String>{};
    for (final ex in exercises) {
      final muscle = ex['muscleGroup'] ?? ex['muscle_group'];
      if (muscle != null) muscles.add(muscle.toString());
    }
    return muscles.take(3).join(', ');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: Stack(
        children: [
          _buildMeshGradient(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading ? _buildLoading() : _buildContent(),
                ),
                if (!_isLoading) _buildSaveButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: FGColors.accent,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildMeshGradient() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Container(color: FGColors.background),
            Positioned(
              bottom: 200,
              left: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      FGColors.accent.withValues(alpha: _pulseAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (_hasChanges) {
                _showDiscardDialog();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: FGColors.glassSurface,
                borderRadius: BorderRadius.circular(Spacing.sm),
                border: Border.all(color: FGColors.glassBorder),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: FGColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              'Modifier programme',
              style: FGTypography.h3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_program == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program name
          _buildSectionTitle('NOM DU PROGRAMME'),
          const SizedBox(height: Spacing.sm),
          _buildNameField(),
          const SizedBox(height: Spacing.xl),

          // Sessions
          _buildSectionTitle('SÉANCES'),
          const SizedBox(height: Spacing.md),
          if (_sessions.isEmpty)
            _buildNoSessionsState()
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _sessions.length,
              onReorder: (oldIndex, newIndex) {
                HapticFeedback.mediumImpact();
                setState(() {
                  _hasChanges = true;
                  if (newIndex > oldIndex) newIndex--;
                  final item = _sessions.removeAt(oldIndex);
                  _sessions.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  key: ValueKey('session_$index'),
                  padding: const EdgeInsets.only(bottom: Spacing.md),
                  child: _buildSessionCard(index),
                );
              },
            ),

          // Add session button
          _buildAddSessionButton(),
          const SizedBox(height: Spacing.xxl),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: FGColors.textSecondary,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Programme introuvable',
            style: FGTypography.body.copyWith(color: FGColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSessionsState() {
    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 32,
              color: FGColors.textSecondary,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Aucune séance',
              style: FGTypography.body.copyWith(color: FGColors.textSecondary),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Ajoute ta première séance',
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: FGTypography.caption.copyWith(
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
        color: FGColors.textSecondary,
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: TextField(
        controller: _nameController,
        style: FGTypography.h3,
        decoration: InputDecoration(
          hintText: 'Nom du programme',
          hintStyle: FGTypography.h3.copyWith(
            color: FGColors.textSecondary.withValues(alpha: 0.5),
          ),
          contentPadding: const EdgeInsets.all(Spacing.lg),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSessionCard(int index) {
    final session = _sessions[index];
    final exercises = session['exercises'] as List;

    return FGGlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header with drag handle
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FGColors.accent.withValues(alpha: 0.08),
                  FGColors.accent.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.sm),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: FGColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session['name'] as String,
                        style: FGTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (session['muscles'] as String).isEmpty
                            ? 'Aucun exercice'
                            : session['muscles'] as String,
                        style: FGTypography.caption.copyWith(
                          color: FGColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _editSession(index),
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: FGColors.glassBorder,
                      borderRadius: BorderRadius.circular(Spacing.sm),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: FGColors.textSecondary,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                GestureDetector(
                  onTap: () => _deleteSession(index),
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.sm),
                    decoration: BoxDecoration(
                      color: FGColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Spacing.sm),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: FGColors.error,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Exercises preview
          if (exercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                children: [
                  ...exercises.take(3).map((ex) => Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.xs),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fiber_manual_record,
                              size: 6,
                              color: FGColors.textSecondary,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                ex['name'] as String,
                                style: FGTypography.caption.copyWith(
                                  color: FGColors.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              ex['sets'] as String,
                              style: FGTypography.caption.copyWith(
                                color: FGColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (exercises.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.xs),
                      child: Text(
                        '+${exercises.length - 3} exercices',
                        style: FGTypography.caption.copyWith(
                          color: FGColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Text(
                'Aucun exercice',
                style: FGTypography.caption.copyWith(
                  color: FGColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddSessionButton() {
    return GestureDetector(
      onTap: _addSession,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          border: Border.all(
            color: FGColors.glassBorder,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(Spacing.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: FGColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              'Ajouter une séance',
              style: FGTypography.body.copyWith(
                color: FGColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: GestureDetector(
        onTap: (_hasChanges && !_isSaving) ? _saveProgram : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
          decoration: BoxDecoration(
            gradient: _hasChanges
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      FGColors.accent,
                      FGColors.accent.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: _hasChanges ? null : FGColors.glassBorder,
            borderRadius: BorderRadius.circular(Spacing.md),
            boxShadow: _hasChanges
                ? [
                    BoxShadow(
                      color: FGColors.accent.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: FGColors.textOnAccent,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Sauvegarder',
                    style: FGTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _hasChanges
                          ? FGColors.textOnAccent
                          : FGColors.textSecondary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _editSession(int index) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Édition de ${_sessions[index]['name']}'),
        backgroundColor: FGColors.glassSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _deleteSession(int index) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FGColors.glassSurface,
        title: Text(
          'Supprimer ${_sessions[index]['name']} ?',
          style: FGTypography.h3,
        ),
        content: Text(
          'Cette action est irréversible.',
          style: FGTypography.body.copyWith(color: FGColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: FGTypography.body.copyWith(color: FGColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _sessions.removeAt(index);
                _hasChanges = true;
              });
              Navigator.pop(context);
            },
            child: Text(
              'Supprimer',
              style: FGTypography.body.copyWith(color: FGColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _addSession() {
    HapticFeedback.lightImpact();
    setState(() {
      _sessions.add({
        'name': 'Nouvelle séance',
        'muscles': '',
        'exercises': <Map<String, String>>[],
      });
      _hasChanges = true;
    });
  }

  Future<void> _saveProgram() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    try {
      // Convert sessions back to days format
      final days = _sessions.map((session) {
        return {
          'name': session['name'],
          'exercises': (session['exercises'] as List).map((ex) {
            final parts = (ex['sets'] as String).split('x');
            return {
              'name': ex['name'],
              'sets': int.tryParse(parts[0]) ?? 3,
              'reps': int.tryParse(parts.length > 1 ? parts[1] : '10') ?? 10,
            };
          }).toList(),
        };
      }).toList();

      await SupabaseService.updateProgram(widget.programId, {
        'name': _nameController.text,
        'days': days,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate changes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Programme sauvegardé'),
            backgroundColor: FGColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: FGColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FGColors.glassSurface,
        title: Text(
          'Abandonner les modifications ?',
          style: FGTypography.h3,
        ),
        content: Text(
          'Les modifications non sauvegardées seront perdues.',
          style: FGTypography.body.copyWith(color: FGColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continuer l\'édition',
              style: FGTypography.body.copyWith(color: FGColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close screen
            },
            child: Text(
              'Abandonner',
              style: FGTypography.body.copyWith(color: FGColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
