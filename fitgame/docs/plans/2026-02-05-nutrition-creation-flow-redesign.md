# Redesign du Flow de Cr\u00e9ation de Plan Nutritionnel

**Date :** 2026-02-05
**Status :** Valid\u00e9

## Vision

Remplacer les 2 flows existants (PlanCreationFlow 3 \u00e9tapes + DietCreationFlow 8 \u00e9tapes legacy) par un **flow unique de 6 \u00e9tapes** combinant le meilleur des deux : l'architecture Day Types du PlanCreationFlow avec le polish UX et la compl\u00e9tude du DietCreationFlow.

## Principes directeurs

- Chaque \u00e9tape tient sur un \u00e9cran (pas de scroll infini)
- Feedback visuel imm\u00e9diat \u00e0 chaque modification
- Brouillon sauvegard\u00e9 localement (SharedPreferences) apr\u00e8s chaque \u00e9tape
- Confirmation dialog si l'user essaie de quitter
- Animations fluides entre les \u00e9tapes (slide horizontal)
- Progress bar cliquable pour retour libre aux \u00e9tapes visit\u00e9es

## Les 6 \u00e9tapes

### \u00c9tape 1 \u2014 Identit\u00e9 du Plan

- Titre anim\u00e9 : "Cr\u00e9e ton plan"
- Grand input centr\u00e9 pour le nom
- 4 suggestions chips anim\u00e9es : "Prise de masse", "S\u00e8che \u00e9t\u00e9", "Nutrition \u00e9quilibr\u00e9e", "Plan personnalis\u00e9"
- Tap chip = pr\u00e9-remplit nom ET pr\u00e9s\u00e9lectionne objectif/calories/macros aux \u00e9tapes suivantes

### \u00c9tape 2 \u2014 Objectif & Calories

**Section Objectif :** 3 cartes glass horizontales (Bulk / Maintien / S\u00e8che)
- Tap = glow accent orange + auto-remplissage calories

**Section Calories :** 2 cartes empil\u00e9es
- Jour Entra\u00eenement : valeur + boutons -100/+100, input direct
- Jour Repos : li\u00e9 intelligemment (auto = -400 kcal vs training), d\u00e9crochable

### \u00c9tape 3 \u2014 R\u00e9partition Macros

**Presets rapides** (chips scrollables) : \u00c9quilibr\u00e9, High Protein, Low Carb, Keto

**3 sliders interactifs** : Prot\u00e9ines %, Glucides %, Lipides %
- Affichage grammes en live
- Contrainte total = 100% (ajustement intelligent)

**Pie chart anim\u00e9** au centre se mettant \u00e0 jour en temps r\u00e9el

### \u00c9tape 4 \u2014 Day Types

**Liste des day types** sous forme de cartes compactes :
- Emoji + nom + nb repas + calories totales
- Boutons \u00e9diter / dupliquer / supprimer

**\u00c9diteur (bottom sheet fullscreen)** :
- Nom + emoji (grille de 14)
- Repas en accordions (nom, ic\u00f4ne, liste aliments)
- Bouton "Ajouter un repas" / "Ajouter un aliment" (\u2192 FoodAddSheet)

### \u00c9tape 5 \u2014 Planning Semaine

**Calendrier visuel** : 7 lignes (Lun\u2192Dim), chaque jour = s\u00e9lecteur custom inline avec day types

**R\u00e9sum\u00e9 en bas** : "X jours repos \u00b7 Y jours training" + calories moyennes hebdo

### \u00c9tape 6 \u2014 R\u00e9cap & Validation

**R\u00e9sum\u00e9 complet** en lecture seule, scrollable :
- Nom, objectif, calories, macros
- Planning semaine visuel
- Day types avec d\u00e9tail repas

**Sections cliquables** \u2192 redirigent vers l'\u00e9tape concern\u00e9e

**Bouton "Activer ce plan"** \u2192 animation succ\u00e8s + retour nutrition screen

## Comportements transversaux

| Comportement | Impl\u00e9mentation |
|---|---|
| Progress bar | 6 dots cliquables si \u00e9tape visit\u00e9e, pulse sur active |
| Brouillon auto | SharedPreferences apr\u00e8s chaque "Suivant" |
| Confirmation sortie | Dialog 3 options : Continuer / Sauvegarder brouillon / Supprimer |
| Bouton Suivant | FGNeonButton fixe en bas, d\u00e9sactiv\u00e9 si invalide |
| Animation | Slide horizontal + fade-in \u00e9l\u00e9ments |
| Bouton Retour | Fl\u00e8che haut-gauche \u2192 \u00e9tape pr\u00e9c\u00e9dente |

## Impact fichiers

### \u00c0 cr\u00e9er
- `fitgame/lib/features/nutrition/create/new_plan_creation_flow.dart` \u2014 Orchestrateur principal
- `fitgame/lib/features/nutrition/create/steps/identity_step.dart`
- `fitgame/lib/features/nutrition/create/steps/objective_calories_step.dart`
- `fitgame/lib/features/nutrition/create/steps/macros_step_v2.dart`
- `fitgame/lib/features/nutrition/create/steps/day_types_step.dart`
- `fitgame/lib/features/nutrition/create/steps/weekly_schedule_step.dart`
- `fitgame/lib/features/nutrition/create/steps/recap_step.dart`
- `fitgame/lib/features/nutrition/create/widgets/progress_dots.dart`
- `fitgame/lib/features/nutrition/create/widgets/day_type_editor_sheet.dart`

### \u00c0 modifier
- `fitgame/lib/features/nutrition/nutrition_screen.dart` \u2014 Pointer vers le nouveau flow
- `fitgame/lib/core/services/supabase_service.dart` \u2014 Adapter les m\u00e9thodes de sauvegarde si n\u00e9cessaire

### \u00c0 supprimer (apr\u00e8s migration)
- `fitgame/lib/features/nutrition/create/diet_creation_flow.dart` (legacy 8 steps)
- `fitgame/lib/features/nutrition/create/plan_creation_flow.dart` (ancien 3 steps)
- Steps individuels du legacy : name_step, goal_step, calories_step, meals_step, meal_names_step, preferences_step
