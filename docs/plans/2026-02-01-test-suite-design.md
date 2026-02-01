# FitGame2 - Test Suite Design

> Date: 2026-02-01
> Status: Approved
> Total Tests: ~230

## Overview

Suite de tests exhaustive couvrant l'application mobile Flutter, le portail coach React, et l'intégration Supabase avec vraie base de données.

## Structure des dossiers

```
fitgame/test/
├── unit/                          # Tests unitaires
│   ├── models/                    # Models Dart
│   ├── services/                  # SupabaseService, HealthService
│   └── utils/                     # ExerciseCalculator, etc.
├── widget/                        # Tests de widgets Flutter
│   ├── features/                  # Par feature (home, workout, etc.)
│   └── shared/                    # FGGlassCard, FGNeonButton
└── integration/                   # Tests avec vraie DB
    └── supabase/                  # CRUD complet sur chaque table

coach-web/src/__tests__/
├── unit/                          # Tests unitaires
│   ├── stores/                    # Zustand stores
│   ├── lib/                       # Utils, services
│   └── types/                     # Type validations
├── components/                    # React Testing Library
│   ├── ui/                        # Composants de base
│   ├── modals/                    # Modales
│   └── pages/                     # Pages complètes
└── integration/                   # Tests avec vraie DB
    └── api/                       # Appels Supabase réels
```

## Tests Unitaires Flutter (~60 tests)

### Models (14 tests)
- `Exercise` : création, toJson/fromJson, validation champs requis
- `WorkoutSet` : création, calcul volume (weight × reps), état completed
- `DietModels` : FoodEntry calories, MealPlan totaux macros, DietPlan validation
- `Activity/Challenge/Friend` : sérialisation, états

### Services avec Mocks (25 tests)
- `SupabaseService` : Chaque méthode testée avec mock client
  - Auth : signUp, signIn, signOut, getCurrentProfile
  - Programs : CRUD complet (get, create, update, delete)
  - WorkoutSessions : start, complete, getHistory
  - DietPlans : CRUD complet
  - Assignments : get, realtime listeners

- `HealthService` : Mock du package health
  - requestAuthorization, getSleepData, getActivityData, getHeartData
  - Calculs de scores (sleep score, energy score)

### Utilities (12 tests)
- `ExerciseCalculator` : getModeLabel, getWarmupDescription, calculateSets pour chaque mode
- `ExerciseCatalog` : recherche par nom, filtrage par muscle group
- `Spacing` : valeurs correctes (xs=4, sm=8, md=16, lg=24, xl=32, xxl=48)

### Painters (9 tests)
- Chaque painter : constructeur, paint() ne crash pas, dimensions correctes

## Tests Unitaires Coach-Web (~50 tests)

### Zustand Stores (32 tests)
4 tests par store × 8 stores:
- `auth-store` : login, logout, checkSession, état initial
- `students-store` : fetchStudents, addStudent, editStudent, deleteStudent
- `programs-store` : CRUD + assignProgram, getExerciseCatalog
- `nutrition-store` : CRUD diet plans + assignDietPlan
- `events-store` : CRUD events
- `messages-store` : fetchConversations, sendMessage, markAsRead
- `stats-store` : fetchStudentStats, fetchCoachStats
- `settings-store` : updateTheme, updateLanguage, persist/hydrate

### Lib/Utils (12 tests)
- `utils.ts` : cn() merge classes, formatDate, formatTime, formatRelativeTime, generateId
- `notifications.ts` : isSupported, requestPermission, show
- `pdf-export.ts` : exportProgramToPDF génère blob valide

### Types (6 tests)
- Validation des types TypeScript avec helpers runtime
- Vérifier correspondance interfaces/réponses Supabase

## Tests de Composants React (~40 tests)

### UI primitifs (10 tests)
- Button : variants, disabled, onClick
- Input : value, onChange, placeholder, error state
- Card, Avatar, Badge : rendu correct

### Modals (18 tests)
2 tests par modal (ouverture/fermeture, soumission):
- AddStudentModal, EditStudentModal, AssignProgramModal
- AssignDietModal, CreateEventModal, SessionDetailModal
- ForgotPasswordModal, Setup2FAModal

### Pages (12 tests)
- LoginPage : formulaire, validation, redirect
- DashboardPage : stats, liste étudiants
- StudentsListPage : liste, filtres
- ProgramsListPage : programmes, actions CRUD

## Tests d'Intégration Supabase (~30 tests)

### Configuration
- Utilisateur de test : `test-runner@fitgame.test`
- Cleanup automatique après chaque test
- Variables d'environnement séparées

### Auth (4 tests)
- signUp crée profil dans `profiles`
- signIn retourne session valide
- signOut invalide la session
- getCurrentProfile retourne les bonnes données

### Programs CRUD (6 tests)
- createProgram insère avec bon `created_by`
- getPrograms retourne uniquement programmes du user
- getProgram par ID
- updateProgram modifie les champs
- deleteProgram supprime
- getAssignedPrograms via `assignments`

### WorkoutSessions (5 tests)
- startWorkoutSession crée avec `started_at`
- completeWorkoutSession ajoute stats
- getWorkoutSessions filtre par user/program
- getExerciseHistory extrait historique
- deleteWorkoutSession supprime

### DietPlans CRUD (5 tests)
- Même pattern que Programs

### Assignments & Realtime (5 tests)
- getAssignments avec relations jointes
- Coach assigne → apparaît chez élève
- Realtime INSERT déclenche callback
- Realtime UPDATE déclenche callback
- getCoachInfo retourne profil coach

### Messages (5 tests)
- Envoi message insère
- Lecture par conversation
- markAsRead met à jour `read_at`

## Tests de Widgets Flutter (~50 tests)

### Shared Widgets (6 tests)
- `FGGlassCard` : rendu, child, styles
- `FGNeonButton` : rendu, onPressed, disabled
- `PlaceholderSheet` : message correct

### Home Feature (8 tests)
- `HomeScreen` : header, stats, workout card
- `HomeHeader` : nom, streak
- `QuickStatsRow` : 3 stats
- `TodayWorkoutCard` : programme, durée, bouton

### Workout Feature (12 tests)
- `WorkoutScreen` : liste programmes
- `ActiveWorkoutScreen` : navigation, timer
- `SetCard` : input, compléter
- `RestTimerView` : countdown
- `PRCelebration` : animation

### Nutrition Feature (8 tests)
- `NutritionScreen` : jours, toggle
- `MacroDashboard` : calories, macros
- `MealCard` : aliments, bouton

### Health Feature (6 tests)
- `HealthScreen` : 3 sections
- `SleepDetailSheet` : métriques
- Gauges : rendu

### Social & Profile (10 tests)
- `SocialScreen` : feed, défis
- `ProfileScreen` : infos, settings

## Résumé

| Catégorie | Tests | Plateforme |
|-----------|-------|------------|
| Unit Flutter | 60 | Mobile |
| Widget Flutter | 50 | Mobile |
| Unit Coach-Web | 50 | Web |
| Component React | 40 | Web |
| Intégration Supabase | 30 | Shared |
| **TOTAL** | **230** | |
