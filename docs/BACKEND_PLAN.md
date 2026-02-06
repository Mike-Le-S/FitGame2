# Backend Plan - FitGame2

> Plan simple pour connecter l'app au backend Supabase.
> On avance étape par étape, on coche au fur et à mesure.

---

## Vue d'ensemble

```
Phase 1: Setup Supabase     ✅ TERMINÉ
Phase 2: Authentification   ✅ TERMINÉ
Phase 3: Données Core       ✅ TERMINÉ
Phase 4: Sync Coach-Élève   ✅ TERMINÉ
Phase 5: Fonctions Avancées ← ON EST ICI
```

---

## Configuration Supabase

| Clé | Valeur |
|-----|--------|
| **Project ID** | `<SUPABASE_PROJECT_ID from .env>` |
| **URL** | `<SUPABASE_URL from .env>` |
| **Anon Key** | `<SUPABASE_ANON_KEY from .env>` |
| **Region** | `eu-west-1` (Ireland) |

---

## Phase 1: Setup Supabase ✅

**Objectif**: Avoir un projet Supabase avec les tables de base.

| # | Étape | Status |
|---|-------|--------|
| 1.1 | Créer le projet Supabase "FitGame" | ✅ |
| 1.2 | Créer la table `profiles` (utilisateurs) | ✅ |
| 1.3 | Créer la table `coaches` | ✅ |
| 1.4 | Créer la table `programs` | ✅ |
| 1.5 | Créer la table `diet_plans` | ✅ |
| 1.6 | Créer la table `workout_sessions` | ✅ |
| 1.7 | Configurer les relations entre tables | ✅ |
| 1.8 | Activer Row Level Security (RLS) | ✅ |

**Résultat**: Base de données prête, vide mais structurée. ✅ Terminé le 2026-02-01

---

## Phase 2: Authentification ✅

**Objectif**: Les users peuvent créer un compte et se connecter.

| # | Étape | Status |
|---|-------|--------|
| 2.1 | Ajouter Supabase Flutter SDK au projet mobile | ✅ |
| 2.2 | Configurer les clés API dans l'app mobile | ✅ |
| 2.3 | Créer écran Login/Register dans l'app mobile | ✅ |
| 2.4 | Connecter le login existant du Coach Web | ✅ |
| 2.5 | Tester: créer un compte, se connecter, se déconnecter | ⬜ Manuel |

**Résultat**: On peut créer un compte et se connecter sur mobile + web. ✅ Terminé le 2026-02-01

---

## Phase 3: Données Core ✅

**Objectif**: Sauvegarder et charger les vraies données.

| # | Étape | Status |
|---|-------|--------|
| 3.1 | Mobile: Sauvegarder un programme créé | ✅ |
| 3.2 | Mobile: Charger les programmes depuis Supabase | ✅ |
| 3.3 | Mobile: Sauvegarder une séance de workout | ✅ |
| 3.4 | Mobile: Sauvegarder un plan nutrition | ✅ |
| 3.5 | Web: Charger/sauvegarder programmes | ✅ |
| 3.6 | Web: Charger/sauvegarder plans nutrition | ✅ |
| 3.7 | Web: Charger/sauvegarder élèves | ✅ |
| 3.8 | Tester: créer sur web, voir sur mobile | ⬜ Manuel |

**Résultat**: Les données persistent et sont partagées. ✅ Terminé le 2026-02-01

---

## Phase 4: Sync Coach-Élève ✅

**Objectif**: Un coach peut gérer ses élèves.

| # | Étape | Status |
|---|-------|--------|
| 4.1 | Créer la relation coach ↔ élève dans la DB | ✅ (fait en Phase 1) |
| 4.2 | Coach: voir la liste de ses élèves | ✅ (coach-web) |
| 4.3 | Coach: assigner un programme à un élève | ✅ (modales existantes) |
| 4.4 | Coach: assigner un plan nutrition à un élève | ✅ (modales existantes) |
| 4.5 | Élève: voir les programmes/diètes assignés par son coach | ✅ (mobile) |
| 4.6 | Coach: voir les séances complétées par ses élèves | ✅ (coach-web) |

**Résultat**: Le système coach/élève fonctionne. ✅ Terminé le 2026-02-01

---

## Phase 5: Fonctions Avancées (optionnel)

**Objectif**: Les extras qui rendent l'app complète.

| # | Étape | Status |
|---|-------|--------|
| 5.1 | Messages temps réel coach ↔ élève | ✅ |
| 5.2 | Notifications push (browser) | ✅ |
| 5.3 | Intégration Apple Health | ✅ |
| 5.4 | Export PDF des programmes | ✅ |
| 5.5 | Historique et statistiques | ✅ |

---

## Schéma des Tables (Référence)

```
profiles (utilisateurs)
├── id (uuid, clé primaire)
├── email
├── full_name
├── avatar_url
├── role ('athlete' | 'coach')
├── coach_id (référence vers un coach, nullable)
└── created_at

coaches (infos supplémentaires coach)
├── id (uuid, = profile.id)
├── business_name
├── specialization
└── credentials

programs (programmes d'entraînement)
├── id
├── created_by (coach ou athlete)
├── name
├── description
├── goal
├── duration_weeks
├── days (JSON: liste des jours avec exercices)
└── created_at

diet_plans (plans nutrition)
├── id
├── created_by
├── name
├── goal
├── training_calories
├── rest_calories
├── macros (JSON)
├── meals (JSON)
└── created_at

workout_sessions (séances complétées)
├── id
├── user_id
├── program_id
├── day_name
├── exercises (JSON: poids, reps, sets réalisés)
├── duration_minutes
├── started_at
├── completed_at
└── notes

assignments (programmes/diètes assignés)
├── id
├── coach_id
├── student_id
├── program_id (nullable)
├── diet_plan_id (nullable)
├── assigned_at
└── status ('active' | 'completed' | 'paused')

messages (messagerie temps réel)
├── id
├── sender_id (référence vers profile)
├── receiver_id (référence vers profile)
├── content (text)
├── read_at (nullable)
└── created_at
```

---

## Notes

- **Vibecoding**: On fait une étape, on teste, on passe à la suivante
- **Pas de rush**: Si une étape coince, on debug avant de continuer
- **Mock data**: On garde les mocks comme fallback pendant le dev

---

## Historique

| Date | Phase | Description |
|------|-------|-------------|
| 2026-02-01 | Phase 1 | Setup Supabase - Tables créées |
| 2026-02-01 | Phase 2 | Auth mobile + coach-web |
| 2026-02-01 | Phase 3 | Sauvegarde programmes, séances, diètes |
| 2026-02-01 | Phase 4 | Sync coach-élève complet |
| 2026-02-01 | Phase 5.1 | Messages temps réel coach ↔ élève |
| 2026-02-01 | Phase 5.2 | Notifications browser (Web Notifications API) |
| 2026-02-01 | Phase 5.5 | Dashboard statistiques temps réel |
| 2026-02-01 | Phase 5.4 | Export PDF programmes et plans nutrition |
| 2026-02-01 | Phase 5.3 | Intégration Apple Health / Google Fit |

---

*Dernière mise à jour: 2026-02-01*
