import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/fg_colors.dart';
import '../../../core/theme/fg_typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/openfoodfacts_service.dart';
import '../../../core/services/supabase_service.dart';

class BarcodeScannerSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onFoodFound;
  final Function(String barcode) onFoodNotFound;

  const BarcodeScannerSheet({
    super.key,
    required this.onFoodFound,
    required this.onFoodNotFound,
  });

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isSearching = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isSearching) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode == _lastScannedCode) return;

    setState(() {
      _isSearching = true;
      _lastScannedCode = barcode;
    });

    HapticFeedback.mediumImpact();

    try {
      // 1. Search OpenFoodFacts
      var food = await OpenFoodFactsService.getProductByBarcode(barcode);

      // 2. If not found, search community foods
      if (food == null) {
        food = await SupabaseService.getCommunityFoodByBarcode(barcode);
        if (food != null) {
          // Convert community food format
          final nutrition = food['nutrition_per_100g'] as Map<String, dynamic>;
          food = {
            'name': food['name'],
            'brand': food['brand'],
            'barcode': barcode,
            'quantity': '100g',
            'cal': nutrition['cal'] ?? 0,
            'p': nutrition['p'] ?? 0,
            'c': nutrition['c'] ?? 0,
            'f': nutrition['f'] ?? 0,
          };
        }
      }

      if (mounted) {
        if (food != null) {
          Navigator.pop(context);
          widget.onFoodFound(food);
        } else {
          Navigator.pop(context);
          widget.onFoodNotFound(barcode);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: FGColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: FGColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: FGColors.accent),
                const SizedBox(width: Spacing.sm),
                Text('Scanner un code-barres', style: FGTypography.h3),
                const Spacer(),
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

          // Scanner
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Spacing.lg),
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _onBarcodeDetected,
                  ),
                ),

                // Scanning overlay
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isSearching ? FGColors.accent : Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(Spacing.lg),
                    ),
                  ),
                ),

                // Loading indicator
                if (_isSearching)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: FGColors.accent),
                          const SizedBox(height: Spacing.md),
                          Text(
                            'Recherche en cours...',
                            style: FGTypography.body.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Instructions
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Text(
              'Placez le code-barres dans le cadre',
              style: FGTypography.body.copyWith(
                color: FGColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show the barcode scanner sheet
void showBarcodeScannerSheet(
  BuildContext context, {
  required Function(Map<String, dynamic>) onFoodFound,
  required Function(String barcode) onFoodNotFound,
}) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => BarcodeScannerSheet(
      onFoodFound: onFoodFound,
      onFoodNotFound: onFoodNotFound,
    ),
  );
}
