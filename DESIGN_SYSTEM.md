# FitGame Pro - Design System (Ultra-Premium)

Ce document définit les règles visuelles de l'expérience FitGame Pro.
Ce système s'inspire du luxe moderne et de la performance automobile.

**RÈGLE ABSOLUE** : Aucune couleur, taille ou espacement ne doit être écrit "en dur" dans les écrans. Toujours utiliser les constantes définies dans ce système.

---

## 1. Couleurs (Atmosphère & Contraste)

| Rôle | Variable | Valeur | Usage |
|------|----------|--------|-------|
| Background Principal | `FGColors.background` | `#050505` | Fond de tous les écrans |
| Glass Surface | `FGColors.glassSurface` | `rgba(26, 26, 26, 0.6)` | Cards avec blur 20px |
| Surface Light | `FGColors.surfaceLight` | `rgba(255, 255, 255, 0.05)` | Bordures fines, overlays |
| Accent Primary | `FGColors.accent` | `#FF6B35` | CTAs, poids, éléments actifs |
| Accent Glow | `FGColors.accentGlow` | `rgba(255, 107, 53, 0.15)` | Lueurs, mesh gradients |
| Success | `FGColors.success` | `#2ECC71` | PR battus, tendances positives |
| Warning | `FGColors.warning` | `#F39C12` | Alertes, séries partielles |
| Error | `FGColors.error` | `#E74C3C` | Erreurs, échecs |
| Text Primary | `FGColors.textPrimary` | `#FFFFFF` | Texte principal |
| Text Secondary | `FGColors.textSecondary` | `#666666` | Métadonnées, labels discrets |

---

## 2. Typographie (Cinétique & Force)

La typographie évoque le mouvement et l'impact.

| Rôle | Taille | Poids | Style | Tracking | Usage |
|------|--------|-------|-------|----------|-------|
| Display | 64px | Black (w900) | Italic | -0.05em | Nombres hero (poids principal) |
| H1 | 40px | Black (w900) | Italic | -0.05em | Titres d'écran |
| H2 | 32px | Black (w900) | Italic | -0.05em | Sections principales |
| H3 | 24px | Bold (w700) | Normal | 0 | Sous-sections |
| Body | 16px | Regular (w400) | Normal | 0 | Texte courant |
| Caption | 14px | Regular (w400) | Normal | 0 | Descriptions |
| Label | 10px | Black (w900) | Normal | 0.3em | Labels uppercase |
| Numbers | 48px | Black (w900) | Italic | -0.02em | Données de performance |

**Règle** : Tous les nombres importants (poids, reps, timer) utilisent le style "Numbers" en couleur Accent.

---

## 3. Composants Signature

### Glass Card (Le "Cockpit")

Le composant principal pour encapsuler le contenu.

| Propriété | Valeur |
|-----------|--------|
| Fond | Gradient linéaire `rgba(255,255,255,0.05)` → `transparent` |
| Backdrop Blur | 20px |
| Bordure | 1px solid `rgba(255,255,255,0.1)` |
| Border Radius | 24px |
| Padding | 16px - 24px selon contenu |

### Neon Button (CTA Principal)

Le bouton d'action avec effet lumineux.

| Propriété | Valeur |
|-----------|--------|
| Fond | `#FF6B35` (Accent) |
| Border Radius | 16px |
| Padding | 16px vertical, 24px horizontal |
| Texte | 14px, Uppercase, Black (w900), couleur `#000000` |
| Shadow (actif) | `0px 0px 25px rgba(255, 107, 53, 0.5)` |
| Shadow (inactif) | Aucune |

### Secondary Button

| Propriété | Valeur |
|-----------|--------|
| Fond | `transparent` |
| Bordure | 1px solid `rgba(255,255,255,0.1)` |
| Border Radius | 16px |
| Texte | 14px, Uppercase, Black (w900), couleur `#FFFFFF` |

### Progress Ring

Pour les indicateurs circulaires (timer, macros).

| Propriété | Valeur |
|-----------|--------|
| Track Color | `rgba(255,255,255,0.1)` |
| Progress Color | `#FF6B35` (ou Success/Warning selon contexte) |
| Stroke Width | 8px |
| Cap | Round |

---

## 4. Espacements (Base 8px)

| Token | Valeur | Usage |
|-------|--------|-------|
| `Spacing.xs` | 4px | Micro-espacements internes |
| `Spacing.sm` | 8px | Entre éléments proches |
| `Spacing.md` | 16px | Padding cards, gaps standards |
| `Spacing.lg` | 24px | Entre sections |
| `Spacing.xl` | 32px | Marges d'écran |
| `Spacing.xxl` | 48px | Grandes séparations |

---

## 5. Effets & Animations

### Glow Effect (Lueur Orange)
```
BoxShadow(
  color: rgba(255, 107, 53, 0.5),
  blurRadius: 25,
  spreadRadius: 0,
)
```

### Glass Effect (Blur)
```
BackdropFilter: blur(20px)
Background: rgba(26, 26, 26, 0.6)
Border: 1px solid rgba(255, 255, 255, 0.1)
```

### Mesh Gradient (Fond atmosphérique)

Gradient radial avec `FGColors.accentGlow` positionné stratégiquement pour créer de la profondeur.

### Haptic Feedback

| Action | Pattern |
|--------|---------|
| Série validée | Light impact (1x) |
| PR battu | Medium impact (3x) |
| Timer terminé | Heavy impact |
| Erreur | Error pattern |

---

## 6. Structure Flutter
```
lib/
  core/
    theme/
      fg_colors.dart      ← Color et LinearGradient
      fg_typography.dart  ← TextStyle avec w900 et italic
      fg_effects.dart     ← BackdropFilter et BoxShadow
      app_theme.dart      ← ThemeData complet
    constants/
      spacing.dart        ← Constantes xs, sm, md, lg, xl, xxl
  shared/
    widgets/
      fg_glass_card.dart  ← ClipRRect + BackdropFilter
      fg_neon_button.dart ← Bouton avec glow animé
      fg_secondary_button.dart
      fg_progress_ring.dart ← CustomPainter cercle
```

---

## 7. Règles d'Implémentation

### TOUJOURS

- ✅ Utiliser `FGColors.accent` jamais `Color(0xFFFF6B35)`
- ✅ Utiliser `FGTypography.display` jamais `TextStyle(fontSize: 64)`
- ✅ Utiliser `Spacing.md` jamais `16.0`
- ✅ Utiliser `FGGlassCard` pour toute card
- ✅ Utiliser `FGNeonButton` pour le CTA principal

### JAMAIS

- ❌ Couleur en dur dans un widget
- ❌ Taille de texte en dur
- ❌ Espacement en dur (sauf exception documentée)
- ❌ `ElevatedButton` ou `Card` standard de Flutter
- ❌ Fond autre que `FGColors.background`

---

## 8. Guide d'Utilisation pour l'IA

Pour chaque nouvel écran, utilise cette instruction :

> "Génère l'écran [Nom] en respectant strictement le FitGame Pro Design System.
> - Utilise UNIQUEMENT les composants FG (FGGlassCard, FGNeonButton, etc.)
> - Utilise UNIQUEMENT les constantes (FGColors, FGTypography, Spacing)
> - Priorise le Glassmorphism et la typographie Black Italic
> - Les nombres importants sont en 48px+ Black Italic orange"

---

## 9. Exemples Visuels de Référence

### Hiérarchie d'un écran type
```
┌─────────────────────────────────────────┐
│ Fond: #050505                           │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ FGGlassCard                     │   │
│   │ ┌─────────────────────────────┐ │   │
│   │ │  87.5 kg                    │ │   │  ← Display, Orange, Italic
│   │ │  Squat Barre                │ │   │  ← H2, Blanc, Italic
│   │ │  Série 2/3                  │ │   │  ← Caption, Gris
│   │ └─────────────────────────────┘ │   │
│   │                                 │   │
│   │  ┌──────────────────────────┐   │   │
│   │  │   ✓ VALIDER SÉRIE        │   │   │  ← FGNeonButton
│   │  └──────────────────────────┘   │   │
│   └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

---

**Version** : 1.0
**Dernière mise à jour** : Janvier 2026
**Projet** : FitGame Pro