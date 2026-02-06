# Écrans FitGame

| Écran | Fichier | Status | Description |
|-------|---------|--------|-------------|
| HomeScreen | `lib/features/home/home_screen.dart` | ✅ | Dashboard multi-domaines avec workout, sommeil, nutrition, social et navigation inter-onglets |
| WorkoutScreen | `lib/features/workout/workout_screen.dart` | ✅ | Interface épurée : prochaine séance, progression programme, activité récente, actions rapides, bouton "+" |
| MainNavigation | `lib/main.dart` | ✅ | Shell de navigation avec bottom nav bar (Accueil, Training, Social, Nutrition, Santé, Profil) |
| SocialScreen | `lib/features/social/social_screen.dart` | ✅ | Écran social avec Feed (séances potes) et Défis (compétitions) |
| NutritionScreen | `lib/features/nutrition/nutrition_screen.dart` | ✅ | Planificateur diète hebdomadaire avec macros, repas et bouton création |
| NewPlanCreationFlow | `lib/features/nutrition/create/new_plan_creation_flow.dart` | ✅ | Flow 6 étapes création plan nutritionnel (identité, objectif/calories, macros, types de jour, planning semaine, récapitulatif) |
| DietCreationFlow | `lib/features/nutrition/create/diet_creation_flow.dart` | 🔒 | Legacy - Flow 9 étapes création diète (non utilisé, remplacé par NewPlanCreationFlow) |
| HealthScreen | `lib/features/health/health_screen.dart` | ✅ | Écran santé avec 3 cartes expandables (Énergie, Sommeil, Cœur) + bottom sheets détaillés |
| ProfileScreen | `lib/features/profile/profile_screen.dart` | ✅ | Écran profil premium avec accomplissements et réglages |
| CreateChoiceScreen | `lib/features/workout/create/create_choice_screen.dart` | ✅ | Choix initial : créer programme ou séance unique |
| ProgramCreationFlow | `lib/features/workout/create/program_creation_flow.dart` | ✅ | Flow multi-étapes création programme (nom, durée, jours, exercices) - Refactorisé en 15 sous-fichiers |
| SessionCreationScreen | `lib/features/workout/create/session_creation_screen.dart` | ✅ | Création rapide séance unique avec sélection exercices |
| ActiveWorkoutScreen | `lib/features/workout/tracking/active_workout_screen.dart` | ✅ | Tracking workout en temps réel avec timer repos, validation séries, célébration PR |
| WorkoutHistoryScreen | `lib/features/workout/history/workout_history_screen.dart` | ✅ | Historique séances avec filtrage par type, stats par séance, détails |
| ProgramEditScreen | `lib/features/workout/edit/program_edit_screen.dart` | ✅ | Édition programme avec réorganisation séances, preview exercices |
| PlaceholderSheet | `lib/shared/sheets/placeholder_sheet.dart` | ✅ | Sheet réutilisable "Coming soon" pour fonctionnalités non implémentées |
| EditProfileSheet | `lib/features/profile/sheets/edit_profile_sheet.dart` | ✅ | Édition profil avec avatar, nom, email |
| AdvancedSettingsSheet | `lib/features/profile/sheets/advanced_settings_sheet.dart` | ✅ | Paramètres avancés : thème, données, export, zone danger |
| AchievementsSheet | `lib/features/profile/sheets/achievements_sheet.dart` | ✅ | Liste complète accomplissements avec progression et rareté |
| HelpSupportSheet | `lib/features/profile/sheets/help_support_sheet.dart` | ✅ | FAQ interactive avec contact support |
| LegalSheet | `lib/features/profile/sheets/legal_sheet.dart` | ✅ | CGU et Politique de confidentialité |
| NotificationsSheet | `lib/features/social/sheets/notifications_sheet.dart` | ✅ | Liste notifications sociales (respect, défis, PR, amis) |
| ExerciseProgressScreen | `lib/features/workout/progress/exercise_progress_screen.dart` | ✅ | Visualisation évolution des poids avec graphique et historique PRs |

## Détail HomeScreen

Dashboard multi-domaines intégrant un aperçu de chaque feature principale.

### Architecture
```
lib/features/home/
├── home_screen.dart              # Écran principal (orchestrateur)
└── widgets/
    ├── home_header.dart          # Header avec greeting + avatar + streak badge
    ├── quick_stats_row.dart      # 3 pills stats (séances, temps, kcal)
    ├── today_workout_card.dart   # Card workout héro
    ├── last_workout_row.dart     # Dernière séance avec check vert
    ├── sleep_summary_widget.dart # Résumé sommeil avec phases
    ├── macro_summary_widget.dart # Résumé nutrition avec macros
    └── friend_activity_peek.dart # Aperçu activité amis
```

### Structure de l'écran
| Position | Widget | Description | Navigation |
|----------|--------|-------------|------------|
| 1 | HomeHeader | Greeting + avatar + 🔥 badge streak compact | - |
| 2 | TodayWorkoutCard | Séance du jour héro avec muscles | ActiveWorkoutScreen |
| 3 | QuickStatsRow | 3 pills: séances/cible, temps, kcal | - |
| 4 | SleepSummaryWidget | Durée + phases + score qualité | Onglet Santé (4) |
| 5 | MacroSummaryWidget | Calories + barres P/C/F | Onglet Nutrition (3) |
| 6 | FriendActivityPeek | 2 activités récentes amis | Onglet Social (2) |
| 7 | LastWorkoutRow | Dernière séance avec check | Historique |
| 8 | BottomCTA | Bouton "Commencer la séance" | ActiveWorkoutScreen |

### Sleep Summary Widget
```
┌─────────────────────────────────────────────────┐
│ 😴 SOMMEIL           ┌──────┐    72 BON      > │
│    7h23              │██████│                   │
│ Profond  Core   REM  └──────┘                   │
└─────────────────────────────────────────────────┘
```
- Durée totale en grand
- Barre combinée 3 couleurs (Profond/Core/REM)
- Score qualité avec badge coloré
- Tap → onglet Santé

### Macro Summary Widget
```
┌─────────────────────────────────────────────────┐
│ 🍽️ NUTRITION          1847 / 2400 kcal       > │
│    [==========77%==========]                    │
│  P 89%  ●────   C 72%  ●────   F 65%  ●────    │
└─────────────────────────────────────────────────┘
```
- Barre calories avec glow
- 3 mini barres colorées P/C/F
- Tap → onglet Nutrition

### Friend Activity Peek
```
┌─────────────────────────────────────────────────┐
│ 👥 ACTIVITÉ                              VOIR > │
│  [●] Thomas D.    Push Day         il y a 2h   │
│  [●] Julie M.     Leg Day          il y a 5h   │
└─────────────────────────────────────────────────┘
```
- 2 activités récentes avec mini avatar
- Nom + workout + timestamp
- Tap → onglet Social

### Navigation inter-onglets
```dart
// main.dart
HomeScreen(onNavigateToTab: (index) => setState(() => _currentIndex = index))
```
- Callback passé depuis MainNavigation
- Permet navigation directe vers les onglets depuis les widgets

### Effets visuels
- Mesh gradient animé (orbes orange pulsants, 3s cycle)
- Haptic feedback sur tap des widgets
- Chevron indicateur de navigation sur chaque section

---

## Détail HealthScreen

### Structure de l'écran
| Position | Widget | Description |
|----------|--------|-------------|
| 1 | Header | "SANTÉ" + "Ton corps parle" + badge Sync vert |
| 2 | Hero Score | Score global 0-100 avec cercle animé + label + tendance |
| 3 | Quick Stats | 3 pills (Pas, Kcal, Sommeil) avec barres progression |
| 4 | Label section | "MÉTRIQUES DÉTAILLÉES" |
| 5 | Sleep Card | Durée + efficacité + barre phases → bottom sheet |
| 6 | Heart Card | FC/VFC/VO₂ en colonnes → bottom sheet |
| 7 | Energy Card | Balance calorique avec barres → bottom sheet |

### Hero Score Santé
```
┌─────────────────────────────────────────────────┐
│  ┌────┐                                     ↗   │
│  │ 78 │  SCORE SANTÉ                            │
│  └────┘  Bon                                    │
│          Basé sur sommeil, cœur et activité    │
└─────────────────────────────────────────────────┘
```
- Cercle avec score animé (count-up 1.5s)
- Couleur contextuelle : vert ≥80, violet ≥60, orange ≥40, rouge <40
- Label : Excellent / Bon / Moyen / À améliorer
- Badge tendance : moyenne des 3 métriques vs 7 jours

### Quick Stats Pills
```
┌─────────┐  ┌─────────┐  ┌─────────┐
│   🚶    │  │   🔥    │  │   🌙    │
│  8.7k   │  │  2450   │  │  7h23   │
│   pas   │  │   kcal  │  │ sommeil │
│ [====]  │  │ [====]  │  │ [====]  │
└─────────┘  └─────────┘  └─────────┘
```
- Barre de progression vs objectif
- Couleurs : cyan (pas), orange (kcal), violet (sommeil)

### Cartes principales
- **Sommeil** : Durée + efficacité% + barre phases empilées + score lettre
- **Cœur** : FC repos + VFC + VO₂ Max en 3 colonnes avec status badges
- **Énergie** : Badge net calories + barres consommé/dépensé côte à côte

### Bottom Sheet Sommeil (version compacte)
**Header compact** : Icône + titre + durée totale + badge efficacité%

**5 jauges visibles sans scroll** - design ultra-compact :
| Métrique | Idéal | Description |
|----------|-------|-------------|
| Profond | 13-23% | Récupération physique |
| Core | 45-55% | Consolidation mémoire |
| REM | 20-25% | Rêves & créativité |
| Éveillé | <5% | Réveils nocturnes (inversé) |
| Endormissement | 10-20min | Latence sommeil |

**Chaque jauge** :
- Point coloré + label + icône info (ⓘ) tappable
- Valeur (ex: "58m") + pourcentage + badge status (Optimal/Insuffisant/Élevé)
- Barre gradient rouge→jaune→vert avec curseur blanc animé

**Icône info** : Ouvre une modale explicative avec :
- Titre et description détaillée de la phase de sommeil
- Liste des bénéfices (récupération, mémoire, hormones, etc.)
- Impact fitness (comment ça affecte l'entraînement)
- Zone idéale recommandée

### Carte Cœur (principale)
- **2 métriques principales** : FC Repos + VFC côte à côte
- Chaque métrique : valeur grande + unité + badge status coloré
- Badge status contextuel (ATHLÈTE/EXCELLENT/BON/MOYEN/ÉLEVÉ pour FC, EXCELLENT/BON/MOYEN/FAIBLE pour VFC)
- Subtitle "Dernière nuit" pour clarifier la source des données

### Bottom Sheet Cœur (HeartDetailSheet)
**Onglets de période** : "Aujourd'hui" | "7 jours" | "14 jours"

**Vue Aujourd'hui** :
| Métrique | Idéal | Description |
|----------|-------|-------------|
| FC Repos | 50-70 BPM | Fréquence cardiaque au repos (athlètes: 40-60) |
| VFC | 50-100 ms | Variabilité cardiaque (plus haut = meilleure récupération) |

- **2 jauges CustomPainter** avec curseur lumineux et gradient couleur
- Icône info (ⓘ) tappable → modale éducative
- **Stats nuit** : Min/Moy/Max en 3 mini cards
- **VO₂ Max card** : Valeur + status (Supérieur/Excellent/Bon/Moyen/Faible)

**Vue Historique (7/14 jours)** :
- Cards résumé avec moyennes + icône tendance (↗ ↘ →)
- Graphique barres : évolution VFC colorée (vert=bon, jaune=moyen, rouge=faible)
- Liste détail par jour : jour | FC repos | VFC | tendance

**HeartInfoModal** : Pour FC repos, VFC et VO₂ Max
- Titre et description
- Liste des bénéfices
- Impact sur l'entraînement
- Zone idéale recommandée

### Bottom Sheet Énergie
- Balance calorique détaillée
- Breakdown par activité (BMR, Marche, Course, Musculation)
- Pas et distance

---

## Détail ProfileScreen

Dashboard profil avec accomplissements et réglages.

### Structure de l'écran
| Position | Widget | Description |
|----------|--------|-------------|
| 1 | Header | "PROFIL" + "Tes réglages" + bouton paramètres |
| 2 | Hero Profile Card | Avatar + Nom + Email + Stats |
| 3 | Accomplissements | Grid 6 badges (3 débloqués, 3 verrouillés) |
| 4 | Notifications | Switches pour notifications app |
| 5 | Préférences | Unités, langue, Apple Health, Sauvegarde |
| 6 | À propos | Noter, Aide, CGU, Confidentialité |
| 7 | Version | Footer avec version app |

### Hero Profile Card
```
┌─────────────────────────────────────────────────┐
│  ┌────────┐  Mike                               │
│  │   M    │  mike@fitgame.pro                   │
│  │  [✏️]  │                                     │
│  └────────┘                                     │
├─────────────────────────────────────────────────┤
│  147        🔥 12        Jan 2025               │
│  Séances    Streak      Membre                  │
└─────────────────────────────────────────────────┘
```
- Avatar avec gradient accent et glow 24px
- Bouton édition overlay sur l'avatar
- Stats en 3 colonnes avec dividers

### Section Accomplissements
```
ACCOMPLISSEMENTS                             3/6
┌─────────────────────────────────────────────────┐
│ 🏆        🔥        💪        🏃        🧠       ⭐ │
│Premier PR 7j Streak 100 Sé.. Marathon Iron Will Elite │
│ [accent]  [accent] [accent] [gris]    [gris]  [gris]│
└─────────────────────────────────────────────────┘
```
- Badges débloqués : gradient accent + border + glow
- Badges verrouillés : fond gris + icône grisée
- Compteur X/Y dans le header de section
- Tap → placeholder sheet

### Thème couleur
- **Accent** : Orange (#FF6B35) - cohérent avec le reste de l'app
- **Mesh gradient** : Orbes accent animés

### Animations
- **Mesh gradient** : Pulse 4s cycle (0.08→0.22 alpha)
- **Switches** : Transition fluide + glow

---

## Flow Création Programme/Séance

### CreateChoiceScreen
Point d'entrée accessible via bouton "+" en haut à droite de WorkoutScreen.
- **2 options** : Programme (multi-semaines) ou Séance unique
- Animation fade-in + glow pulsant en arrière-plan
- Cards descriptives avec icônes et descriptions

### ProgramCreationFlow (4 étapes)
Navigation par PageView avec indicateur de progression animé.

**Architecture refactorisée** (15 fichiers) :
```
lib/features/workout/create/
├── program_creation_flow.dart      # Orchestrateur principal (~280 lignes)
├── utils/
│   ├── exercise_catalog.dart       # Catalogue 20 exercices + groupes musculaires
│   └── exercise_calculator.dart    # Calcul séries selon mode (RPT/Pyramidal/Dropset)
├── widgets/
│   ├── number_picker.dart          # NumberPicker (compact) + ExpandedNumberPicker
│   ├── toggle_card.dart            # ToggleCard glassmorphism avec switch
│   ├── mode_card.dart              # ModeCard pour sélection mode entraînement
│   ├── day_tabs.dart               # DayTabs navigation jours avec compteurs
│   ├── exercise_catalog_picker.dart # Sélecteur exercices par groupe musculaire
│   └── day_exercise_list.dart      # Liste réordonnables avec supersets
├── sheets/
│   ├── success_modal.dart          # Modal succès avec animation + stats
│   ├── custom_exercise_sheet.dart  # Création exercice personnalisé
│   └── exercise_config_sheet.dart  # Configuration mode/sets/reps/warmup
└── steps/
    ├── name_step.dart              # Étape 1 - Nom programme
    ├── cycle_step.dart             # Étape 2 - Configuration cycle/deload
    ├── days_step.dart              # Étape 3 - Sélection jours
    └── exercises_step.dart         # Étape 4 - Configuration exercices
```

**Étape 1 - Nom** :
- Champ texte avec suggestions cliquables
- Suggestions : Push Pull Legs, Full Body, Upper Lower, Bro Split, Force 5x5

**Étape 2 - Durée & Cycle** :
- **Toggle "Activer un cycle"** :
  - OFF : Programme continu (∞) sans limite de temps
  - ON : Programme avec durée définie
- Si cycle activé :
  - Sélecteur durée (jauge circulaire, 1-24 semaines)
  - Toggle "Semaine de deload"
  - Si deload activé :
    - Fréquence : deload après X semaines (2-8)
    - Réduction poids : slider 20-60%
    - Exemple calculé en temps réel
- Info card contextuelle selon la configuration

**Étape 3 - Jours d'entraînement** :
- 7 boutons pour L/M/M/J/V/S/D
- Sélection multiple avec animation gradient
- Résumé : nombre de séances + liste des jours

**Étape 4 - Exercices par jour** :
- **Onglets de navigation** : Un onglet par jour sélectionné (ex: Lun | Mer | Ven)
  - Badge compteur sur chaque onglet
  - Bordure verte si exercices configurés
  - Glow accent sur onglet actif
- **Résumé jour** : Card avec initial + nom du jour + compteur + check validation
- **Catalogue exercices groupé par muscle** :

| Muscle | Exercices disponibles |
|--------|----------------------|
| Pectoraux | Développé couché, Développé incliné, Écarté poulie |
| Dos | Soulevé de terre, Rowing barre, Tractions, Tirage vertical |
| Épaules | Développé militaire, Élévations latérales, Oiseau |
| Biceps | Curl biceps, Curl marteau |
| Triceps | Extension triceps, Dips |
| Jambes | Squat barre, Presse jambes, Leg curl, Leg extension |
| Abdos | Crunch, Planche |

- **Liste séance du jour** : Drag-and-drop pour réordonner
  - Numérotation automatique
  - **Bouton "Config"** (icône tune) pour configuration avancée
  - **Long-press** pour sélectionner pour superset (fond vert)
  - **Badge mode** si mode avancé (RPT, Pyramidal, Dropset)
  - **Badge "WARMUP"** jaune si échauffement activé
  - **Bordure verte + badge "S1"** si dans un superset
  - Bouton suppression
- **Bouton "Créer superset"** : Apparaît si 2+ exercices sélectionnés (glow vert)
- **Exercice personnalisé** : Nom + muscle + mode + warmup

**Configuration avancée (Bottom Sheet)** :
- **Sélecteur de mode** : 4 cards animées avec glow
  - **Classique** : Sets × Reps standards (icon: fitness_center)
  - **RPT** : Reverse Pyramid -10% poids/-2 reps (icon: trending_down)
  - **Pyramidal** : Montée progressive 70%→100% (icon: trending_up)
  - **Dropset** : 1 série + 3 drops -20%/-40%/-60% (icon: arrow_downward)
- **Sets/Reps pickers** : Pour modes Classic et RPT
- **Toggle échauffement** :
  - Description dynamique selon mode
  - Icône flame, couleur warning
  - RPT : "2 séries: 60%×8, 80%×5"
  - Classic : "1 série: 50%×10"
- **Preview table temps réel** :
  - Header : SÉRIE | POIDS | REPS
  - Badge "W" pour séries warmup
  - Poids en % (100%, 90%, 80%...)
  - Reps calculés selon mode
  - Fond accent sur header
  - Dividers entre lignes

- **Validation** : Bouton actif si chaque jour a ≥1 exercice

### SessionCreationScreen
Création rapide d'une séance unique.

**Composants** :
- Champ nom de séance
- Filtres groupes musculaires (chips sélectionnables)
- Liste exercices suggérés (filtrée par muscles)
- Bouton "Personnalisé" → bottom sheet ajout exercice custom
- Liste réordonnableréordonnableréordonnableréordonnableur des exercices sélectionnés (drag & drop)

**Exercices suggérés** :
| Exercice | Muscle | Sets | Reps |
|----------|--------|------|------|
| Développé couché | Pectoraux | 4 | 10 |
| Squat barre | Jambes | 4 | 8 |
| Rowing barre | Dos | 4 | 10 |
| Développé militaire | Épaules | 3 | 12 |
| Curl biceps | Biceps | 3 | 12 |
| Extension triceps | Triceps | 3 | 12 |
| Soulevé de terre | Dos | 4 | 6 |
| Presse jambes | Jambes | 4 | 12 |
| Tractions | Dos | 4 | 8 |
| Dips | Triceps | 3 | 10 |

---

## NutritionScreen

Planificateur de diète hebdomadaire complet (différent du logging quotidien type MyFitnessPal).

### Header
- **Titre** : "NUTRITION" + "Plan semaine"
- **Chip objectif** : Prise / Sèche / Maintien (tap → bottom sheet sélection)
- **Bouton "+"** : Icône add verte avec glow → ouvre DietCreationFlow

### Sélecteur de jour
Barre horizontale de 7 jours (LUN-DIM) avec :
- **Point orange** sur les jours d'entraînement
- **Mini progress ring** montrant % calories atteintes
- **Bordure orange** sur le jour sélectionné avec glow si training
- **Swipe horizontal** pour naviguer entre les jours (PageView)

### Dashboard Macros
Card glassmorphism affichant :
- **Calories hero** : Nombre animé + objectif (ex: "2847 / 3200")
- **Progress ring** principal avec % et couleur contextuelle (vert si 90-110%, jaune si >110%, orange sinon)
- **3 mini rings** pour P/G/L avec valeurs en grammes et objectifs

| Macro | Couleur | Ring |
|-------|---------|------|
| Protéines | Rouge (#E74C3C) | Progress ring |
| Glucides | Bleu (#3498DB) | Progress ring |
| Lipides | Jaune (#F39C12) | Progress ring |

### Badge Training
Sur les jours d'entraînement : badge orange "TRAINING" avec icône haltère

### Cartes Repas
4 repas par jour, chacun dans une FGGlassCard expandable :

| Repas | Icône |
|-------|-------|
| Petit-déjeuner | sun |
| Déjeuner | restaurant |
| Collation | apple |
| Dîner | moon |

**Header carte** (collapsed) :
- Icône dans carré orange
- Nom du repas + nombre d'aliments
- Calories totales + protéines
- Chevron rotation 180° quand expanded

**Contenu expanded** :
- Liste des aliments avec quantité
- Chaque aliment affiche : nom, quantité, pills P/C/F colorés, calories
- Tap sur aliment → bottom sheet édition (slider quantité 0.25x-3x)
- Bouton "+ Ajouter un aliment" → ouvre bibliothèque

### Quick Actions
3 boutons en bas de page :
| Action | Icône | Description |
|--------|-------|-------------|
| Dupliquer | copy | Copie le jour vers d'autres jours |
| Réinitialiser | refresh | Supprime tous les aliments du jour |
| Partager | share | Partage le plan (placeholder) |

### Bottom Sheet Objectif (GoalSelectorSheet)
3 options avec descriptions :
- **Prise de masse** : Surplus calorique pour développer le muscle
- **Sèche** : Déficit calorique pour perdre du gras
- **Maintien** : Équilibre pour maintenir le poids actuel

### Bottom Sheet Génération IA (GenerateAISheet)
- **Toggle** : Ajuster selon l'entraînement (+ glucides les jours training)
- **Sélecteur** : Nombre de repas par jour (3, 4, 5, 6)
- **Bouton** : "Générer le plan"

### Bilan Calories Card (CalorieBalanceCard) 🆕
Card en haut de chaque jour affichant :
- **Calories consommées** : Total des repas
- **Calories brûlées** : Depuis Apple Santé
- **Balance** : Déficit/Surplus avec couleur selon objectif
- **Prédiction fin de journée** : Basée sur historique 7 jours
- **Barre de progression** : Vers objectif calorique

### Plan vs Tracking 🆕
- **Plan** = Template de ce qu'on doit manger (inchangé sur les autres jours)
- **Tracking** = Ce qu'on a réellement mangé aujourd'hui
- Les modifications sur le jour actuel vont dans le tracking
- Affichage "120g / 150g prévu" si quantité différente du plan

### Bottom Sheet Ajout Aliment (FoodAddSheet) 🆕
Interface principale d'ajout :
- **Recherche** : Champ texte avec icône loupe
- **Boutons rapides** : Scanner, Favoris, Templates
- **Liste aliments récents** : Depuis les favoris

### Bottom Sheet Scanner (BarcodeScannerSheet) 🆕
Scanner de codes-barres :
- **Caméra** avec cadre de scan
- **Recherche OpenFoodFacts** en premier
- **Fallback base communautaire** si non trouvé
- **Proposition contribution** si introuvable

### Bottom Sheet Contribution (ContributeFoodSheet) 🆕
Formulaire quand aliment non trouvé :
- **Code-barres** affiché
- **Champs** : Nom, marque, calories, P/C/F pour 100g
- **Info** : Partage avec la communauté FitGame

### Bottom Sheet Favoris (FavoriteFoodsSheet) 🆕
Liste des aliments favoris :
- **Triés par fréquence** d'utilisation
- **Tap** pour ajouter au repas
- **Swipe** pour supprimer

### Bottom Sheet Templates (MealTemplatesSheet) 🆕
Templates de repas sauvegardés :
- **Nom + nombre d'aliments** + calories
- **Tap** pour ajouter tous les aliments du template

### Bottom Sheet Édition Aliment (EditFoodSheet)
- **Nom et quantité** de l'aliment
- **Champ saisie directe** des grammes (1-9999g)
- **Boutons +/-** par pas de 10g
- **Presets rapides** : 25g, 50g, 100g, 150g, 200g, 250g, 300g
- **Macros calculés** en temps réel
- **Bouton supprimer** (icône trash rouge)
- **Bouton enregistrer**

### Bottom Sheet Dupliquer (DuplicateDaySheet)
- Sélection multiple des jours cibles
- Exclut le jour source
- Bouton "Dupliquer vers X jour(s)"

### Données Mock
7 jours de repas pré-configurés avec aliments variés :
- ~20 aliments différents par jour
- Macros réalistes calculés
- Mix protéines (poulet, saumon, oeufs), glucides (riz, pâtes, patates), légumes, fruits, compléments

### Objectifs Caloriques par Défaut

| Objectif | Training | Repos | Protéines | Glucides | Lipides |
|----------|----------|-------|-----------|----------|---------|
| Prise | 3200 | 2800 | 180g | 380g | 90g |
| Sèche | 2400 | 2000 | 200g | 200g | 70g |
| Maintien | 2800 | 2500 | 170g | 300g | 80g |

---

## DietCreationFlow

Flow complet de création de diète personnalisée en 8 étapes.

### Accès
- Bouton "+" vert en haut à droite de NutritionScreen
- Animation slide-up à l'ouverture

### Architecture
```
lib/features/nutrition/create/
├── diet_creation_flow.dart      # Orchestrateur principal
├── steps/
│   ├── name_step.dart           # Étape 1 - Nom
│   ├── goal_step.dart           # Étape 2 - Objectif
│   ├── calories_step.dart       # Étape 3 - Calories
│   ├── macros_step.dart         # Étape 4 - Macros
│   ├── meals_step.dart          # Étape 5 - Nombre repas
│   ├── preferences_step.dart    # Étape 6 - Préférences alimentaires 🆕
│   ├── meal_names_step.dart     # Étape 7 - Noms repas
│   ├── meal_planning_step.dart  # Étape 8 - Planning repas
│   └── supplements_step.dart    # Étape 9 - Compléments
├── sheets/
│   ├── diet_success_modal.dart  # Modal de succès
│   └── food_quantity_sheet.dart # Sélecteur quantité aliment (NEW)
└── ../models/
    └── diet_models.dart         # FoodEntry, MealPlan, SupplementEntry (NEW)
```

### Étape 1 - Nom (`name_step.dart`)
- **Titre** : "Nomme ton plan"
- **TextField** glassmorphism avec placeholder
- **Suggestions chips** : Plan Prise, Diète Sèche, Nutrition Équilibre, Plan Perso
- Chips verts quand sélectionnés

### Étape 2 - Objectif (`goal_step.dart`)
- **Titre** : "Ton objectif"
- **3 cards sélectionnables** :

| Objectif | Icône | Couleur | Description |
|----------|-------|---------|-------------|
| Prise de masse | trending_up | Orange | Surplus calorique pour développer le muscle |
| Sèche | trending_down | Bleu | Déficit calorique pour perdre du gras |
| Maintien | remove | Vert | Équilibre pour maintenir le poids actuel |

- Animation glow + bordure colorée quand sélectionné
- Met à jour automatiquement les calories par défaut

### Étape 3 - Calories (`calories_step.dart`)
- **Titre** : "Objectifs caloriques"
- **2 cards** :
  - Jour Training : icône fitness_center, glow orange
  - Jour Repos : icône hotel, glow vert
- **Contrôles** :
  - Boutons +/- (±50 kcal) pour ajustement rapide
  - Tap sur valeur → ListWheelScrollView picker (1000-5000 kcal, pas de 50)
- **Indicateur différence** entre jours training et repos

### Étape 4 - Macros (`macros_step.dart`)
- **Titre** : "Répartition macros"
- **Presets** :

| Preset | P | C | F |
|--------|---|---|---|
| Équilibré | 30% | 45% | 25% |
| High Protein | 40% | 35% | 25% |
| Low Carb | 35% | 25% | 40% |

- **3 sliders** avec couleurs distinctes :
  - Protéines : Rouge (#E74C3C)
  - Glucides : Bleu (#3498DB)
  - Lipides : Jaune (#F39C12)
- **Validation** : warning si total != 100%
- **Résumé** : badges P/C/F avec grammes calculés

### Étape 5 - Repas (`meals_step.dart`)
- **Titre** : "Repas par jour"
- **Sélecteur** : 4 boxes (3, 4, 5, 6) avec glow vert sur actif
- **Preview liste repas** :

| Nombre | Repas |
|--------|-------|
| 3 | Petit-déjeuner, Déjeuner, Dîner |
| 4 | Petit-déjeuner, Déjeuner, Collation, Dîner |
| 5 | Petit-déjeuner, Collation AM, Déjeuner, Collation PM, Dîner |
| 6 | Petit-déjeuner, Collation AM, Déjeuner, Collation PM, Dîner, Collation soir |

- **Icônes** par type : soleil, resto, pomme, lune
- **Info tip** : "Plus de repas = portions plus petites"

### Étape 6 - Préférences alimentaires (`preferences_step.dart`) 🆕
- **Titre** : "Préférences alimentaires"
- **Subtitle** : "Personnalise ton plan selon tes goûts"
- **Section Restrictions** :

| Restriction | Icône | Couleur sélection |
|-------------|-------|-------------------|
| Végétarien | eco | Rouge (#E74C3C) |
| Vegan | spa | Rouge |
| Sans gluten | grain | Rouge |
| Sans lactose | no_drinks | Rouge |

- **Section Aliments préférés** :

| Aliment | Icône | Couleur sélection |
|---------|-------|-------------------|
| Poulet | restaurant | Vert (#2ECC71) |
| Poisson | set_meal | Vert |
| Boeuf | lunch_dining | Vert |
| Oeufs | egg | Vert |
| Riz | rice_bowl | Vert |
| Pâtes | ramen_dining | Vert |
| Légumes | grass | Vert |
| Fruits | apple | Vert |

- **Chips sélectionnables** : Multi-select avec animation
- **Info card** : "Cette étape est optionnelle. Tu peux la passer si tu veux."
- **Étape optionnelle** : bouton "Passer" disponible

### Étape 7 - Noms des repas (`meal_names_step.dart`)
- **Titre** : "Nomme tes repas"
- **ReorderableListView** pour réorganiser l'ordre des repas
- **Chaque carte repas** :
  - Drag handle pour réordonner
  - Badge numéro vert
  - Icône tappable → bottom sheet sélecteur (8 icônes)
  - TextField éditable pour le nom
- **Icônes disponibles** : soleil, restaurant, pomme, lune, café, oeuf, haltère, nuit
- **Info tip** : "Maintiens et glisse pour réorganiser"

### Étape 8 - Planification repas (`meal_planning_step.dart`)
- **Titre** : "Planifie tes repas"
- **DayTypeToggle** : TRAINING (orange) / REPOS (vert)
  - Chaque type a ses propres listes de repas
  - Objectifs caloriques différents
- **Macro Dashboard** temps réel :
  - Barre progression calories avec couleur contextuelle
  - Mini indicateurs P/C/F avec valeurs actuelles/cibles
- **Bouton "Copier Training → Repos"** (visible sur jours repos si training a des aliments)
- **Cards repas expandables** :
  - Header : icône + nom + nombre aliments + calories + protéines
  - Contenu expanded : liste aliments + bouton ajouter
  - Tap "+ Ajouter" → FoodLibrarySheet → FoodQuantitySheet → ajout
  - Aliments avec nom, quantité (ex: "2× 100g"), calories, macros (P/C/F)
  - Bouton suppression par aliment
- **FoodQuantitySheet** (`create/sheets/food_quantity_sheet.dart`) :
  - Slider quantité 0.25x → 5x
  - Presets rapides : 0.5, 1, 1.5, 2, 3
  - Preview macros calculés en temps réel
  - Bouton "Ajouter" pour confirmer
- **Étape optionnelle** : bouton "Passer" disponible

### Étape 9 - Compléments (`supplements_step.dart`)
- **Titre** : "Compléments"
- **Catalogue** : 8 compléments prédéfinis en chips

| Complément | Icône | Dosage défaut | Moment |
|------------|-------|---------------|--------|
| Créatine | science | 5g | Post-workout |
| Whey Protein | local_drink | 30g | Post-workout |
| BCAA | bubble_chart | 5g | Pré-workout |
| Multivitamines | medication | 1 capsule | Matin |
| Oméga-3 | water_drop | 2 capsules | Avec repas |
| Vitamine D | wb_sunny | 2000 IU | Matin |
| Zinc | shield | 25mg | Soir |
| Magnésium | flash_on | 400mg | Soir |

- **Cards compléments sélectionnés** :
  - Header : icône + nom + timing (tappable) + dosage (tappable) + bouton supprimer
  - Timing : bottom sheet avec 5 options (Matin, Pré/Post-workout, Soir, Avec repas)
  - Dosage : bottom sheet avec TextField
  - Toggle notification + time picker
- **Étape optionnelle** : bouton "Passer" disponible

### Modal Succès (`diet_success_modal.dart`)
- Animation scale elasticOut (600ms)
- Icône restaurant_menu dans cercle vert avec gradient
- Nom de la diète en couleur accent
- **Stats** : Objectif | Kcal | Repas/jour | Compléments (si > 0)
- Bouton "Parfait" vert

### Orchestrateur (`diet_creation_flow.dart`)
- **Mesh gradient** vert/teal pulsant (4s cycle)
- **Header** : bouton retour/fermer + "Étape X/9"
- **Progress bar** : 9 segments, glow vert sur actif
- **Validation par étape** :
  - Étape 1 : nom requis
  - Étape 2 : objectif sélectionné
  - Étape 3 : calories > 0
  - Étape 4 : total macros = 100%
  - Étape 5 : repas entre 3-6
  - Étape 6 : optionnelle (préférences alimentaires)
  - Étape 7 : tous les noms de repas remplis
  - Étape 8 : optionnelle (planning repas)
  - Étape 9 : optionnelle (compléments)
- **Bouton bottom** : "Continuer" ou "Créer le plan" (dernier step)
- **Bouton "Passer"** visible sur étapes 6, 8 et 9

### State Management
```dart
// Basic info
String _dietName = '';
String _goalType = 'maintain';
int _trainingCalories = 2800;
int _restCalories = 2500;
int _proteinPercent = 30;
int _carbsPercent = 45;
int _fatPercent = 25;
int _mealsPerDay = 4;

// Dietary preferences
Set<String> _restrictions = {};     // vegetarian, vegan, gluten_free, lactose_free
Set<String> _preferences = {};      // chicken, fish, beef, eggs, rice, pasta, vegetables, fruits

// Meal customization
List<String> _mealNames = [];
List<IconData> _mealIcons = [];

// Meal planning
List<MealPlan> _trainingDayMeals = [];
List<MealPlan> _restDayMeals = [];

// Supplements
List<SupplementEntry> _supplements = [];
```

### Models (`diet_models.dart`)

```dart
// Food entry in a meal
class FoodEntry {
  final String id, name, quantity, unit;
  final int calories, protein, carbs, fat;
}

// Meal with foods
class MealPlan {
  final String name;
  final IconData icon;
  final List<FoodEntry> foods;
  int get totalCalories => ...;
  int get totalProtein => ...;
}

// Supplement timing options
enum SupplementTiming { morning, preWorkout, postWorkout, evening, withMeal }

// Supplement entry
class SupplementEntry {
  final String id, name, dosage;
  final IconData icon;
  final SupplementTiming timing;
  final bool notificationsEnabled;
  final TimeOfDay? reminderTime;
}
```

---

## ProfileScreen

Écran de paramètres et profil utilisateur.

### Carte Profil
- Avatar : cercle avec initiale + gradient orange + glow
- Nom et email utilisateur
- Bouton édition (icône crayon)
- **Stats** : 3 métriques en ligne avec dividers
  - Séances totales
  - Jours de série
  - Membre depuis

### Section Notifications
**Toggle master** : Active/désactive toutes les notifications

**Sub-toggles** (visibles si master activé) :
| Toggle | Description |
|--------|-------------|
| Rappels séances | Notification avant chaque séance |
| Jours de repos | Rappel de récupération |
| Alertes progression | Nouveau PR, objectifs atteints |

**Custom Switch** : Animation bounce + glow orange quand activé

### Section Préférences
| Préférence | Type | Options |
|------------|------|---------|
| Unité de poids | Segmented control | kg / lbs |
| Langue | Segmented control | Français / English |
| Apple Health | Navigation tile | Status connexion (badge vert) |
| Sauvegarde | Navigation tile | iCloud status (badge vert) |

### Section À propos
Liens de navigation avec chevron :
- Noter l'app → App Store
- Aide & Support → FAQ/Contact
- Conditions d'utilisation → CGU
- Politique de confidentialité → Privacy

### Footer
Version app centrée (FitGame Pro v1.0.0)

---

## ActiveWorkoutScreen

Écran de tracking workout en temps réel - le cœur de l'expérience FitGame.

### Accès
- Tap sur la card "Prochaine séance" dans WorkoutScreen
- Tap sur le bouton play dans la card session

### Header
- Bouton fermer (X) avec confirmation avant sortie
- Nom de l'exercice + badge muscle coloré
- Position dans la séance (ex: "2/5")
- Timer de séance (format MM:SS ou Xh MM)

### Navigation Exercices
**Dots indicators** :
- Dot actif : élargi (24px) + couleur accent + glow
- Dots complétés : vert
- Dots restants : gris glassBorder
- Tap sur dot pour naviguer

### Vue Active (série en cours)

**Carte Série Principale** :
| Élément | Style |
|---------|-------|
| Badge warmup | Fond warning 20%, texte warning, icône flame |
| Label série | "SÉRIE X" en caption secondary |
| Poids | Display 56px, orange accent, italic |
| Reps | Display 56px, blanc, italic |
| Record | Icône trophée + "Record: Xkg" en caption |

**Zone d'entrée** :
- 2 cards Poids / Reps côte à côte
- Boutons -/+ pour ajustement rapide
  - Poids : ±2.5kg
  - Reps : ±1
- Tap sur valeur → NumberPickerSheet avec clavier et presets

**Bouton Valider** :
- Full width avec glow neon
- Animation pulse subtile (0.95-1.0)
- Texte "VALIDER LA SÉRIE"
- Déclenche timer repos après tap

**Indicateurs séries** :
- Ligne de boxes représentant chaque série
- Warmup : icône flame
- Travail : numéro
- Active : bordure accent + fond accent 20%
- Complétée : fond vert + icône check

**Stats Live** :
| Stat | Icône | Exemple |
|------|-------|---------|
| Volume | fitness_center | 1.2t |
| Séries | repeat | 8 |
| Kcal | fire | 245 |

### Vue Repos (timer entre séries)

**Timer circulaire** (240×240px) :
- CustomPainter avec track gris + arc progression vert
- Glow lumineux à l'extrémité de l'arc
- Centre : "REPOS" label + temps MM:SS (64px)

**Preview prochaine série** :
- Card glassmorphism
- Si même exercice : "Xkg × Y reps"
- Si prochain exercice : Nom + muscle

**Contrôles** :
- Bouton "+30s" : glassmorphism, ajoute 30 secondes
- Bouton "PASSER" : accent avec glow, skip le repos

**Haptic Feedback** :
- lightImpact à 10s, 5s, 3s, 2s, 1s
- heavyImpact à 0s (fin repos)

### Célébration PR (Personal Record)

Déclenchée quand poids > record précédent :

- Overlay fullscreen fond vert 10%
- Animation scale 0.8→1.2
- Icône trophée 64px dans cercle vert glow
- Texte "NOUVEAU RECORD !" en H1 vert
- Triple haptic (heavy + medium après 1s)
- Disparaît après 2s

### Bottom Sheets

**NumberPickerSheet** :
- TextField centré style display
- Presets rapides (Poids: 60, 80, 100, 120, 140 / Reps: 5, 8, 10, 12, 15, 20)
- Bouton confirmer accent

**WorkoutCompleteSheet** :
- Icône trophée grande dans cercle vert
- Titre "SÉANCE TERMINÉE !"
- Stats : Durée, Volume (tonnes), Kcal
- Bouton "TERMINER" ferme l'écran

**ExitConfirmationSheet** :
- Icône warning dans cercle jaune
- Message "Quitter la séance ?"
- Subtitle "Ta progression sera perdue."
- 2 boutons : "CONTINUER" (secondary) / "QUITTER" (error rouge)

### Mock Data

**Séance Leg Day** :
| Exercice | Muscle | Sets | Repos |
|----------|--------|------|-------|
| Squat Barre | Quadriceps | 1 warmup + 4 travail | 180s |
| Presse Jambes | Quadriceps | 4 | 120s |
| Leg Extension | Quadriceps | 3 | 90s |
| Leg Curl | Ischio-jambiers | 3 | 90s |
| Mollets Debout | Mollets | 4 | 60s |

### Animations & Effets

- Mesh gradient dynamique : orange en mode actif, vert en repos
- Pulse animation sur bouton valider (1.5s cycle)
- Transitions exercices : slide horizontal
- Timer ring : progression smooth
- PR celebration : scale + fade combo

---

## SocialScreen

Écran social avec deux sections : Feed (séances des potes) et Défis (compétitions).

### Accès
- 3ème onglet dans la bottom navigation bar (icône people)

### Header
- **Titre** : "SOCIAL" + "Ta communauté"
- **Cloche notifications** : Badge rouge si non lues

### Segmented Control
Toggle entre deux onglets :
- **FEED** : Voir les séances des amis
- **DÉFIS** : Voir et créer des défis

### Feed - Séances des potes

**ActivityCard** - Carte de séance :
| Section | Contenu |
|---------|---------|
| Header | Avatar + nom + workout name + "il y a Xh" |
| PR Badge | Banner vert si nouveau record (exercice + valeur + gain) |
| Stats | Muscles • durée • volume • exercices |
| Top 3 | Chips avec nom exercice + poids×reps |
| Respect | Compteur + "Mike, Julie et X autres" + bouton respect |

**RespectButton** - Alternative au "like" :
- Icône : haltère (fitness_center)
- Animation : scale 1.0→1.3→1.0 + glow orange
- Haptic : mediumImpact au tap
- États : normal (gris) / respecté (fond orange)

**ActivityDetailSheet** :
- Header complet avec avatar 56px
- Stats grid (Durée/Volume/Exercices/Muscles)
- Liste complète des exercices
- Section respect avec noms

### Défis - Compétitions

**ChallengeCard** - Carte de défi :
| Section | Contenu |
|---------|---------|
| Header | Badge status (ACTIF/TERMINÉ/EXPIRÉ) + "Xj restants" |
| Titre | "100kg au bench" + exercice cible |
| Participants | Créateur + avatars empilés (+N) |
| Leaderboard | Top 3 avec 🥇🥈🥉 + % + valeur |
| Actions | "VOIR DÉTAILS" / "PARTICIPER" |

**ChallengeDetailSheet** :
- Progress ring 180px avec % leader
- Info : Objectif / Participants / Deadline
- Classement complet avec barres progression
- Bouton "PARTICIPER AU DÉFI"

**ParticipantAvatars** :
- Avatars empilés avec chevauchement 60%
- Maximum 3 visibles + "+N" si plus

### Création de Défi (FAB)

**CreateChallengeSheet** - Flow 4 étapes :

**Étape 1 - Type** :
| Type | Icône | Description |
|------|-------|-------------|
| Défi poids | fitness_center | Premier à X kg |
| Défi reps | repeat | Max reps à X kg |
| Défi temps | timer | Meilleur temps |
| Défi libre | edit_note | Description custom |

**Étape 2 - Configuration** :
- Dropdown sélection exercice (8 exercices principaux)
- Picker valeur cible avec +/- (±5)
- Date picker deadline (optionnel)

**Étape 3 - Invitations** :
- Liste amis avec recherche
- Multi-select avec checkboxes
- Status online (badge vert)
- Streak affiché 🔥

**Étape 4 - Confirmation** :
- Preview card avec récap complet
- Chips participants sélectionnés
- Bouton "LANCER LE DÉFI"

### Models

```dart
// Activity
Activity(
  id, userName, userAvatarUrl, workoutName, muscles,
  durationMinutes, volumeKg, exerciseCount, timestamp,
  topExercises: [ExerciseSummary],
  pr: PersonalRecord?,
  respectCount, hasGivenRespect, respectGivers
)

// Challenge
Challenge(
  id, title, exerciseName, type: ChallengeType,
  targetValue, unit, deadline?, status: ChallengeStatus,
  creatorId, creatorName,
  participants: [ChallengeParticipant]
)

// Friend
Friend(
  id, name, avatarUrl, isOnline, lastActive?,
  totalWorkouts, streak
)
```

### Structure fichiers

```
lib/features/social/
├── social_screen.dart              # Écran principal
├── models/
│   ├── activity.dart               # Activity, ExerciseSummary, PersonalRecord
│   ├── challenge.dart              # Challenge, ChallengeType, ChallengeStatus, ChallengeParticipant
│   └── friend.dart                 # Friend
├── widgets/
│   ├── activity_card.dart          # Carte séance
│   ├── challenge_card.dart         # Carte défi
│   ├── pr_badge.dart               # Badge PR vert
│   ├── respect_button.dart         # Bouton respect animé
│   └── participant_avatars.dart    # Avatars empilés
├── sheets/
│   ├── activity_detail_sheet.dart  # Détail séance
│   ├── challenge_detail_sheet.dart # Détail défi
│   ├── create_challenge_sheet.dart # Création défi (4 étapes)
│   └── friends_list_sheet.dart     # Sélection amis
└── painters/
    └── challenge_progress_painter.dart # Ring progression
```

### Animations & Effets

- Mesh gradient orange/violet (différent des autres écrans)
- RespectButton : scale + glow au tap
- Segmented control : transition couleur 200ms
- FAB : visible uniquement sur onglet Défis

---

## WorkoutHistoryScreen

Écran d'historique des séances d'entraînement.

### Accès
- Tap sur "Historique" dans WorkoutScreen (quick actions)
- Tap sur un item récent dans WorkoutScreen (filtré par type)

### Header
- Bouton retour
- Titre "Historique" + compteur séances
- Badge stat total volume

### Filtres
Chips horizontaux pour filtrer par type de session :
- Tout
- Push Day
- Pull Day
- Leg Day
- (autres types selon historique)

### Liste des séances
**WorkoutCard** pour chaque séance :
| Section | Contenu |
|---------|---------|
| Icône | Dépend du type (fitness_center/rowing/running) |
| Header | Nom session + badge PR si nouveau record |
| Date | Aujourd'hui / Hier / Lun 27 Jan |
| Stats | Timer durée + exercices + volume (formaté k) |

### Bottom Sheet Détail
Tap sur une carte ouvre un DraggableScrollableSheet :
- Header avec nom et date
- Stats grid : durée, exercices, volume, PRs
- Liste exercices avec sets×reps

---

## ProgramEditScreen

Écran d'édition d'un programme d'entraînement.

### Accès
- Tap sur "Modifier" dans WorkoutScreen (quick actions)

### Header
- Bouton fermer (X) avec confirmation si modifications
- Titre "Modifier programme"

### Contenu
**Nom du programme** :
- TextField glassmorphism

**Liste des séances** :
- ReorderableListView avec drag handles
- Chaque carte affiche :
  - Drag indicator
  - Nom + muscles
  - Preview 3 premiers exercices (bullet points)
  - "+N exercices" si plus de 3
  - Bouton éditer (icône edit)
  - Bouton supprimer (icône delete, rouge)

**Bouton ajouter séance** :
- Full width, style outline

### Footer
Bouton "Sauvegarder" :
- Inactif (gris) si pas de modifications
- Actif (accent + glow) si modifications

### Confirmation
Dialog si tentative de fermeture avec modifications non sauvegardées :
- "Abandonner les modifications ?"
- Boutons : Continuer / Abandonner

---

## PlaceholderSheet

Sheet réutilisable pour fonctionnalités "Coming soon".

### Utilisation
```dart
PlaceholderSheet.show(
  context,
  title: 'Apple Health',
  message: 'Synchronisation bientôt disponible.',
  icon: Icons.sync_outlined,
);
```

### Contenu
- Handle
- Icône dans cercle accent 15%
- Titre (h3)
- Message (body, secondary)
- Bouton "Compris"

---

## EditProfileSheet

Sheet pour modifier le profil utilisateur.

### Accès
- Tap sur l'icône crayon dans la carte profil (ProfileScreen)

### Contenu
**Avatar selector** :
- ListView horizontal de 8 emojis fitness
- Animation sélection avec bordure accent

**Champs** :
- Nom (TextField)
- Email (TextField)

**Actions** :
- Annuler (secondary)
- Sauvegarder (accent) → SnackBar confirmation

### Avatars disponibles
💪 🏋️ 🏃 🧘 🚴 ⚡ 🔥 🎯

---

## ExerciseProgressScreen

Écran de visualisation de la progression des poids sur un exercice.

### Accès
- Tap sur un badge PR dans les séances récentes (WorkoutScreen)

### Architecture
```
lib/features/workout/progress/
├── exercise_progress_screen.dart    # Écran principal
├── models/
│   └── exercise_history.dart        # Modèles + mock data
└── widgets/
    ├── progress_chart.dart          # CustomPainter graphique
    └── pr_history_list.dart         # Liste des PRs
```

### Header
| Élément | Description |
|---------|-------------|
| Bouton retour | Navigation pop |
| Nom exercice | Uppercase avec letterSpacing |
| Groupe musculaire | Caption secondary |
| Badge PR | Gradient doré avec icône trophée + poids actuel |

### Graphique de progression
**ProgressChart** - CustomPainter animé :
- **Axes** : Y (poids en kg), X (semaines S1-S7)
- **Grille** : Lignes horizontales avec labels
- **Courbe** : Ligne orange avec courbe de Bézier lisse
- **Gradient** : Zone sous la courbe avec gradient accent
- **Points normaux** : Cercles orange (6px) avec bordure background
- **Points PR** : Cercles dorés (7px) avec glow et bordure blanche
- **Animation** : Apparition progressive de gauche à droite (1.2s)

### Card stats progression
| Donnée | Format | Exemple |
|--------|--------|---------|
| Pourcentage | +X.X% depuis le début | +11.1% |
| Gain total | +Xkg en Y semaines | +10kg en 7 semaines |
| Icône | trending_up vert | - |

### Liste historique PRs (PRHistoryList)
Affiche uniquement les entrées marquées comme PR, triées par date décroissante.

**Chaque item** :
| Section | Contenu |
|---------|---------|
| Icône | Trophée dans carré (doré si plus récent, orange sinon) |
| Poids × Reps | "100kg × 5" en h3 (doré si plus récent) |
| Session | Nom de la séance en caption |
| Date | Badge avec date relative (Aujourd'hui, Hier, S1-S7) |

**Style item plus récent** :
- Fond doré 10%
- Bordure dorée 30%
- Textes en couleur dorée

### Modèles

```dart
// Entrée d'historique
class ExerciseProgressEntry {
  final DateTime date;
  final double weight;
  final int reps;
  final bool isPR;
  final String? sessionName;
}

// Historique complet
class ExerciseHistory {
  final String exerciseName;
  final String muscleGroup;
  final double currentPR;
  final List<ExerciseProgressEntry> entries;

  // Getters calculés
  double get progressPercentage;  // % gain depuis début
  double get totalGain;           // kg gagnés
  int get weeksOfProgress;        // semaines de données
  List<ExerciseProgressEntry> get prEntries;  // filtré PRs only
}
```

### Mock Data (MockExerciseData)
3 exercices avec historique 7 semaines :

| Exercice | Muscle | PR initial | PR actuel | Progression |
|----------|--------|------------|-----------|-------------|
| Bench Press | Pectoraux | 90kg | 100kg | +11.1% |
| Squat | Quadriceps | 120kg | 140kg | +16.7% |
| Deadlift | Dos | 140kg | 160kg | +14.3% |

### Animations & Effets
- **Fade-in** : Écran entier avec animation 600ms
- **Chart animation** : Progression linéaire 1.2s
- **Glow** : Points PR avec MaskFilter blur
- **Gradient background** : Orbe accent en haut à droite

### Navigation
```dart
// Depuis WorkoutScreen
void _openPRProgress(String exerciseName) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ExerciseProgressScreen(exerciseName: exerciseName),
      // slide from right transition
    ),
  );
}
```
