# Frontend Polish - Plan de corrections

> Audit et corrections UX/UI avant implémentation backend

**Status: ✅ TERMINÉ** - 2026-02-01

## Résumé

- **8 critiques** : ✅ Tous corrigés
- **8 majeures** : ✅ Tous corrigés (sauf TODOs gardés intentionnellement)
- **4 mineures** : TODOs gardés comme marqueurs pour backend

---

## Critiques (Section 1)

### FitGame Mobile

| # | Fichier | Avant | Après |
|---|---------|-------|-------|
| 1 | `lib/main.dart:95` | "Training" | "Entraînement" |
| 2 | `lib/features/home/widgets/today_workout_card.dart:85` | "45 min" | "~45-60 min" |
| 3 | `lib/features/health/sheets/sleep_detail_sheet.dart:317` | Jauge confuse | Ajouter "(moins = mieux)" |
| 4 | `lib/features/nutrition/nutrition_screen.dart` | Pas d'empty state | Placeholder "Ajoute des aliments" |

### Coach-Web

| # | Fichier | Action |
|---|---------|--------|
| 5 | `src/pages/auth/login-page.tsx:382` | Supprimer credentials démo |
| 6 | `src/components/layout/sidebar.tsx` | Retirer "Calendrier" |
| 7 | `src/pages/messages/messages-page.tsx` | Placeholder "Bientôt disponible" |
| 8 | `src/pages/settings/settings-page.tsx` | Cacher options theme désactivées |

---

## Majeures (Section 2)

### FitGame Mobile

| # | Fichier | Correction |
|---|---------|------------|
| 9 | `lib/features/nutrition/nutrition_screen.dart:668` | "TRAINING" → "ENTRAÎNEMENT" |
| 10 | `lib/features/profile/profile_screen.dart:660` | "Alertes progression" → "Alertes de progression" |
| 11 | `lib/features/social/social_screen.dart` | Gérer deadline: null → "Sans limite" |
| 12 | Nutrition/Workout screens | Empty states |

### Coach-Web

| # | Fichier | Correction |
|---|---------|------------|
| 13 | `nutrition-create-page.tsx` | Warning unsaved changes |
| 14 | Créer `src/constants/goals.ts` | Centraliser goalConfig |
| 15 | `student-profile-page.tsx` | Fix duplication sessions |
| 16 | Plusieurs | Cohérence "Plans nutritionnels" |

---

## Mineures (Section 3)

| # | Type | Action |
|---|------|--------|
| 17 | Typos FR | Audit final |
| 18 | Colors | Constantes au lieu de hardcoded |
| 19 | TODOs | Nettoyer commentaires |
| 20 | Magic numbers | Documenter ou extraire |

---

*Créé: 2026-02-01*
