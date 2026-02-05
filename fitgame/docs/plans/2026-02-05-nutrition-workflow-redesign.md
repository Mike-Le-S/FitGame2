# Nutrition Workflow Redesign

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:writing-plans to create the implementation plan from this design.

**Goal:** Simplifier le workflow Nutrition avec une séparation claire Plan (template) vs Vue quotidienne (tracking)

**Architecture:** Système de "types de jour" réutilisables assignés à chaque jour de la semaine. Le plan est un template fixe, la vue quotidienne permet des ajustements temporaires.

**Tech Stack:** Flutter/Dart, Supabase (PostgreSQL), HealthKit via health package

---

## 1. Architecture globale

```
┌─────────────────────────────────────────────────────┐
│  PLAN (master template)                             │
│  - Créé une fois, dure plusieurs semaines/mois      │
│  - Contient des "types de jour" (repos, muscu...)   │
│  - Chaque type a ses repas configurés               │
│  - Chaque jour de la semaine est assigné à un type  │
└─────────────────────────────────────────────────────┘
            ↓ génère automatiquement
┌─────────────────────────────────────────────────────┐
│  VUE DU JOUR (copie quotidienne)                    │
│  - Pré-remplie depuis le plan actif                 │
│  - Modifiable temporairement (juste aujourd'hui)    │
│  - Calcule le bilan calories vs Apple Santé         │
└─────────────────────────────────────────────────────┘
            ↓ sauvegarde dans
┌─────────────────────────────────────────────────────┐
│  HISTORIQUE (daily_nutrition_logs)                  │
│  - Ce qui a été réellement mangé chaque jour        │
│  - Permet de voir l'écart plan vs réel              │
└─────────────────────────────────────────────────────┘
```

**Règle clé:** Modifier un aliment dans la vue du jour = temporaire. Modifier le plan = permanent pour tous les jours futurs.

---

## 2. Écran Nutrition (vue quotidienne)

### Header simplifié

```
NUTRITION                    [Mon plan ▼]  [+]
Lundi 5 février
```

- **"Mon plan ▼"** → Ouvre le modal de gestion des plans
- **"+"** → Crée un nouveau plan (lance le flow 3 étapes)

### Corps de l'écran

- **Bilan du jour** (CalorieBalanceCard) → Consommé vs Brûlé (Apple Santé) + prédiction
- **Sélecteur de jour** → LUN MAR MER... (comme actuellement)
- **Repas du jour** → Pré-remplis depuis le plan, modifiables temporairement

### Comportement des repas

- Les repas affichent ce que le plan prévoit
- Clic sur un aliment → modifier quantité ou supprimer (temporaire)
- Clic "+" sur un repas → ajouter un aliment (temporaire)
- Badge discret si la quantité diffère du plan : `"120g (prévu: 150g)"`

### Sans plan actif

- Les repas sont vides
- Message : "Aucun plan actif. Créez un plan ou trackez manuellement."
- L'utilisateur peut quand même ajouter des aliments manuellement

---

## 3. Modal de gestion des plans

S'ouvre quand on clique sur "Mon plan ▼"

```
┌─────────────────────────────────────────┐
│  Mes plans                        [X]   │
├─────────────────────────────────────────┤
│                                         │
│  ✓ ACTIF                                │
│  ┌─────────────────────────────────┐    │
│  │ Prise de masse été              │    │
│  │ Bulk • 3200 kcal training       │    │
│  │           [Modifier] [Désactiver]│   │
│  └─────────────────────────────────┘    │
│                                         │
│  AUTRES PLANS                           │
│  ┌─────────────────────────────────┐    │
│  │ Sèche printemps                 │    │
│  │ Cut • 2000 kcal      [Activer]  │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ Vacances                        │    │
│  │ Maintien • 2500 kcal [Activer]  │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

### Actions

- **Modifier** → Ouvre l'écran d'édition du plan (3 étapes)
- **Désactiver** → Retire le plan actif (mode tracking manuel)
- **Activer** → Ouvre un mini-dialog pour choisir la date

### Dialog d'activation

```
┌────────────────────────────────┐
│  Activer "Sèche printemps"     │
├────────────────────────────────┤
│  À partir de :                 │
│                                │
│  ○ Maintenant                  │
│  ○ Demain                      │
│  ○ Le [____date picker____]    │
├────────────────────────────────┤
│    [Annuler]    [Confirmer]    │
└────────────────────────────────┘
```

---

## 4. Création/Édition de plan (3 étapes)

### Étape 1 : Infos générales

```
┌─────────────────────────────────────────┐
│  [←]              Étape 1/3             │
│  ━━━━━━━━━━━━━━━━━●○○                   │
├─────────────────────────────────────────┤
│                                         │
│  INFORMATIONS DU PLAN                   │
│                                         │
│  Nom du plan                            │
│  ┌─────────────────────────────────┐    │
│  │ Prise de masse été              │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Objectif                               │
│  [Prise ✓]  [Maintien]  [Sèche]        │
│                                         │
│  Calories cibles                        │
│  ┌──────────────┐ ┌──────────────┐     │
│  │ Training     │ │ Repos        │     │
│  │ 3200 kcal    │ │ 2800 kcal    │     │
│  └──────────────┘ └──────────────┘     │
│                                         │
├─────────────────────────────────────────┤
│            [Continuer]                  │
└─────────────────────────────────────────┘
```

### Étape 2 : Types de jour

```
┌─────────────────────────────────────────┐
│  [←]              Étape 2/3             │
│  ━━━━━━━━━━━━━━━━━━━━●○                 │
├─────────────────────────────────────────┤
│                                         │
│  MES TYPES DE JOUR                      │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 🏋️ Jour muscu          [Éditer] │   │
│  │ 4 repas • 3200 kcal             │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 😴 Jour repos          [Éditer] │   │
│  │ 4 repas • 2800 kcal             │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │       + Ajouter un type         │    │
│  └─────────────────────────────────┘    │
│                                         │
├─────────────────────────────────────────┤
│            [Continuer]                  │
└─────────────────────────────────────────┘
```

Quand on clique "Éditer" un type :
- Ouvre un écran avec les repas (Petit-déj, Déjeuner, Collation, Dîner)
- Ajout d'aliments via recherche / scanner / favoris
- Possibilité de renommer les repas ou en ajouter/supprimer

### Étape 3 : Planning semaine

```
┌─────────────────────────────────────────┐
│  [←]              Étape 3/3             │
│  ━━━━━━━━━━━━━━━━━━━━━━━●               │
├─────────────────────────────────────────┤
│                                         │
│  PLANNING DE LA SEMAINE                 │
│                                         │
│  Lundi      [Jour muscu ▼]              │
│  Mardi      [Jour repos ▼]              │
│  Mercredi   [Jour muscu ▼]              │
│  Jeudi      [Jour repos ▼]              │
│  Vendredi   [Jour muscu ▼]              │
│  Samedi     [Jour repos ▼]              │
│  Dimanche   [Jour repos ▼]              │
│                                         │
├─────────────────────────────────────────┤
│  [Passer]      [Créer le plan]          │
└─────────────────────────────────────────┘
```

Chaque dropdown liste les types de jour créés à l'étape 2.

---

## 5. Data model

### Tables Supabase

```sql
-- Table existante, modifiée
diet_plans
├── id UUID PRIMARY KEY
├── user_id UUID REFERENCES auth.users
├── name TEXT                    -- "Prise de masse été"
├── goal TEXT                    -- "bulk" | "cut" | "maintain"
├── training_calories INTEGER    -- 3200
├── rest_calories INTEGER        -- 2800
├── is_active BOOLEAN           -- un seul actif par user
├── active_from DATE            -- date de début d'activation
└── created_at TIMESTAMPTZ

-- NOUVELLE TABLE
day_types
├── id UUID PRIMARY KEY
├── diet_plan_id UUID REFERENCES diet_plans ON DELETE CASCADE
├── name TEXT                   -- "Jour muscu"
├── emoji TEXT                  -- "🏋️"
├── meals JSONB                 -- array des repas avec aliments
└── sort_order INTEGER          -- pour l'affichage

-- NOUVELLE TABLE
weekly_schedule
├── id UUID PRIMARY KEY
├── diet_plan_id UUID REFERENCES diet_plans ON DELETE CASCADE
├── day_of_week INTEGER         -- 0-6 (lundi-dimanche)
└── day_type_id UUID REFERENCES day_types

-- Table existante, inchangée
daily_nutrition_logs
├── id UUID PRIMARY KEY
├── user_id UUID REFERENCES auth.users
├── date DATE
├── diet_plan_id UUID           -- quel plan était actif ce jour
├── meals JSONB                 -- ce qui a été réellement mangé
├── calories_consumed INTEGER
└── calories_burned INTEGER
```

### Flow de données

1. User ouvre l'app → Récupère le `diet_plan` actif (`is_active = true`)
2. Récupère le `day_type` assigné à aujourd'hui via `weekly_schedule`
3. Affiche les repas du `day_type`
4. Si l'user modifie → Sauvegarde dans `daily_nutrition_logs` (pas dans le plan)

---

## 6. Changements par rapport à l'existant

### Ce qu'on garde

- L'écran Nutrition actuel (vue quotidienne avec repas)
- Le système de favoris, scanner, templates pour ajouter des aliments
- Le CalorieBalanceCard avec Apple Santé
- Les daily_nutrition_logs pour l'historique

### Ce qu'on change

- Header simplifié : `[Mon plan ▼]` remplace le sélecteur bulk/cut/maintain
- Nouveau modal de gestion des plans (activer, modifier, désactiver)
- Activation de plan avec choix de date
- Flow de création en 3 étapes (infos → types de jour → planning semaine)
- Nouveau concept de "types de jour" (templates réutilisables)

### Ce qu'on supprime

- Le flow 8 étapes actuel `DietCreationFlow` (trop lourd)
- Les macros en pourcentage (simplifié en calories uniquement)
- Les suppléments dans le flow de création (feature secondaire)
- Le toggle `_isTrackingMode` (plus nécessaire, la logique est claire)
- `_weeklyPlan` local (remplacé par day_types + weekly_schedule en DB)

---

## 7. Fichiers impactés

### À modifier

- `lib/features/nutrition/nutrition_screen.dart` - Header, logique de chargement
- `lib/core/services/supabase_service.dart` - Nouvelles méthodes CRUD

### À créer

- `lib/features/nutrition/sheets/plans_modal_sheet.dart` - Modal gestion des plans
- `lib/features/nutrition/sheets/activate_plan_sheet.dart` - Dialog activation avec date
- `lib/features/nutrition/create/plan_creation_flow.dart` - Nouveau flow 3 étapes
- `lib/features/nutrition/create/steps/plan_info_step.dart` - Étape 1
- `lib/features/nutrition/create/steps/day_types_step.dart` - Étape 2
- `lib/features/nutrition/create/steps/weekly_schedule_step.dart` - Étape 3
- `lib/features/nutrition/create/day_type_editor_screen.dart` - Édition d'un type de jour
- Migration Supabase pour `day_types` et `weekly_schedule`

### À supprimer

- `lib/features/nutrition/create/steps/name_step.dart`
- `lib/features/nutrition/create/steps/goal_step.dart`
- `lib/features/nutrition/create/steps/calories_step.dart`
- `lib/features/nutrition/create/steps/macros_step.dart`
- `lib/features/nutrition/create/steps/meals_step.dart`
- `lib/features/nutrition/create/steps/meal_names_step.dart`
- `lib/features/nutrition/create/steps/meal_planning_step.dart`
- `lib/features/nutrition/create/steps/supplements_step.dart`
- (ou les garder temporairement et migrer progressivement)
