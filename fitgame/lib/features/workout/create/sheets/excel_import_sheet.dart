import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/fg_colors.dart';
import '../../../../core/theme/fg_typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/services/excel_import_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/fg_glass_card.dart';
import '../../../../shared/widgets/fg_neon_button.dart';

class ExcelImportSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const ExcelImportSheet({super.key, required this.onSuccess});

  @override
  State<ExcelImportSheet> createState() => _ExcelImportSheetState();
}

class _ExcelImportSheetState extends State<ExcelImportSheet> {
  Map<String, dynamic>? _parsedProgram;
  bool _isParsing = false;
  bool _isImporting = false;
  String? _error;
  String? _fileName;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null && file.path == null) return;

      setState(() {
        _isParsing = true;
        _error = null;
        _fileName = file.name;
      });

      final program = ExcelImportService.parseExcelFile(
        file.path ?? '',
        fileBytes: file.bytes,
      );

      setState(() {
        _parsedProgram = program;
        _isParsing = false;
      });
    } catch (e, stack) {
      debugPrint('ExcelImport SHEET ERROR: $e');
      debugPrint('ExcelImport SHEET STACK: $stack');
      setState(() {
        _error = 'Erreur de parsing: $e';
        _isParsing = false;
      });
    }
  }

  Future<void> _importProgram() async {
    if (_parsedProgram == null || _isImporting) return;

    setState(() => _isImporting = true);
    HapticFeedback.heavyImpact();

    try {
      final days = _parsedProgram!['days'] as List;
      await SupabaseService.createProgram(
        name: _parsedProgram!['name'] ?? 'Programme importé',
        goal: 'bulk',
        durationWeeks: 8,
        days: days.map((d) => d as Map<String, dynamic>).toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur d\'import: $e';
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: FGColors.glassBorder),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: Spacing.md),
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
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Importer depuis Excel', style: FGTypography.h3),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Sélectionne un fichier .xlsx avec ton programme',
                  style: FGTypography.bodySmall
                      .copyWith(color: FGColors.textSecondary),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File picker
                  GestureDetector(
                    onTap: _isParsing ? null : _pickFile,
                    child: FGGlassCard(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: Column(
                        children: [
                          Icon(
                            _fileName != null
                                ? Icons.description
                                : Icons.upload_file,
                            size: 48,
                            color: _fileName != null
                                ? FGColors.success
                                : FGColors.accent,
                          ),
                          const SizedBox(height: Spacing.md),
                          Text(
                            _fileName ?? 'Choisir un fichier .xlsx',
                            style: FGTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _fileName != null
                                  ? FGColors.textPrimary
                                  : FGColors.accent,
                            ),
                          ),
                          if (_isParsing) ...[
                            const SizedBox(height: Spacing.md),
                            const CircularProgressIndicator(
                              color: FGColors.accent,
                              strokeWidth: 2,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: Spacing.md),
                    Container(
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: FGColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Spacing.sm),
                        border: Border.all(
                            color: FGColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _error!,
                        style: FGTypography.bodySmall
                            .copyWith(color: FGColors.error),
                      ),
                    ),
                  ],

                  // Preview
                  if (_parsedProgram != null) ...[
                    const SizedBox(height: Spacing.xl),
                    Text(
                      'APERÇU',
                      style: FGTypography.caption.copyWith(
                        color: FGColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    ...(_parsedProgram!['days'] as List).map((day) {
                      final d = day as Map<String, dynamic>;
                      final exercises = d['exercises'] as List? ?? [];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: FGGlassCard(
                          padding: const EdgeInsets.all(Spacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d['name'] as String? ?? 'Séance',
                                style: FGTypography.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${exercises.length} exercice${exercises.length > 1 ? 's' : ''}',
                                style: FGTypography.caption.copyWith(
                                  color: FGColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: Spacing.sm),
                              ...exercises.take(5).map((ex) {
                                final e = ex as Map<String, dynamic>;
                                final customSets = e['customSets'] as List?;
                                String detail = '';
                                if (customSets != null &&
                                    customSets.isNotEmpty) {
                                  final weights = customSets
                                      .map((s) =>
                                          (s['weight'] as num?)
                                              ?.toDouble() ??
                                          0)
                                      .where((w) => w > 0);
                                  if (weights.isNotEmpty) {
                                    detail =
                                        '${customSets.length}× ${weights.reduce((a, b) => a < b ? a : b).toInt()}→${weights.reduce((a, b) => a > b ? a : b).toInt()}kg';
                                  } else {
                                    detail = '${customSets.length} séries';
                                  }
                                } else {
                                  detail =
                                      '${e['sets'] ?? 3}×${e['reps'] ?? 10}';
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.fiber_manual_record,
                                          size: 5,
                                          color: FGColors.textSecondary),
                                      const SizedBox(width: Spacing.sm),
                                      Expanded(
                                        child: Text(
                                          e['name'] as String? ?? '',
                                          style: FGTypography.caption.copyWith(
                                              color: FGColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        detail,
                                        style: FGTypography.caption.copyWith(
                                          color: FGColors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              if (exercises.length > 5)
                                Text(
                                  '+${exercises.length - 5} exercices',
                                  style: FGTypography.caption.copyWith(
                                    color: FGColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: Spacing.xl),
                ],
              ),
            ),
          ),
          // Import button
          if (_parsedProgram != null)
            Container(
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    FGColors.background.withValues(alpha: 0),
                    FGColors.background,
                  ],
                ),
              ),
              child: FGNeonButton(
                label: _isImporting
                    ? 'Import en cours...'
                    : 'Importer le programme',
                isExpanded: true,
                onPressed: _isImporting ? null : _importProgram,
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showExcelImportSheet(
  BuildContext context, {
  required VoidCallback onSuccess,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ExcelImportSheet(onSuccess: onSuccess),
  );
}
