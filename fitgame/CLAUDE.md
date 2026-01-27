/sk# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Important

**Before any frontend/UI modification**, always read `/Users/mike/projects/FitGame2/DESIGN_SYSTEM.md` to ensure consistency with the design system.

## Commands

```bash
# Run the app
flutter run

# Run on specific device
flutter run -d ios
flutter run -d android
flutter run -d macos

# Analyze code
flutter analyze

# Run tests
flutter test

# Run single test file
flutter test test/widget_test.dart

# Get dependencies
flutter pub get
```

## Architecture

FitGame is a Flutter fitness gamification app with a custom dark theme design system.

### Project Structure

```
lib/
├── core/
│   ├── constants/     # App-wide constants (spacing)
│   └── theme/         # Design system (colors, typography, effects, theme)
├── shared/
│   └── widgets/       # Reusable UI components (FGGlassCard, FGNeonButton)
└── main.dart          # App entry point
```

### Design System

All UI follows the FitGame design system with `FG` prefix:

- **Colors** (`FGColors`): Dark background (#050505), orange accent (#FF6B35), glass surfaces
- **Typography** (`FGTypography`): Black (w900) italic headlines, tight letter-spacing (-0.05em)
- **Effects** (`FGEffects`): Glass blur (20px), neon glow shadows
- **Spacing** (`Spacing`): xs(4), sm(8), md(16), lg(24), xl(32), xxl(48)

### Widget Naming

Custom widgets use `FG` prefix: `FGGlassCard`, `FGNeonButton`

### Theme Usage

Always use `AppTheme.dark` - the app is dark-mode only. Access design tokens via the abstract classes (`FGColors.accent`, `FGTypography.h1`, etc.) rather than hardcoding values.
