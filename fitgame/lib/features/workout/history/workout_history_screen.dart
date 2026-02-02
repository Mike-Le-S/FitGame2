import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/spacing.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/fg_glass_card.dart';

/// Écran d'historique des séances d'entraînement
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({
    super.key,
    this.initialFilter,
  });

  /// Filtre initial (nom de session) pour afficher une session spécifique
  final String? initialFilter;

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String? _selectedFilter;
  bool _isLoading = true;

  // Workout history from Supabase
  List<Map<String, dynamic>> _workoutHistory = [];

  List<String> get _sessionTypes {
    return _workoutHistory
        .map((w) => w['day_name'] as String? ?? 'Séance')
        .toSet()
        .toList()
      ..sort();
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_selectedFilter == null) return _workoutHistory;
    return _workoutHistory
        .where((w) => w['day_name'] == _selectedFilter)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;

    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.05, end: 0.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final sessions = await SupabaseService.getWorkoutSessions(limit: 50);
      if (mounted) {
        setState(() {
          _workoutHistory = sessions
              .where((s) => s['completed_at'] != null)
              .map((s) {
                final exercises = s['exercises'] as List? ?? [];
                final prs = s['personal_records'] as List? ?? [];
                return {
                  'id': s['id'],
                  'day_name': s['day_name'] ?? 'Séance',
                  'date': DateTime.tryParse(s['completed_at'] ?? '') ?? DateTime.now(),
                  'duration': s['duration_minutes'] ?? 0,
                  'volume': ((s['total_volume_kg'] as num?) ?? 0).toInt(),
                  'exercises': exercises.length,
                  'prs': prs.length,
                  'exercises_data': exercises,
                };
              })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
                if (!_isLoading && _workoutHistory.isNotEmpty) _buildFilters(),
                Expanded(
                  child: _isLoading ? _buildLoading() : _buildHistoryList(),
                ),
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
              top: -80,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
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
              Navigator.of(context).pop();
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
                Icons.arrow_back_rounded,
                color: FGColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historique',
                  style: FGTypography.h2,
                ),
                Text(
                  '${_filteredHistory.length} séances',
                  style: FGTypography.caption.copyWith(
                    color: FGColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Stats summary
          if (_filteredHistory.isNotEmpty)
            _buildStatBadge(
              icon: Icons.local_fire_department_rounded,
              value: '${_calculateTotalVolume()}',
              label: 'kg total',
            ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: FGColors.glassSurface,
        borderRadius: BorderRadius.circular(Spacing.md),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: FGColors.accent, size: 16),
          const SizedBox(width: Spacing.xs),
          Text(
            value,
            style: FGTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: FGColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateTotalVolume() {
    return _filteredHistory.fold<int>(
      0,
      (sum, w) => sum + (w['volume'] as int),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        children: [
          _buildFilterChip(null, 'Tout'),
          ..._sessionTypes.map((type) => _buildFilterChip(type, type)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? filter, String label) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: Spacing.sm),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilter = filter);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? FGColors.accent
                : FGColors.glassSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(Spacing.lg),
            border: Border.all(
              color: isSelected ? FGColors.accent : FGColors.glassBorder,
            ),
          ),
          child: Text(
            label,
            style: FGTypography.caption.copyWith(
              color: isSelected ? FGColors.textOnAccent : FGColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final history = _filteredHistory;

    if (history.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final workout = history[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: _buildWorkoutCard(workout),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: FGColors.glassBorder,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 40,
              color: FGColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Aucune séance',
            style: FGTypography.h3.copyWith(
              color: FGColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Tes séances terminées\napparaîtront ici',
            textAlign: TextAlign.center,
            style: FGTypography.body.copyWith(
              color: FGColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    final date = workout['date'] as DateTime;
    final isToday = _isToday(date);
    final isYesterday = _isYesterday(date);
    final prs = workout['prs'] as int;

    return FGGlassCard(
      onTap: () {
        HapticFeedback.lightImpact();
        _showWorkoutDetail(workout);
      },
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Session icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isToday
                      ? FGColors.success.withValues(alpha: 0.2)
                      : FGColors.glassBorder,
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: Icon(
                  _getSessionIcon(workout['day_name'] as String),
                  color: isToday ? FGColors.success : FGColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: Spacing.md),

              // Title & date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          workout['day_name'] as String,
                          style: FGTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (prs > 0) ...[
                          const SizedBox(width: Spacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  FGColors.accent,
                                  FGColors.accent.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(Spacing.xs),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.emoji_events_rounded,
                                  color: FGColors.textOnAccent,
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '$prs PR',
                                  style: FGTypography.caption.copyWith(
                                    fontSize: 9,
                                    color: FGColors.textOnAccent,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      isToday
                          ? 'Aujourd\'hui'
                          : isYesterday
                              ? 'Hier'
                              : _formatDate(date),
                      style: FGTypography.caption.copyWith(
                        color: isToday ? FGColors.success : FGColors.textSecondary,
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: FGColors.textSecondary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Stats row
          Row(
            children: [
              _buildStatItem(
                icon: Icons.timer_outlined,
                value: '${workout['duration']}',
                unit: 'min',
              ),
              const SizedBox(width: Spacing.lg),
              _buildStatItem(
                icon: Icons.fitness_center_rounded,
                value: '${workout['exercises']}',
                unit: 'exos',
              ),
              const SizedBox(width: Spacing.lg),
              _buildStatItem(
                icon: Icons.monitor_weight_outlined,
                value: _formatVolume(workout['volume'] as int),
                unit: 'kg',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String unit,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: FGColors.textSecondary,
          size: 14,
        ),
        const SizedBox(width: Spacing.xs),
        Text(
          value,
          style: FGTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: FGColors.textPrimary,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          unit,
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  IconData _getSessionIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('push') || lower.contains('pec') || lower.contains('chest')) {
      return Icons.fitness_center_rounded;
    } else if (lower.contains('pull') || lower.contains('dos') || lower.contains('back')) {
      return Icons.rowing_rounded;
    } else if (lower.contains('leg') || lower.contains('jambe')) {
      return Icons.directions_run_rounded;
    } else if (lower.contains('upper') || lower.contains('haut')) {
      return Icons.accessibility_new_rounded;
    }
    return Icons.fitness_center_rounded;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }

  String _formatVolume(int volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k';
    }
    return volume.toString();
  }

  void _showWorkoutDetail(Map<String, dynamic> workout) {
    final exercises = workout['exercises_data'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: FGColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: FGColors.glassBorder),
          ),
          child: Column(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout['day_name'] as String,
                            style: FGTypography.h2,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            _formatDate(workout['date'] as DateTime),
                            style: FGTypography.bodySmall.copyWith(
                              color: FGColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: FGColors.glassBorder,
                          borderRadius: BorderRadius.circular(Spacing.sm),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: FGColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Row(
                  children: [
                    _buildDetailStat('${workout['duration']}', 'minutes'),
                    const SizedBox(width: Spacing.md),
                    _buildDetailStat('${workout['exercises']}', 'exercices'),
                    const SizedBox(width: Spacing.md),
                    _buildDetailStat('${workout['volume']}', 'kg volume'),
                    if ((workout['prs'] as int) > 0) ...[
                      const SizedBox(width: Spacing.md),
                      _buildDetailStat('${workout['prs']}', 'PR', isHighlight: true),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // Exercise list from real data
              Expanded(
                child: exercises.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun détail disponible',
                          style: FGTypography.body.copyWith(
                            color: FGColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final ex = exercises[index] as Map<String, dynamic>;
                          final sets = ex['sets'] as List? ?? [];
                          final bestSet = _getBestSet(sets);
                          return _buildExerciseItem(
                            ex['exerciseName'] ?? ex['name'] ?? 'Exercice',
                            bestSet,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBestSet(List sets) {
    if (sets.isEmpty) return '-';

    double maxWeight = 0;
    int completedSets = 0;

    for (final set in sets) {
      final s = set as Map<String, dynamic>;
      if (s['completed'] == true) {
        completedSets++;
        final weight = (s['weightKg'] as num?)?.toDouble() ?? 0;
        if (weight > maxWeight) {
          maxWeight = weight;
        }
      }
    }

    if (completedSets == 0) return '-';
    if (maxWeight == 0) return '${completedSets}x PDC';
    return '${completedSets}x @ ${maxWeight.toStringAsFixed(0)}kg';
  }

  Widget _buildDetailStat(String value, String label, {bool isHighlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: isHighlight
              ? FGColors.accent.withValues(alpha: 0.15)
              : FGColors.glassSurface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(
            color: isHighlight
                ? FGColors.accent.withValues(alpha: 0.3)
                : FGColors.glassBorder,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: FGTypography.h3.copyWith(
                color: isHighlight ? FGColors.accent : FGColors.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              label,
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem(String name, String sets) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: FGColors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Spacing.md),
          border: Border.all(color: FGColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: FGColors.glassBorder,
                borderRadius: BorderRadius.circular(Spacing.sm),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: FGColors.textSecondary,
                size: 16,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                name,
                style: FGTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              sets,
              style: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
