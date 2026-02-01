# Architecture FitGame2

Documentation unifiée pour le développement backend. Ce fichier décrit les modèles de données partagés entre l'app mobile (FitGame) et le portail coach (Coach-Web).

## Vue d'ensemble système

```
┌─────────────────────────┐       ┌─────────────────────────┐
│      FitGame App        │       │      Coach Portal       │
│       (Flutter)         │       │        (React)          │
│                         │       │                         │
│  • 6 onglets principaux │       │  • 13 pages             │
│  • Athletes/Utilisateurs│       │  • Coachs               │
│  • Tracking en temps réel│      │  • Gestion clients      │
│  • Données santé        │       │  • Création programmes  │
└───────────┬─────────────┘       └───────────┬─────────────┘
            │                                 │
            └──────────────┬──────────────────┘
                           │
                    ┌──────▼──────┐
                    │   Backend   │
                    │    (API)    │
                    │             │
                    │  PostgreSQL │
                    │  (M1 Server)│
                    └─────────────┘
```

## Rôles utilisateurs

| Rôle | App | Description |
|------|-----|-------------|
| **Athlete** | FitGame Mobile | Utilisateur final qui s'entraîne, suit sa nutrition et sa santé |
| **Coach** | Coach-Web | Professionnel qui gère ses clients, crée des programmes et suit leur progression |

Un coach peut aussi être athlete (utiliser l'app mobile pour son propre entraînement).

---

## Modèles de données partagés

### Mapping des entités

| Entité Backend | FitGame (Dart) | Coach-Web (TS) | Description |
|----------------|----------------|----------------|-------------|
| `users` | - | `Student` | Athlètes/clients |
| `coaches` | - | `Coach` | Coachs avec leurs credentials |
| `programs` | `Exercise`, `WorkoutSet`, `WorkoutDay` | `Program`, `Exercise` | Programmes d'entraînement |
| `program_assignments` | - | `ProgramAssignment` | Attribution programme → client |
| `nutrition_plans` | `MealPlan`, `FoodEntry` | `DietPlan`, `MealPlan` | Plans nutritionnels |
| `diet_assignments` | - | `DietAssignment` | Attribution diète → client |
| `workout_sessions` | - | `WorkoutSession` | Séances réalisées |
| `calendar_events` | - | `CalendarEvent` | Événements (séances, RDV, notes) |
| `messages` | - | `Message`, `Conversation` | Messagerie coach ↔ client |
| `health_metrics` | `SleepData`, `HeartData` | - | Données santé (sommeil, cœur, activité) |
| `achievements` | `Achievement` | - | Badges et accomplissements |
| `challenges` | `Challenge` | - | Défis sociaux entre utilisateurs |

---

## Schémas détaillés

### User (Athlete)

```typescript
interface User {
  id: string;
  email: string;
  name: string;
  avatar_url?: string;

  // Stats
  total_sessions: number;
  current_streak: number;
  member_since: Date;

  // Préférences
  weight_unit: 'kg' | 'lbs';
  language: 'fr' | 'en';
  notifications_enabled: boolean;

  // Relations
  coach_id?: string;  // Coach assigné (si applicable)

  created_at: Date;
  updated_at: Date;
}
```

### Coach

```typescript
interface Coach {
  id: string;
  email: string;
  name: string;
  avatar_url?: string;

  // Business
  business_name?: string;
  specialty?: string;  // Force, Nutrition, etc.

  // Settings
  two_factor_enabled: boolean;
  theme: 'dark' | 'light' | 'auto';
  accent_color: string;  // Hex color

  created_at: Date;
  updated_at: Date;
}
```

### Program

```typescript
interface Program {
  id: string;
  coach_id: string;
  name: string;
  description?: string;

  // Configuration
  is_cycled: boolean;
  cycle_weeks?: number;        // Si cyclé: durée totale
  deload_enabled: boolean;
  deload_frequency?: number;   // Deload après X semaines
  deload_reduction?: number;   // % réduction poids

  // Contenu
  days: WorkoutDay[];

  // Metadata
  created_at: Date;
  updated_at: Date;
}

interface WorkoutDay {
  id: string;
  program_id: string;
  day_of_week: 0 | 1 | 2 | 3 | 4 | 5 | 6;  // 0=Lundi
  name: string;  // "Push Day", "Leg Day"

  exercises: ProgramExercise[];
  order: number;
}

interface ProgramExercise {
  id: string;
  workout_day_id: string;
  exercise_id: string;  // Référence au catalogue

  // Configuration
  mode: 'classic' | 'rpt' | 'pyramidal' | 'dropset';
  sets: number;
  reps: number;
  warmup_enabled: boolean;

  // Superset
  superset_group?: number;  // null = pas de superset

  order: number;
}

interface Exercise {
  id: string;
  name: string;
  muscle_group: string;  // Pectoraux, Dos, Épaules, etc.
  is_custom: boolean;
  coach_id?: string;  // Si custom, créé par ce coach
}
```

### NutritionPlan

```typescript
interface NutritionPlan {
  id: string;
  coach_id: string;
  name: string;

  // Objectif
  goal_type: 'bulk' | 'cut' | 'maintain';

  // Calories
  training_calories: number;
  rest_calories: number;

  // Macros (pourcentages)
  protein_percent: number;
  carbs_percent: number;
  fat_percent: number;

  // Repas
  meals_per_day: number;
  meals: MealTemplate[];

  // Compléments
  supplements: SupplementEntry[];

  created_at: Date;
  updated_at: Date;
}

interface MealTemplate {
  id: string;
  nutrition_plan_id: string;
  name: string;
  icon: string;  // sun, restaurant, apple, moon
  order: number;

  // Foods pour jours training
  training_foods: FoodEntry[];
  // Foods pour jours repos
  rest_foods: FoodEntry[];
}

interface FoodEntry {
  id: string;
  food_id: string;  // Référence à la base d'aliments
  quantity: number;
  unit: string;  // g, ml, portion
}

interface SupplementEntry {
  id: string;
  name: string;
  dosage: string;
  timing: 'morning' | 'pre_workout' | 'post_workout' | 'evening' | 'with_meal';
  reminder_enabled: boolean;
  reminder_time?: string;  // HH:mm
}
```

### WorkoutSession (séance réalisée)

```typescript
interface WorkoutSession {
  id: string;
  user_id: string;
  program_id?: string;
  workout_day_id?: string;

  // Timing
  started_at: Date;
  completed_at?: Date;
  duration_minutes: number;

  // Stats
  total_volume_kg: number;
  total_sets: number;
  calories_burned: number;

  // Détails
  exercises: SessionExercise[];

  // PRs réalisés
  personal_records: PersonalRecord[];
}

interface SessionExercise {
  id: string;
  session_id: string;
  exercise_id: string;
  order: number;

  sets: SessionSet[];
}

interface SessionSet {
  id: string;
  session_exercise_id: string;
  set_number: number;
  is_warmup: boolean;

  weight_kg: number;
  reps: number;
  completed: boolean;

  // RPE optionnel
  rpe?: number;
}

interface PersonalRecord {
  id: string;
  user_id: string;
  exercise_id: string;
  session_id: string;

  weight_kg: number;
  reps: number;
  achieved_at: Date;
}
```

### HealthMetrics

```typescript
interface HealthMetric {
  id: string;
  user_id: string;
  date: Date;

  // Sommeil
  sleep_duration_minutes?: number;
  sleep_efficiency?: number;  // 0-100%
  deep_sleep_percent?: number;
  core_sleep_percent?: number;
  rem_sleep_percent?: number;
  awake_percent?: number;
  sleep_latency_minutes?: number;

  // Cœur
  resting_hr?: number;
  hrv?: number;
  vo2_max?: number;

  // Activité
  steps?: number;
  active_calories?: number;
  distance_km?: number;

  // Score global calculé
  health_score?: number;  // 0-100

  source: 'apple_health' | 'google_fit' | 'manual';
  synced_at: Date;
}
```

### CalendarEvent

```typescript
interface CalendarEvent {
  id: string;
  coach_id: string;
  student_id?: string;  // null = événement personnel coach

  title: string;
  description?: string;
  type: 'session' | 'appointment' | 'note' | 'holiday';

  start_time: Date;
  end_time?: Date;
  all_day: boolean;

  // Récurrence
  recurring: boolean;
  recurrence_rule?: string;  // RRULE format

  // Statut
  status: 'scheduled' | 'completed' | 'cancelled';

  created_at: Date;
  updated_at: Date;
}
```

### Message

```typescript
interface Conversation {
  id: string;
  coach_id: string;
  student_id: string;

  last_message_at: Date;
  unread_count_coach: number;
  unread_count_student: number;
}

interface Message {
  id: string;
  conversation_id: string;
  sender_type: 'coach' | 'student';
  sender_id: string;

  content: string;

  // Attachments optionnels
  attachment_type?: 'image' | 'file' | 'workout' | 'nutrition';
  attachment_id?: string;

  read_at?: Date;
  created_at: Date;
}
```

### Challenge (Social)

```typescript
interface Challenge {
  id: string;
  creator_id: string;

  title: string;
  type: 'weight' | 'reps' | 'time' | 'custom';
  exercise_id?: string;
  target_value: number;
  unit: string;

  deadline?: Date;
  status: 'active' | 'completed' | 'expired';

  participants: ChallengeParticipant[];

  created_at: Date;
}

interface ChallengeParticipant {
  id: string;
  challenge_id: string;
  user_id: string;

  current_value: number;
  best_value: number;
  progress_percent: number;

  joined_at: Date;
  last_updated: Date;
}
```

---

## API Endpoints

### FitGame Mobile (Athletes)

```
# Auth
POST   /auth/login              # Connexion
POST   /auth/register           # Inscription
POST   /auth/refresh            # Refresh token
POST   /auth/logout             # Déconnexion

# Profil
GET    /users/me                # Profil utilisateur
PATCH  /users/me                # Mise à jour profil
GET    /users/me/stats          # Stats globales (séances, streak, etc.)

# Programmes
GET    /programs/assigned       # Programmes assignés par le coach
GET    /programs/:id            # Détail d'un programme
GET    /programs/:id/next       # Prochaine séance à faire

# Sessions
POST   /sessions                # Démarrer une séance
PATCH  /sessions/:id            # Mettre à jour (sets validés)
POST   /sessions/:id/complete   # Terminer la séance
GET    /sessions/history        # Historique des séances

# PRs
GET    /prs                     # Tous les records personnels
GET    /prs/:exercise_id        # Historique PRs d'un exercice

# Nutrition
GET    /nutrition/today         # Plan du jour
GET    /nutrition/week          # Plan de la semaine
PATCH  /nutrition/day/:date     # Modifier aliments d'un jour

# Santé
POST   /health/sync             # Sync Apple Health / Google Fit
GET    /health/today            # Métriques du jour
GET    /health/history          # Historique 7/14/30 jours

# Social
GET    /social/feed             # Activité des amis
POST   /social/respect/:id      # Donner un respect
GET    /challenges              # Défis actifs
POST   /challenges              # Créer un défi
POST   /challenges/:id/join     # Rejoindre un défi
PATCH  /challenges/:id/progress # Mettre à jour progression

# Notifications
GET    /notifications           # Liste notifications
PATCH  /notifications/:id/read  # Marquer comme lue
```

### Coach-Web (Coachs)

```
# Auth
POST   /auth/coach/login        # Connexion coach
POST   /auth/coach/2fa/setup    # Configurer 2FA
POST   /auth/coach/2fa/verify   # Vérifier code 2FA

# Dashboard
GET    /dashboard/stats         # Stats globales (clients actifs, séances cette semaine)
GET    /dashboard/recent        # Activité récente

# Étudiants/Clients
GET    /students                # Liste clients
POST   /students                # Ajouter un client
GET    /students/:id            # Profil complet client
PATCH  /students/:id            # Modifier infos client
DELETE /students/:id            # Supprimer un client
GET    /students/:id/sessions   # Historique séances client
GET    /students/:id/progress   # Progression (graphiques)

# Programmes
GET    /programs                # Liste programmes créés
POST   /programs                # Créer un programme
GET    /programs/:id            # Détail programme
PATCH  /programs/:id            # Modifier programme
DELETE /programs/:id            # Supprimer programme
POST   /programs/:id/duplicate  # Dupliquer programme

# Assignations programmes
POST   /programs/:id/assign     # Assigner à un client
DELETE /programs/:id/unassign/:student_id  # Retirer assignation

# Nutrition
GET    /nutrition-plans         # Liste plans nutrition
POST   /nutrition-plans         # Créer plan
GET    /nutrition-plans/:id     # Détail plan
PATCH  /nutrition-plans/:id     # Modifier plan
DELETE /nutrition-plans/:id     # Supprimer plan

# Assignations nutrition
POST   /nutrition-plans/:id/assign     # Assigner à un client
DELETE /nutrition-plans/:id/unassign/:student_id

# Calendrier
GET    /calendar/events         # Événements (filtrable par date range)
POST   /calendar/events         # Créer événement
PATCH  /calendar/events/:id     # Modifier événement
DELETE /calendar/events/:id     # Supprimer événement

# Messagerie
GET    /conversations           # Liste conversations
GET    /conversations/:id       # Messages d'une conversation
POST   /conversations/:id/messages  # Envoyer message
PATCH  /messages/:id/read       # Marquer comme lu

# Settings
GET    /settings                # Paramètres coach
PATCH  /settings                # Modifier paramètres
```

---

## Relations clés

```
Coach (1) ────────< (N) Student
  │                      │
  │                      │
  ├──< Program           ├──< WorkoutSession
  │     │                │
  │     └──< ProgramExercise
  │                      │
  ├──< NutritionPlan     ├──< HealthMetric
  │                      │
  ├──< CalendarEvent     └──< PersonalRecord
  │
  └──< Message

Student (N) >────< (N) Program  (via program_assignments)
Student (N) >────< (N) NutritionPlan  (via diet_assignments)
Student (N) >────< (N) Challenge  (via challenge_participants)
```

---

## Flux de données typiques

### 1. Séance d'entraînement (FitGame)

```
1. GET /programs/assigned → Liste programmes
2. GET /programs/:id/next → Prochaine séance
3. POST /sessions → Démarrer (session_id)
4. PATCH /sessions/:id → Valider chaque série
5. POST /sessions/:id/complete → Terminer
   → Backend calcule: volume, calories, PRs
   → Notifications push aux amis (nouveau respect disponible)
```

### 2. Création programme (Coach-Web)

```
1. POST /programs → Créer programme vide
2. PATCH /programs/:id → Ajouter jours/exercices
3. POST /programs/:id/assign → Assigner au client
   → Notification push au client
   → Visible dans GET /programs/assigned côté mobile
```

### 3. Sync santé (FitGame)

```
1. App récupère données Apple Health / Google Fit
2. POST /health/sync → Envoie batch de métriques
   → Backend calcule health_score
   → Disponible dans dashboard coach
```

---

## Documentation détaillée

| Sujet | Fichier |
|-------|---------|
| Écrans FitGame Mobile | `fitgame/docs/SCREENS.md` |
| Historique FitGame | `fitgame/docs/CHANGELOG.md` |
| Architecture Coach-Web | `coach-web/CLAUDE.md` |
| Instructions générales | `CLAUDE.md` (racine) |

---

## Notes techniques

### Base de données
- PostgreSQL sur M1 Server (`192.168.1.26`)
- Pas de DB locale (tout via API)

### Authentification
- JWT avec refresh tokens
- 2FA optionnel pour les coachs
- Sessions persistées côté mobile

### Temps réel
- WebSockets pour:
  - Notifications push
  - Messagerie instantanée
  - Sync position séance (coach peut suivre en direct)

### Fichiers / Media
- Avatars: S3 ou équivalent
- Pièces jointes messages: même stockage
- Limites: 5MB images, 10MB fichiers
