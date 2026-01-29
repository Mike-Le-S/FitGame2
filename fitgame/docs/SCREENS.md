# Écrans FitGame

| Écran | Fichier | Status | Description |
|-------|---------|--------|-------------|
| HomeScreen | `lib/features/home/home_screen.dart` | ✅ | Écran d'accueil principal avec salutation, niveau, stats, séance suggérée |
| WorkoutScreen | `lib/features/workout/workout_screen.dart` | ✅ | Interface épurée : prochaine séance, progression programme, activité récente, actions rapides, bouton "+" |
| MainNavigation | `lib/main.dart` | ✅ | Shell de navigation avec bottom nav bar (Accueil, Entraînement, Nutrition, Santé, Profil) |
| NutritionScreen | `lib/features/nutrition/nutrition_screen.dart` | ✅ | Planificateur diète hebdomadaire avec macros, repas et génération IA |
| HealthScreen | `lib/features/health/health_screen.dart` | ✅ | Écran santé avec 3 cartes expandables (Énergie, Sommeil, Cœur) + bottom sheets détaillés |
| ProfileScreen | `lib/features/profile/profile_screen.dart` | ✅ | Écran profil avec réglages notifications, préférences app, liens utiles |
| CreateChoiceScreen | `lib/features/workout/create/create_choice_screen.dart` | ✅ | Choix initial : créer programme ou séance unique |
| ProgramCreationFlow | `lib/features/workout/create/program_creation_flow.dart` | ✅ | Flow multi-étapes création programme (nom, durée, jours, exercices) - Refactorisé en 15 sous-fichiers |
| SessionCreationScreen | `lib/features/workout/create/session_creation_screen.dart` | ✅ | Création rapide séance unique avec sélection exercices |
| ActiveWorkoutScreen | `lib/features/workout/tracking/active_workout_screen.dart` | ✅ | Tracking workout en temps réel avec timer repos, validation séries, célébration PR |

## Détail HealthScreen

### Cartes principales (page santé)
- **Énergie** : Consommé/Dépensé/Déficit avec chevron → ouvre bottom sheet détail
- **Sommeil** : Durée totale + score + aperçu phases → ouvre bottom sheet avec jauges
- **Cœur** : FC repos/moyenne/VFC + badge status → ouvre bottom sheet détail

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
- **Bouton IA** : Icône sparkle orange avec glow → génère un plan semaine

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

### Bottom Sheet Bibliothèque (FoodLibrarySheet)
DraggableScrollableSheet avec :
- **Header** : Titre + bouton scanner + bouton créer aliment
- **Recherche** : Champ texte avec icône loupe
- **Filtres** : Chips catégories (Tous, Récents, Favoris, Protéines, Glucides, Légumes, Fruits, Laitiers)
- **Liste aliments** : Cards avec nom, unité, calories, macros colorés, bouton +

### Bottom Sheet Édition Aliment (EditFoodSheet)
- **Nom et quantité** de l'aliment
- **Slider quantité** : 0.25x à 3x
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
