import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/spacing.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
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

  // Mock history data
  final List<Map<String, dynamic>> _workoutHistory = [
    {
      'id': '1',
      'name': 'Push Day',
      'date': DateTime.now(),
      'duration': 68,
      'volume': 4200,
      'exercises': 6,
      'prs': 1,
    },
    {
      'id': '2',
      'name': 'Leg Day',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'duration': 75,
      'volume': 6800,
      'exercises': 5,
      'prs': 2,
    },
    {
      'id': '3',
      'name': 'Pull Day',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'duration': 62,
      'volume': 3600,
      'exercises': 6,
      'prs': 0,
    },
    {
      'id': '4',
      'name': 'Push Day',
      'date': DateTime.now().subtract(const Duration(days: 4)),
      'duration': 65,
      'volume': 4000,
      'exercises': 6,
      'prs': 0,
    },
    {
      'id': '5',
      'name': 'Leg Day',
      'date': DateTime.now().subtract(const Duration(days: 6)),
      'duration': 72,
      'volume': 6500,
      'exercises': 5,
      'prs': 1,
    },
    {
      'id': '6',
      'name': 'Pull Day',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'duration': 58,
      'volume': 3400,
      'exercises': 6,
      'prs': 0,
    },
    {
      'id': '7',
      'name': 'Push Day',
      'date': DateTime.now().subtract(const Duration(days: 8)),
      'duration': 70,
      'volume': 4100,
      'exercises': 6,
      'prs': 1,
    },
    {
      'id': '8',
      'name': 'Leg Day',
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'duration': 78,
      'volume': 6200,
      'exercises': 5,
      'prs': 0,
    },
  ];

  List<String> get _sessionTypes {
    return _workoutHistory
        .map((w) => w['name'] as String)
        .toSet()
        .toList()
      ..sort();
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_selectedFilter == null) return _workoutHistory;
    return _workoutHistory
        .where((w) => w['name'] == _selectedFilter)
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
                _buildFilters(),
                Expanded(
                  child: _buildHistoryList(),
                ),
              ],
            ),
          ),
        ],
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 64,
              color: FGColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Aucune séance',
              style: FGTypography.body.copyWith(
                color: FGColors.textSecondary,
              ),
            ),
          ],
        ),
      );
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
                  _getSessionIcon(workout['name'] as String),
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
                          workout['name'] as String,
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
    if (name.toLowerCase().contains('push')) {
      return Icons.fitness_center_rounded;
    } else if (name.toLowerCase().contains('pull')) {
      return Icons.rowing_rounded;
    } else if (name.toLowerCase().contains('leg')) {
      return Icons.directions_run_rounded;
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
                            workout['name'] as String,
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

              // Mock exercise list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  children: [
                    _buildExerciseItem('Développé couché', '4x8 @ 80kg'),
                    _buildExerciseItem('Développé incliné', '3x10 @ 60kg'),
                    _buildExerciseItem('Écartés poulie', '3x12 @ 15kg'),
                    _buildExerciseItem('Dips', '3x10 PDC'),
                    _buildExerciseItem('Extension triceps', '3x12 @ 25kg'),
                    _buildExerciseItem('Élévations latérales', '3x15 @ 10kg'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
