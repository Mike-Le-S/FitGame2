import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/fg_neon_button.dart';

/// Sheet for scanning nutrition labels using OCR
class NutritionScannerSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onFoodScanned;

  const NutritionScannerSheet({
    super.key,
    required this.onFoodScanned,
  });

  @override
  State<NutritionScannerSheet> createState() => _NutritionScannerSheetState();
}

class _NutritionScannerSheetState extends State<NutritionScannerSheet> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  bool _isProcessing = false;
  String? _errorMessage;
  File? _imageFile;

  // Parsed nutrition values
  int _calories = 0;
  int _protein = 0;
  int _carbs = 0;
  int _fat = 0;
  String _servingSize = '100g';

  // Controllers for manual editing
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _servingController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _servingController = TextEditingController(text: '100g');
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _servingController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _isProcessing = true;
          _errorMessage = null;
        });
        await _processImage(photo.path);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur caméra: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _isProcessing = true;
          _errorMessage = null;
        });
        await _processImage(image.path);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur galerie: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      _parseNutritionLabel(recognizedText.text);

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur OCR: $e';
        _isProcessing = false;
      });
    }
  }

  void _parseNutritionLabel(String text) {
    // Normalize text: lowercase
    final normalizedText = text.toLowerCase();

    // Parse calories
    _calories = _extractNumber(normalizedText, [
      r'calories?\s*[:\-]?\s*(\d+)',
      r'(\d+)\s*kcal',
      r'energie\s*[:\-]?\s*(\d+)',
      r'valeur\s*energetique\s*[:\-]?\s*(\d+)',
      r'energy\s*[:\-]?\s*(\d+)',
    ]);

    // Parse protein
    _protein = _extractNumber(normalizedText, [
      r'proteines?\s*[:\-]?\s*(\d+)',
      r'protein\s*[:\-]?\s*(\d+)',
      r'prot\.?\s*[:\-]?\s*(\d+)',
    ]);

    // Parse carbs
    _carbs = _extractNumber(normalizedText, [
      r'glucides?\s*[:\-]?\s*(\d+)',
      r'carbohydrates?\s*[:\-]?\s*(\d+)',
      r'carbs?\s*[:\-]?\s*(\d+)',
      r'dont\s*sucres?\s*[:\-]?\s*(\d+)', // Also capture sugars as fallback
    ]);

    // Parse fat
    _fat = _extractNumber(normalizedText, [
      r'lipides?\s*[:\-]?\s*(\d+)',
      r'matieres?\s*grasses?\s*[:\-]?\s*(\d+)',
      r'fat\s*[:\-]?\s*(\d+)',
      r'graisses?\s*[:\-]?\s*(\d+)',
    ]);

    // Try to extract serving size
    final servingMatch = RegExp(r'pour\s*(\d+\s*g)', caseSensitive: false)
        .firstMatch(normalizedText);
    if (servingMatch != null) {
      _servingSize = servingMatch.group(1) ?? '100g';
    }

    // Update controllers
    _caloriesController.text = _calories.toString();
    _proteinController.text = _protein.toString();
    _carbsController.text = _carbs.toString();
    _fatController.text = _fat.toString();
    _servingController.text = _servingSize;

    // Log for debugging
    debugPrint('OCR Text: $text');
    debugPrint(
        'Parsed: Cal=$_calories, P=$_protein, C=$_carbs, F=$_fat, Serving=$_servingSize');
  }

  int _extractNumber(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final value = int.tryParse(match.group(1) ?? '0');
        if (value != null && value > 0) {
          return value;
        }
      }
    }
    return 0;
  }

  void _submitFood() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un nom pour l\'aliment';
      });
      return;
    }

    final food = {
      'name': name,
      'quantity': _servingController.text,
      'cal': int.tryParse(_caloriesController.text) ?? 0,
      'p': int.tryParse(_proteinController.text) ?? 0,
      'c': int.tryParse(_carbsController.text) ?? 0,
      'f': int.tryParse(_fatController.text) ?? 0,
      'category': 'Scanné',
    };

    widget.onFoodScanned(food);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: FGColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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

            // Title
            Row(
              children: [
                const Icon(
                  Icons.document_scanner_rounded,
                  color: FGColors.accent,
                  size: 24,
                ),
                const SizedBox(width: Spacing.sm),
                Text('Scanner une étiquette', style: FGTypography.h3),
              ],
            ),
            const SizedBox(height: Spacing.md),

            // Instructions
            Text(
              'Prenez en photo l\'étiquette nutritionnelle d\'un produit. L\'app détectera automatiquement les valeurs.',
              style: FGTypography.bodySmall.copyWith(
                color: FGColors.textSecondary,
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // Camera/Gallery buttons or image preview
            if (_imageFile == null) ...[
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: FGColors.glassSurface,
                          borderRadius: BorderRadius.circular(Spacing.md),
                          border: Border.all(color: FGColors.glassBorder),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              color: FGColors.accent,
                              size: 36,
                            ),
                            const SizedBox(height: Spacing.sm),
                            Text(
                              'Prendre une photo',
                              style: FGTypography.caption.copyWith(
                                color: FGColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickFromGallery,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: FGColors.glassSurface,
                          borderRadius: BorderRadius.circular(Spacing.md),
                          border: Border.all(color: FGColors.glassBorder),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_rounded,
                              color: FGColors.textSecondary,
                              size: 36,
                            ),
                            const SizedBox(height: Spacing.sm),
                            Text(
                              'Galerie',
                              style: FGTypography.caption.copyWith(
                                color: FGColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Image preview
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Spacing.md),
                    child: Image.file(
                      _imageFile!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: Spacing.sm,
                    right: Spacing.sm,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _imageFile = null;
                          _calories = 0;
                          _protein = 0;
                          _carbs = 0;
                          _fat = 0;
                          _caloriesController.clear();
                          _proteinController.clear();
                          _carbsController.clear();
                          _fatController.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(Spacing.xs),
                        decoration: BoxDecoration(
                          color: FGColors.background.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(Spacing.xs),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: FGColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: FGColors.background.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(Spacing.md),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: FGColors.accent,
                              strokeWidth: 2,
                            ),
                            const SizedBox(height: Spacing.sm),
                            Text(
                              'Analyse en cours...',
                              style: FGTypography.caption.copyWith(
                                color: FGColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: Spacing.md),
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: FGColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                  border: Border.all(
                    color: FGColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: FGColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: FGTypography.caption.copyWith(
                          color: FGColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Form fields (show after image is captured)
            if (_imageFile != null && !_isProcessing) ...[
              const SizedBox(height: Spacing.lg),
              Text(
                'Vérifiez et corrigez les valeurs',
                style: FGTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Food name
              _buildTextField(
                controller: _nameController,
                label: 'Nom de l\'aliment',
                hint: 'Ex: Yaourt nature',
                icon: Icons.restaurant_rounded,
              ),
              const SizedBox(height: Spacing.md),

              // Serving size
              _buildTextField(
                controller: _servingController,
                label: 'Portion',
                hint: 'Ex: 100g',
                icon: Icons.scale_rounded,
              ),
              const SizedBox(height: Spacing.md),

              // Nutrition values in grid
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      controller: _caloriesController,
                      label: 'Calories',
                      suffix: 'kcal',
                      color: FGColors.accent,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: _buildNumberField(
                      controller: _proteinController,
                      label: 'Protéines',
                      suffix: 'g',
                      color: const Color(0xFFE74C3C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      controller: _carbsController,
                      label: 'Glucides',
                      suffix: 'g',
                      color: const Color(0xFF3498DB),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: _buildNumberField(
                      controller: _fatController,
                      label: 'Lipides',
                      suffix: 'g',
                      color: const Color(0xFFF39C12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xl),

              // Submit button
              FGNeonButton(
                label: 'Ajouter cet aliment',
                isExpanded: true,
                onPressed: _submitFood,
              ),
            ],

            const SizedBox(height: Spacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FGTypography.caption.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Container(
          decoration: BoxDecoration(
            color: FGColors.glassSurface,
            borderRadius: BorderRadius.circular(Spacing.sm),
            border: Border.all(color: FGColors.glassBorder),
          ),
          child: TextField(
            controller: controller,
            style: FGTypography.body,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: FGTypography.body.copyWith(
                color: FGColors.textSecondary.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(icon, color: FGColors.textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.md,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FGTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Spacing.sm),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: FGTypography.body.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              suffixText: suffix,
              suffixStyle: FGTypography.caption.copyWith(
                color: FGColors.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.sm,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper function to show the nutrition scanner sheet
void showNutritionScannerSheet(
  BuildContext context, {
  required Function(Map<String, dynamic>) onFoodScanned,
}) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => NutritionScannerSheet(
      onFoodScanned: (food) {
        Navigator.pop(context);
        onFoodScanned(food);
      },
    ),
  );
}
