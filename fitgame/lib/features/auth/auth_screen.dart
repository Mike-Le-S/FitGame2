import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/fg_colors.dart';
import '../../core/theme/fg_typography.dart';
import '../../core/constants/spacing.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/fg_glass_card.dart';
import '../../shared/widgets/fg_neon_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await SupabaseService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await SupabaseService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = _parseError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _parseError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect';
    }
    if (error.contains('User already registered')) {
      return 'Cet email est déjà utilisé';
    }
    if (error.contains('Password should be at least')) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    if (error.contains('Invalid email')) {
      return 'Email invalide';
    }
    return 'Une erreur est survenue. Réessayez.';
  }

  void _toggleMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FGColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              children: [
                const SizedBox(height: Spacing.xxl),

                // Logo
                _buildLogo(),
                const SizedBox(height: Spacing.xxl),

                // Form
                FGGlassCard(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          _isLogin ? 'Connexion' : 'Inscription',
                          style: FGTypography.h2.copyWith(
                            color: FGColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          _isLogin
                              ? 'Content de te revoir !'
                              : 'Crée ton compte FitGame',
                          style: FGTypography.body.copyWith(
                            color: FGColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Spacing.lg),

                        // Error message
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(Spacing.sm),
                            decoration: BoxDecoration(
                              color: FGColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(Spacing.sm),
                              border: Border.all(
                                color: FGColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: FGColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: Spacing.sm),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: FGTypography.bodySmall.copyWith(
                                      color: FGColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Spacing.md),
                        ],

                        // Name field (signup only)
                        if (!_isLogin) ...[
                          _buildTextField(
                            controller: _nameController,
                            label: 'Nom complet',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Entre ton nom';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: Spacing.md),
                        ],

                        // Email field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Entre ton email';
                            }
                            if (!value.contains('@')) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Spacing.md),

                        // Password field
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: FGColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Entre ton mot de passe';
                            }
                            if (!_isLogin && value.length < 6) {
                              return 'Minimum 6 caractères';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Spacing.lg),

                        // Submit button
                        FGNeonButton(
                          label: _isLogin ? 'Se connecter' : "S'inscrire",
                          onPressed: _isLoading ? null : _handleSubmit,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: Spacing.md),

                        // Toggle mode
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? 'Pas encore de compte ?'
                                  : 'Déjà un compte ?',
                              style: FGTypography.bodySmall.copyWith(
                                color: FGColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: _toggleMode,
                              child: Text(
                                _isLogin ? "S'inscrire" : 'Se connecter',
                                style: FGTypography.bodySmall.copyWith(
                                  color: FGColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [FGColors.accent, Color(0xFFFF8F5C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: FGColors.accent.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.fitness_center,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: Spacing.md),
        RichText(
          text: TextSpan(
            style: FGTypography.h1.copyWith(
              fontSize: 32,
            ),
            children: const [
              TextSpan(
                text: 'Fit',
                style: TextStyle(color: FGColors.textPrimary),
              ),
              TextSpan(
                text: 'Game',
                style: TextStyle(color: FGColors.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          'Ton coach fitness personnel',
          style: FGTypography.body.copyWith(
            color: FGColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: FGTypography.body.copyWith(color: FGColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: FGTypography.body.copyWith(color: FGColors.textSecondary),
        prefixIcon: Icon(icon, color: FGColors.textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: FGColors.glassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.sm),
          borderSide: const BorderSide(color: FGColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.sm),
          borderSide: const BorderSide(color: FGColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.sm),
          borderSide: const BorderSide(color: FGColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.sm),
          borderSide: const BorderSide(color: FGColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.sm),
          borderSide: const BorderSide(color: FGColors.error, width: 2),
        ),
      ),
    );
  }
}
