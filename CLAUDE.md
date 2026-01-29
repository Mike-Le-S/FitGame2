# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Règles importantes

- **TOUJOURS utiliser `/frontend-design`** lors de toute modification ou création de frontend/UI
- **Ne JAMAIS lancer l'app** (`flutter run`) - Mike lance l'app dans son propre terminal
- **Après chaque tâche** : Mettre à jour `fitgame/docs/CHANGELOG.md` et `fitgame/docs/SCREENS.md`

## Commandes

```bash
flutter analyze              # Vérifier le code
flutter test                 # Lancer les tests
flutter pub get              # Installer les dépendances
```

## Architecture complète

```
fitgame/lib/
├── main.dart                              # Entry point + MainNavigation (5 onglets)
│
├── core/
│   ├── constants/spacing.dart             # Grille 8px (xs/sm/md/lg/xl/xxl)
│   ├── models/                            # Models partagés (exercise, workout_set)
│   └── theme/
│       ├── fg_colors.dart                 # Palette couleurs
│       ├── fg_typography.dart             # Typographie
│       ├── fg_effects.dart                # Blur, glow, shadows
│       └── app_theme.dart                 # ThemeData
│
├── shared/widgets/
│   ├── fg_glass_card.dart                 # Card glassmorphism
│   └── fg_neon_button.dart                # Bouton CTA avec glow
│
└── features/
    ├── home/home_screen.dart              # Onglet 1: Accueil
    ├── workout/                           # Onglet 2: Entraînement
    ├── nutrition/                         # Onglet 3: Nutrition
    ├── health/                            # Onglet 4: Santé
    └── profile/profile_screen.dart        # Onglet 5: Profil
```

## Écrans principaux (chemins exacts)

| Écran | Fichier | Description |
|-------|---------|-------------|
| **Navigation** | `lib/main.dart` | Bottom nav 5 onglets |
| **Accueil** | `lib/features/home/home_screen.dart` | Streak, stats, séance du jour |
| **Entraînement** | `lib/features/workout/workout_screen.dart` | Dashboard programmes |
| **Nutrition** | `lib/features/nutrition/nutrition_screen.dart` | Planificateur diète |
| **Santé** | `lib/features/health/health_screen.dart` | Énergie, Sommeil, Cœur |
| **Profil** | `lib/features/profile/profile_screen.dart` | Réglages, préférences |

## Sous-écrans Workout

| Écran | Fichier |
|-------|---------|
| Choix création | `lib/features/workout/create/create_choice_screen.dart` |
| Création programme | `lib/features/workout/create/program_creation_flow.dart` |
| Création séance | `lib/features/workout/create/session_creation_screen.dart` |
| Tracking workout | `lib/features/workout/tracking/active_workout_screen.dart` |

## Structure d'un feature

Chaque feature suit ce pattern :
```
features/{name}/
├── {name}_screen.dart       # Écran principal
├── sheets/                  # Bottom sheets
├── widgets/                 # Widgets spécifiques
├── painters/                # CustomPainters (si graphs/jauges)
├── modals/                  # Modales (si popup)
└── models/                  # Models locaux (si besoin)
```

## Design System

| Token | Classe | Exemples |
|-------|--------|----------|
| Couleurs | `FGColors` | `.background`, `.accent`, `.glassSurface`, `.success`, `.warning` |
| Typo | `FGTypography` | `.h1`, `.h2`, `.h3`, `.body`, `.bodySmall`, `.caption` |
| Spacing | `Spacing` | `.xs(4)`, `.sm(8)`, `.md(16)`, `.lg(24)`, `.xl(32)`, `.xxl(48)` |
| Effets | `FGEffects` | `.glassBlur`, `.neonGlow` |

**Règles UI :**
- Toujours dark mode (`FGColors.background` = #050505)
- Accent orange (`FGColors.accent` = #FF6B35)
- Widgets custom préfixés `FG` : `FGGlassCard`, `FGNeonButton`
- Headlines en italic bold (w900)

## Documentation détaillée

Pour les détails de chaque écran (composants, bottom sheets, mock data) :
- `fitgame/docs/SCREENS.md` - Documentation complète des écrans
- `fitgame/docs/CHANGELOG.md` - Historique des modifications
