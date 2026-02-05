# Changelog FitGame

## 2026-02-05 - Redesign du workflow Nutrition (Phase 2)

### Nouveau système de Plans avec Types de Jour

#### Nouvelles tables Supabase
- **day_types** : Types de jour réutilisables (Jour muscu, Jour repos, etc.)
  - `name`, `emoji`, `meals` (JSONB), `sort_order`
  - Chaque type contient ses repas configurés
- **weekly_schedule** : Planning semaine
  - Assigne un type de jour à chaque jour de la semaine
- **diet_plans** : Colonnes ajoutées
  - `is_active` : Un seul plan actif par utilisateur
  - `active_from` : Date de début d'activation

#### PlanCreationFlow (create/plan_creation_flow.dart)
- **Nouveau wizard 3 étapes** remplace l'ancien flow 8 étapes
- Étape 1 : Infos du plan (nom, objectif, calories training/repos)
- Étape 2 : Types de jour (créer, éditer, supprimer des types)
- Étape 3 : Planning semaine (assigner types aux jours)
- Éditeur intégré pour configurer les repas de chaque type

#### PlansModalSheet (sheets/plans_modal_sheet.dart)
- **Nouveau modal** : Gestion des plans
- Affiche le plan actif et les autres plans
- Actions : Modifier, Activer, Désactiver
- Dialog d'activation avec choix de date (Maintenant, Demain, Date personnalisée)

#### NutritionScreen Header
- **Nouveau bouton "Mon plan"** remplace le sélecteur d'objectif
- Affiche si un plan est actif ou non
- Ouvre le PlansModalSheet au tap
- Bouton "+" ouvre directement le PlanCreationFlow

#### SupabaseService - Nouvelles méthodes
- `getActiveDietPlan()` : Récupère le plan actif
- `activateDietPlan(planId, activeFrom)` : Active un plan
- `deactivateAllDietPlans()` : Désactive tous les plans
- `getDayTypes(planId)` : Liste des types de jour
- `createDayType()`, `updateDayType()`, `deleteDayType()`
- `getWeeklySchedule(planId)` : Planning semaine
- `getDayTypeForWeekday(planId, dayOfWeek)` : Type du jour
- `setWeeklySchedule(planId, schedule)` : Définir le planning

#### Concept clé : Plan = Template, Tracking = Quotidien
- Le Plan est un template qui dure des semaines/mois
- Modifications dans la vue quotidienne = temporaires (daily_nutrition_logs)
- Modifications du plan = permanentes pour tous les jours futurs

---

## 2026-02-05 - Upgrade majeure de l'écran Nutrition

### A) Bilan Calories (consommé vs brûlé)

#### CalorieBalanceCard (widgets/calorie_balance_card.dart)
- **Nouveau widget** : Affiche le bilan calorique du jour
- Calories consommées (depuis les repas)
- Calories brûlées (depuis Apple Santé)
- Balance avec code couleur selon l'objectif :
  - Cut : vert si déficit, orange si surplus
  - Bulk : orange si déficit, vert si surplus
  - Maintain : vert si dans les ±200 kcal
- Prédiction fin de journée basée sur l'historique 7 jours
- Barre de progression vers l'objectif calorique

#### HealthService (core/services/health_service.dart)
- `getCaloriesHistory(days)` : Historique des calories brûlées
- `predictDailyCalories()` : Prédiction basée sur le taux de burn actuel

### B) Plan vs Tracking (séparation template/tracking)

#### NutritionScreen (nutrition_screen.dart)
- **Nouveau concept** : Séparation entre Plan (template) et Tracking (journalier)
- Le Plan reste intact, les modifications quotidiennes vont dans le tracking
- Affichage "120g / 150g prévu" quand quantité modifiée

#### daily_nutrition_logs (nouvelle table Supabase)
- Stocke ce que l'utilisateur a réellement mangé chaque jour
- Lié au plan actif mais indépendant

### C) Ajout d'aliments rapide

#### FoodAddSheet (sheets/food_add_sheet.dart)
- **Nouveau sheet** : Interface principale d'ajout d'aliments
- Barre de recherche
- Boutons rapides : Scanner, Favoris, Templates
- Liste des aliments récents

#### BarcodeScannerSheet (sheets/barcode_scanner_sheet.dart)
- **Nouveau sheet** : Scanner de codes-barres
- Recherche dans OpenFoodFacts API
- Si non trouvé, recherche dans la base communautaire
- Si toujours pas trouvé, propose la contribution

#### ContributeFoodSheet (sheets/contribute_food_sheet.dart)
- **Nouveau sheet** : Contribution communautaire
- Formulaire pour ajouter un aliment non trouvé
- Sauvegarde dans `community_foods` pour tous les utilisateurs

#### FavoriteFoodsSheet (sheets/favorite_foods_sheet.dart)
- **Nouveau sheet** : Aliments favoris
- Triés par fréquence d'utilisation
- Swipe pour supprimer

#### MealTemplatesSheet (sheets/meal_templates_sheet.dart)
- **Nouveau sheet** : Templates de repas
- Ajouter un repas complet en un tap

### Nouvelles tables Supabase

| Table | Description |
|-------|-------------|
| daily_nutrition_logs | Tracking journalier (séparé du plan) |
| user_favorite_foods | Aliments favoris de l'utilisateur |
| meal_templates | Templates de repas sauvegardés |
| community_foods | Base communautaire crowdsourcée |

### Nouveaux services

#### OpenFoodFactsService (core/services/openfoodfacts_service.dart)
- `getProductByBarcode(barcode)` : Recherche par code-barres
- `searchProducts(query)` : Recherche par nom
- API gratuite, bonne couverture France

#### SupabaseService (ajouts)
- CRUD pour daily_nutrition_logs
- CRUD pour user_favorite_foods
- CRUD pour meal_templates
- CRUD pour community_foods

### Dépendances ajoutées
- `mobile_scanner: ^5.1.1` - Scanner de codes-barres
- `http: ^1.2.2` - Requêtes HTTP pour OpenFoodFacts

---

## 2026-02-05 - Édition des plans nutrition

### Nouvelles fonctionnalités

#### 1. EditPlanSheet (sheets/edit_plan_sheet.dart)
- **Nouveau fichier** : Bottom sheet pour modifier les plans nutrition
- Renommage du plan via TextField
- Modification des objectifs caloriques (training/repos)
- Ajustement des macros (protéines, glucides, lipides)
- Bouton de suppression avec confirmation
- Plans coach en lecture seule (affichage info uniquement)
- État de chargement pendant les opérations async

#### 2. Bouton d'édition dans le sélecteur de plans (nutrition_screen.dart)
- Icône d'édition sur chaque plan dans `_buildPlanItem()`
- Navigation vers `EditPlanSheet` au tap
- Gestion de la suppression avec rechargement automatique
- Si le plan actif est supprimé, sélection automatique d'un autre plan

### Intégration backend
- Utilisation de `SupabaseService.updateDietPlan()` existant
- Utilisation de `SupabaseService.deleteDietPlan()` existant
- Rechargement des données via `_loadData()` après modification

---

## 2026-02-03 - Nutrition Screen Enhancements

### Nouvelles fonctionnalités

#### 1. Toggle Training/Repos par jour (nutrition_screen.dart)
- Badge tappable pour basculer entre jour d'entraînement et jour de repos
- Permet le carb cycling avec macros différents selon le type de jour
- Feedback visuel avec couleur orange (training) ou gris (repos)

#### 2. Nombre de repas configurable (nutrition_screen.dart, meal_card.dart)
- Suppression de la limite fixe de 4 repas par jour
- Bouton "Ajouter un repas" avec dialog de nomination
- Presets rapides : Petit-déjeuner, Brunch, Déjeuner, Collation, Goûter, Pré-workout, Post-workout, Dîner
- Possibilité de supprimer un repas (si plus d'un repas)

#### 3. Saisie manuelle des grammes (edit_food_sheet.dart)
- Champ de saisie direct pour les grammes (1-9999g)
- Boutons +/- pour ajuster par pas de 10g
- Presets rapides : 25g, 50g, 100g, 150g, 200g, 250g, 300g
- Calcul automatique des macros basé sur la portion de base

#### 4. Scanner d'étiquettes nutritionnelles (nutrition_scanner_sheet.dart)
- **Nouveau fichier** : OCR pour lire les étiquettes de produits
- Prise de photo ou import depuis galerie
- Détection automatique : calories, protéines, glucides, lipides
- Parsing regex pour formats français et anglais
- Formulaire de correction si valeurs incorrectes
- Packages ajoutés : `image_picker`, `google_mlkit_text_recognition`

---

## 2026-02-03 - Health & Workout Bug Fixes

### Corrections critiques

#### 1. Écran blanc au lancement d'un workout (active_workout_screen.dart)
- **Root cause** : Accès à `_exercises[index]` avant la fin du chargement async
- **Fix** : Ajout d'un état `_isLoading` avec spinner pendant le chargement
- Ajout d'un état vide si aucun exercice n'est trouvé dans le programme

#### 2. Durée de sommeil incorrecte (14h+ au lieu de ~8h) (health_service.dart)
- **Root cause** : Segments de sommeil dupliqués/chevauchants additionnés
- **Fix** : Déduplication avec `removeDuplicates()` + tracking des intervalles déjà comptés
- Utilisation du segment IN_BED le plus long comme fenêtre de sommeil principale
- Filtrage des données en dehors de la session principale

#### 3. Pull-to-refresh sur l'écran Santé (health_screen.dart)
- Ajout de `RefreshIndicator` pour resynchroniser avec Apple Health
- Physics `AlwaysScrollableScrollPhysics` pour permettre le pull même en haut

#### 4. Données manquantes grisées au lieu de 0 (health_screen.dart)
- Les métriques sans données Apple Health affichent "—" au lieu de "0"
- Couleurs grisées pour indiquer l'indisponibilité
- Score santé calculé uniquement sur les catégories avec données

#### 5. Balance calorique sans calories consommées (health_screen.dart)
- **Root cause** : Affichait un déficit de -2000+ kcal si pas de tracking alimentaire
- **Fix** : N'affiche la balance que si l'utilisateur a logué des calories
- Sinon affiche uniquement "Calories dépensées" avec le total brûlé

---

## 2026-02-02 - Production Audit Fixes

### Corrections critiques

#### 1. Calories kJ → kcal (health_service.dart)
- Fix conversion des calories depuis HealthKit (division par 4.184)
- Avant: 3665 kJ affichés comme kcal | Après: ~876 kcal

#### 2. Programme non affiché après création
- **workout_screen.dart** : `_openCreateFlow()` attend maintenant le résultat et recharge
- **create_choice_screen.dart** : `_navigateTo()` retourne le résultat de création
- **program_creation_flow.dart** : `_showSuccessModal()` retourne `true` après succès

#### 3. Nutrition sauvegardée vers Supabase
- **nutrition_screen.dart** : Nouvelle méthode `_saveDietPlanChanges()`
- Appelée après : `_addFoodToMeal`, `_updateFood`, `_deleteFood`, `_duplicateDayToTargets`, `_resetDay`

#### 4. Profile settings persistés
- **profile_screen.dart** : Nouvelle méthode `_saveSetting(key, value)`
- Settings sauvegardés : notifications, workout_reminders, rest_day_reminders, progress_alerts, weight_unit, language

#### 5. Challenges sauvegardés vers Supabase
- **supabase_service.dart** : Nouvelles méthodes `createChallenge()`, `joinChallenge()`, `updateChallengeProgress()`, `getChallenges()`
- **social_screen.dart** : `_createChallenge()` et `_participateInChallenge()` connectés à Supabase

#### 6. Erreurs silencieuses avec feedback utilisateur
- **home_screen.dart** : SnackBar d'erreur avec bouton "Réessayer" si chargement échoue
- **active_workout_screen.dart** : SnackBar d'avertissement si programme non chargé

---

## 2026-02-01 - Nettoyage des données mock

### Mobile (Flutter)
Suppression de toutes les données hardcodées pour afficher un état vide aux nouveaux utilisateurs :

- **home_screen.dart** : `currentStreak` → 0
- **friend_activity_peek.dart** : `_activities` → liste vide
- **sleep_summary_widget.dart** : données sommeil → "--" / 0
- **macro_summary_widget.dart** : calories/macros → 0
- **social_screen.dart** : `_activities`, `_challenges`, `_friends` → listes vides
- **nutrition_screen.dart** : `_weeklyPlan` → structure vide (4 repas/jour sans aliments)
- **health_screen.dart** : fallback mock → 0 (données réelles depuis HealthKit)
- **active_workout_screen.dart** : `_exercises` → liste vide (chargés depuis programme)

---

## 2026-02-01 - Google Authentication

### Configuration Google Cloud
- Projet FitGame configuré avec OAuth consent screen (External)
- iOS OAuth Client : `241707453312-24n1s72q44oughb28s7fjhiaehgop7ss.apps.googleusercontent.com`
- Web OAuth Client : `241707453312-bcdt4drl7bi0t10pga3g83f9bp123384.apps.googleusercontent.com`
- Supabase Auth Provider Google activé avec Skip nonce checks (iOS)

### Mobile (Flutter)
- **pubspec.yaml** : Ajout `google_sign_in: ^6.2.2`
- **core/services/supabase_service.dart** :
  - `signInWithGoogle()` : Authentification native Google avec création profil automatique
  - `signOut()` : Déconnexion Google + Supabase
- **features/auth/auth_screen.dart** : Bouton "Continuer avec Google" avec glow orange
- **ios/Runner/Info.plist** : URL scheme `com.googleusercontent.apps.241707453312-...`

### Coach-Web (React)
- **store/auth-store.ts** :
  - `loginWithGoogle()` : OAuth redirect vers Google
- **pages/auth/login-page.tsx** : Bouton Google avec logo SVG multicolore

---

## 2026-02-01 - Backend Phase 5.3 : Apple Health / Google Fit

### Mobile (Flutter)
- **core/services/health_service.dart** : Service HealthKit/Google Fit
  - `requestAuthorization()` : Demande permissions santé
  - `checkAuthorization()` : Vérifie statut permissions
  - `getSleepData(date)` : Sommeil (deep, light, REM, awake)
  - `getActivityData(date)` : Activité (steps, calories, distance)
  - `getHeartData(date)` : Coeur (resting HR, avg/min/max HR, HRV)
  - `getHealthSnapshot(date)` : Toutes les données combinées
  - `writeWorkout()` : Enregistre séance dans Apple Santé
  - Models: SleepData, ActivityData, HeartData, HealthSnapshot

- **health_screen.dart** : Intégration données réelles
  - Chargement automatique au mount
  - Fallback sur mock data si non autorisé
  - Getters dynamiques pour utiliser vraies données

### Configuration iOS
- **Info.plist** : Permissions HealthKit
  - NSHealthShareUsageDescription
  - NSHealthUpdateUsageDescription
- **Runner.entitlements** : Capabilities HealthKit
  - com.apple.developer.healthkit
  - com.apple.developer.healthkit.background-delivery

### Dépendances ajoutées
- `health: ^11.1.0` : Apple Health / Google Fit
- `permission_handler: ^11.3.1` : Gestion permissions

---

## 2026-02-01 - Backend Phase 5.4 : Export PDF

### Coach-Web (React)
- **lib/pdf-export.ts** : Utilitaire génération PDF avec jsPDF
  - `exportProgramToPDF(program, coachName)` : Export programme complet
    - Header brandé FitGame (orange)
    - Métadonnées : objectif, durée, jours d'entraînement
    - Tableau exercices par jour (nom, muscle, sets×reps@poids, mode)
    - Notes d'exercices incluses
    - Footer avec date génération
  - `exportDietPlanToPDF(dietPlan, coachName)` : Export plan nutrition
    - Header brandé (vert)
    - Boxes calories/macros jour training vs repos
    - Liste des repas avec aliments détaillés
    - Liste des suppléments avec dosage et timing
    - Notes générales

- **program-detail-page.tsx** : Bouton "Exporter PDF" dans menu Actions
- **nutrition-detail-page.tsx** : Bouton "Exporter PDF" dans menu Actions

### Dépendance ajoutée
- `jspdf` : Génération PDF côté client

---

## 2026-02-01 - Backend Phase 5.5 : Historique et Statistiques

### Coach-Web (React)
- **store/stats-store.ts** : Nouveau store pour statistiques dashboard
  - `fetchDashboardStats()` : Stats globales (élèves, séances, compliance, volume)
  - `fetchRecentActivity()` : Activité récente des élèves
  - `fetchWeeklyTrends()` : Tendances hebdomadaires (8 semaines)
  - `refreshAll()` : Rafraîchit toutes les stats

- **dashboard-page.tsx** : Dashboard avec vraies données Supabase
  - Stats élèves actifs vs total
  - Séances cette semaine + évolution vs semaine dernière
  - Compliance moyenne + élèves à risque
  - Volume total soulevé (en kg/tonnes)
  - Messages non lus (temps réel)
  - Bouton refresh pour actualiser

- **app-shell.tsx** : Chargement stats à l'authentification
  - `refreshStats()` ajouté au Promise.all initial

### Données calculées depuis Supabase
- Agrégation workout_sessions par semaine
- Calcul volume = poids × reps pour tous les sets
- Élèves à risque = < 2 séances/semaine
- Compliance = % élèves avec >= 3 séances/semaine

---

## 2026-02-01 - Backend Phase 5.2 : Notifications Browser

### Coach-Web (React)
- **lib/notifications.ts** : Service de notifications browser
  - `notificationService.isSupported()` : Vérifie support navigateur
  - `notificationService.requestPermission()` : Demande autorisation
  - `notificationService.show()` : Affiche notification
  - `showMessageNotification()` : Notification nouveau message
  - `showSessionNotification()` : Notification séance complétée

- **messages-store.ts** : Intégration notifications
  - Notification browser automatique sur nouveau message (realtime)
  - Respect des préférences utilisateur (settings-store)

- **settings-page.tsx** : UI permissions notifications
  - Carte pour activer les notifications browser
  - Affichage état permission (granted/denied/default)
  - Notification test à l'activation

---

## 2026-02-01 - Backend Phase 5.1 : Messages Temps Réel

### Database
- **Migration create_messages_table** :
  - Table `messages` avec sender_id, receiver_id, content, read_at
  - RLS policies pour sécuriser accès (lecture/écriture uniquement participants)
  - Publication Realtime activée pour les messages

### Coach-Web (React)
- **messages-store.ts** : Réécrit pour Supabase temps réel
  - `fetchMessages()` : Charge tous les messages coach ↔ élèves
  - `sendMessage(studentId, content)` : Envoi async avec optimistic update
  - `markAsRead(studentId)` : Marque messages comme lus
  - `subscribeToRealtime()` : Souscription postgres_changes pour nouveaux messages
  - `unsubscribeFromRealtime()` : Cleanup souscription
  - Groupement messages par conversation (studentId)

- **messages-page.tsx** : Adapté pour async/temps réel
  - État de chargement pendant envoi
  - Mise à jour automatique via realtime
  - Conversations groupées par élève

- **app-shell.tsx** : Init messages au login
  - Fetch messages à l'authentification
  - Subscribe realtime après chargement initial
  - Cleanup on unmount

---

## 2026-02-01 - Backend Phase 4 : Sync Coach-Élève

### Mobile (Flutter)
- **workout_screen.dart** : Chargement programmes depuis Supabase
  - Affiche programmes propres + assignés par coach
  - Badge "COACH" pour programmes du coach
  - Section séparée dans la liste des programmes
- **nutrition_screen.dart** : Chargement plans diète depuis Supabase
  - Affiche plans propres + assignés par coach
  - Possibilité de switcher entre plans disponibles
  - Badge "COACH" en header si plan du coach actif
- **supabase_service.dart** : Méthodes getCoachInfo ajoutée

### Coach-Web (React)
- **students-store.ts** : Ajout fetchStudentSessions()
  - Récupère séances workout complétées par un élève
  - Stockage dans studentSessions[studentId]
- **student-profile-page.tsx** : Vraies données séances
  - Remplacement mock data par vraies séances Supabase
  - Loading state pendant chargement
  - Affichage PRs (Personal Records)

---

## 2026-02-01 - Backend Phase 3 : Données Core

### Coach-Web (React)
- **programs-store.ts** : CRUD complet avec Supabase
- **nutrition-store.ts** : CRUD complet avec Supabase
- **students-store.ts** : CRUD complet avec Supabase
- **AppShell** : Chargement auto des données à l'auth

### Mobile (Flutter)
- **supabase_service.dart** : API complète ajoutée
  - Programs: getPrograms, createProgram, updateProgram, deleteProgram
  - WorkoutSessions: startWorkoutSession, completeWorkoutSession, getWorkoutSessions
  - DietPlans: getDietPlans, createDietPlan, updateDietPlan, deleteDietPlan
  - Assignments: getAssignments, getAssignedPrograms, getAssignedDietPlans
- **program_creation_flow.dart** : Sauvegarde vers Supabase à la fin
- **active_workout_screen.dart** : Sauvegarde session complétée
- **diet_creation_flow.dart** : Sauvegarde vers Supabase à la fin

### Migration DB
- Ajout colonne `goal` dans `profiles` pour les athlètes

---

## 2026-02-01 - Backend Phase 1 & 2 : Database + Authentication

### Phase 1 : Database Supabase
- **Projet Supabase créé** : `snqeueklxfdwxfrrpdvl` (région eu-west-1)
- **Tables créées** :
  - `profiles` : Utilisateurs avec role (athlete/coach), preferences, coach_id
  - `coaches` : Détails additionnels coach (business_name, credentials, 2FA)
  - `programs` : Programmes d'entraînement avec JSONB days
  - `diet_plans` : Plans nutritionnels avec JSONB meals/supplements
  - `workout_sessions` : Séances complétées avec JSONB exercises
  - `assignments` : Assignations coach → élève (programmes/diets)
- **RLS (Row Level Security)** : Policies activées pour toutes les tables
- **Trigger** : `updated_at` automatique sur toutes les tables

### Phase 2 : Authentication
- **Flutter (Mobile)**
  - `lib/core/services/supabase_service.dart` : Client Supabase + helpers auth
  - `lib/features/auth/auth_screen.dart` : Écran login/register avec validation
  - `lib/main.dart` : AuthWrapper avec StreamBuilder pour auth state
  - `.env` + `.env.example` : Configuration credentials
- **React (Coach-Web)**
  - `src/lib/supabase.ts` : Client Supabase
  - `src/store/auth-store.ts` : Zustand store avec login/signUp/logout/checkSession
  - `.env` + `.env.example` : Configuration credentials
  - Vérification du role 'coach' lors de la connexion

### Frontend Polish (pré-backend)
- Navigation Flutter : "Training" → "Entraînement"
- Today workout card : "45 min" → "~45-60 min"
- Sleep detail : Ajout "(moins = mieux)" sur jauge Éveillé
- Nutrition day toggle : "TRAINING" → "ENTRAÎNEMENT"
- Profile settings : "Alertes progression" → "Alertes de progression"
- Coach-web : Suppression Calendar nav, simplification Settings (dark only)
- Coach-web : Suppression demo credentials dans login

---

## 2026-01-30 (Suite 13) - Documentation Architecture Unifiée

### Nouvelle documentation
- **`/docs/ARCHITECTURE.md`** : Documentation unifiée pour le backend
  - Vue d'ensemble système (FitGame Mobile + Coach-Web + Backend)
  - Schémas détaillés de tous les modèles de données
  - Endpoints API requis par chaque app
  - Relations entre entités
  - Flux de données typiques

### Mise à jour SCREENS.md
- Ajout `preferences_step.dart` dans DietCreationFlow
- Flow création diète passe de 8 à 9 étapes
- Nouvelle étape 6 : Préférences alimentaires (restrictions + aliments préférés)

### Mise à jour CLAUDE.md (racine)
- Ajout lien vers `/docs/ARCHITECTURE.md`

---

## 2026-01-29 (Suite 12) - Audit Text Overflow

### Corrections appliquées (13 fixes dans 7 fichiers)

#### health_screen.dart
- Subtitle "Basé sur sommeil..." : `maxLines: 2` + `overflow: ellipsis`
- Section label "MÉTRIQUES DÉTAILLÉES" : `maxLines: 1` + `overflow: ellipsis`

#### workout_screen.dart
- Program name h3 dans header : `FittedBox` avec `scaleDown`
- Session name h1 (36px) dans hero card : `FittedBox` avec `scaleDown`
- Stats value h3 : `maxLines: 1` + `overflow: ellipsis`
- Recent session name : `Flexible` + `maxLines: 1` + `overflow: ellipsis`

#### nutrition_screen.dart
- "Plan semaine" h1 : `FittedBox` avec `scaleDown`
- Badge "TRAINING" : `Flexible` + `FittedBox` dans Row

#### nutrition/widgets/meal_card.dart
- Meal name : `maxLines: 1` + `overflow: ellipsis`

#### social_screen.dart
- "Ta communauté" h1 : `FittedBox` avec `scaleDown`

#### social/widgets/activity_card.dart
- userName : `maxLines: 1` + `overflow: ellipsis`
- Exercise display : `maxLines: 1` + `overflow: ellipsis`

#### profile_screen.dart
- Email : `maxLines: 1` + `overflow: ellipsis`
- Navigation tile title : `maxLines: 1` + `overflow: ellipsis`

### Résultat
- `flutter analyze` : 0 erreurs (10 infos mineures sur constructeurs)
- Aucun risque de débordement/chevauchement de texte sur petits écrans

---

## 2026-01-29 (Suite 11) - Finalisation boutons et sheets manquants

### Nouveaux sheets créés (Profile)
- **AdvancedSettingsSheet** : Paramètres avancés avec thème, données, export, zone danger
- **AchievementsSheet** : Liste complète des accomplissements avec progression et rareté
- **HelpSupportSheet** : FAQ interactive + contact support (email/Discord)
- **LegalSheet** : CGU et Politique de confidentialité (textes complets)

### Nouveau sheet créé (Social)
- **NotificationsSheet** : Liste des notifications avec types variés (respect, défis, PR, amis)

### Handlers implémentés (Social)
- **Participation défis** : Logique mock pour rejoindre un défi existant
- **Création défis** : Ajout à la liste avec participants invités
- **Bouton notifications** : Ouvre le NotificationsSheet

### Handlers implémentés (Workout)
- **Switch programme** : Changement de programme actif avec setState
- **Navigation historique** : Depuis LastWorkoutRow vers WorkoutHistoryScreen

### Handlers implémentés (Nutrition)
- **Scanner barcode** : PlaceholderSheet (nécessite caméra)
- **Créer aliment custom** : Dialog avec formulaire de saisie

### Connexions ProfileScreen
- Paramètres avancés → AdvancedSettingsSheet
- Accomplissements → AchievementsSheet
- Aide & Support → HelpSupportSheet
- CGU → LegalSheet (terms)
- Confidentialité → LegalSheet (privacy)

### Résultat
- Tous les boutons déclenchent une action
- PlaceholderSheet uniquement pour fonctionnalités externes (Apple Health, iCloud, App Store)
- `flutter analyze` : 0 erreurs

---

## 2026-01-29 (Suite 10) - Polish ProfileScreen

### Header cohérent
- **Style unifié** avec les autres écrans (PROFIL + "Tes réglages")
- Caption uppercase avec letterspacing + h2 italic bold
- Bouton paramètres avancés dans le header

### Hero Profile Card enrichie
- **Avatar avec glow** : gradient accent + shadow 24px
- **Bouton édition overlay** : positionné sur l'avatar avec bordure accent
- **Stats row** :
  - Séances (total workouts) en accent
  - Streak avec icône feu 🔥 en accent
  - Membre depuis (date) en accent

### Section Accomplissements (nouvelle)
- **Header** avec compteur X/Y (badges débloqués / total)
- **Grid de 6 badges** :
  - Premier PR, 7j Streak, 100 Séances (débloqués)
  - Marathon, Iron Will, Elite (verrouillés)
- **Badges débloqués** : gradient accent + border + glow
- **Badges verrouillés** : fond gris semi-transparent + icône grisée
- **Tap** : ouvre placeholder sheet "bientôt disponible"

### Sections améliorées (Notifications, Préférences, À propos)
- **Icônes avec gradients** : background gradient accent quand actif
- **Switch custom** : couleur accent + glow quand ON
- **Navigation tiles** : icônes avec gradients colorés par thème
  - Apple Health : rose/corail
  - Sauvegarde : cyan/violet
  - Noter l'app : accent/orange
- **Indicateurs** : "Connecté" et "iCloud activé" en vert

### Mesh gradient
- **Orbe accent** en haut gauche
- **Orbe accent subtil** en bas droite
- **Animation pulsante** : 4s cycle, opacité 0.08→0.22

### Animations
- **Pulse background** : mesh gradient animé en continu
- **Switch** : transition fluide avec Curves.easeOutBack

### Résultat
- Interface premium cohérente avec Training et Santé
- Utilisation de FGColors.accent (orange #FF6B35) partout
- `flutter analyze` : 0 erreurs

---

## 2026-01-29 (Suite 9) - Polish HealthScreen

### Hero Score Santé
- **Nouveau composant hero** : Score global de santé combinant sommeil, cœur et activité
  - Cercle animé avec score 0-100
  - Label dynamique (Excellent/Bon/Moyen/À améliorer)
  - Couleur contextuelle (vert/violet/orange/rouge)
  - Badge tendance (↗ ↘ →) basé sur la moyenne des 3 métriques
  - Animation count-up au chargement (1.5s)
  - Glow et shadow cohérents avec le score

### Quick Stats Pills
- **3 pills compacts** en ligne sous le hero :
  - Pas : icône marche + valeur formatée (8.7k) + barre progression vs objectif
  - Kcal : icône feu + calories brûlées + barre progression
  - Sommeil : icône lune + durée (7h23) + barre progression vs 8h
- Style cohérent avec WorkoutScreen (même composant visuel)

### Indicateurs de tendance
- **Mini badges tendance** ajoutés sur chaque carte (Sommeil, Cœur, Énergie)
- Icône flèche haut/bas/stable avec couleur contextuelle
- Comparaison avec la moyenne 7 jours

### Cartes améliorées

**Sleep Card** :
- Barre de phases empilées (Profond/Core/REM) avec légende
- Badge efficacité sommeil (%)
- Score lettre (A+/A/B/C) au lieu de score numérique
- Icône avec gradient au lieu de fond plat

**Heart Card** :
- 3 métriques en colonnes (FC Repos, VFC, VO₂ Max)
- Dividers visuels entre colonnes
- Badges status colorés sous chaque valeur
- Score lettre dans le header

**Energy Card** :
- Badge net calories prominent (+/- avec couleur)
- Barres de progression côte à côte (Consommé vs Dépensé)
- Labels et valeurs intégrés aux barres

### Header amélioré
- Badge "Sync" vert avec point lumineux (Apple Health connecté)
- Titre italic bold cohérent avec autres écrans

### Mesh gradient enrichi
- Orbe violet plus intense en haut gauche
- Orbe rose/rouge en bas droite
- Animation pulsante plus prononcée

### Calculs ajoutés
- `_globalHealthScore` : moyenne pondérée des 3 scores
- `_calculateHeartScore()` : score basé sur FC repos et VFC
- `_calculateActivityScore()` : score basé sur pas et calories
- `_getVo2Status()` : classification VO₂ Max

### Résultat
- Interface plus riche et informative
- Cohérence visuelle avec WorkoutScreen
- `flutter analyze` : 0 erreurs

---

## 2026-01-29 (Suite 8) - Écran Progression PR

### ExerciseProgressScreen - Visualisation évolution des poids
- **Nouvel écran** : `lib/features/workout/progress/exercise_progress_screen.dart`
  - Accessible en tappant sur un badge PR dans les séances récentes
  - Header avec nom exercice + muscle + badge PR actuel
  - Animation fade-in à l'ouverture

### Graphique de progression (CustomPainter)
- **Fichier** : `lib/features/workout/progress/widgets/progress_chart.dart`
- **Fonctionnalités** :
  - Ligne de progression avec courbe de Bézier lisse
  - Points normaux (orange) pour chaque séance
  - Points dorés avec glow pour les PRs
  - Grille avec axes Y (poids) et X (semaines)
  - Zone sous la courbe avec gradient
  - Animation d'apparition progressive (1.2s)

### Liste historique PRs
- **Fichier** : `lib/features/workout/progress/widgets/pr_history_list.dart`
- **Fonctionnalités** :
  - Liste triée par date décroissante
  - Item le plus récent mis en valeur (fond doré)
  - Affichage poids × reps + nom séance + date relative
  - Icône trophée dorée sur le PR actuel

### Modèles de données
- **Fichier** : `lib/features/workout/progress/models/exercise_history.dart`
- **Classes** :
  - `ExerciseProgressEntry` : date, weight, reps, isPR, sessionName
  - `ExerciseHistory` : exerciseName, muscleGroup, currentPR, entries
  - Getters calculés : progressPercentage, totalGain, weeksOfProgress
- **Mock data** : Bench Press, Squat, Deadlift avec 7 semaines d'historique

### Card stats de progression
- Pourcentage de progression depuis le début
- Gain total en kg
- Nombre de semaines de progression
- Icône trending_up verte

### WorkoutScreen modifié
- Badge PR rendu tappable (GestureDetector)
- Navigation vers ExerciseProgressScreen au tap
- Transition slide-from-right

### Structure des fichiers
```
lib/features/workout/progress/
├── exercise_progress_screen.dart    # Écran principal
├── models/
│   └── exercise_history.dart        # Modèles + mock data
└── widgets/
    ├── progress_chart.dart          # CustomPainter graphique
    └── pr_history_list.dart         # Liste des PRs
```

### Résultat
- 4 nouveaux fichiers créés
- `flutter analyze` : 0 erreurs dans les fichiers progress
- Badge PR cliquable avec navigation fluide

---

## 2026-01-29 (Suite 7) - Refonte HomeScreen multi-features

### HomeScreen - Dashboard multi-domaines
- **Architecture refactorisée** : Extraction de 7 widgets dans `lib/features/home/widgets/`
  - `home_header.dart` : Header avec greeting + avatar + badge streak compact
  - `quick_stats_row.dart` : 3 pills stats (séances, temps, kcal)
  - `today_workout_card.dart` : Card workout héro
  - `last_workout_row.dart` : Dernière séance avec check vert
  - `sleep_summary_widget.dart` : Résumé sommeil avec phases et score
  - `macro_summary_widget.dart` : Résumé nutrition avec calories et macros P/C/F
  - `friend_activity_peek.dart` : Aperçu activité amis (2 dernières)

### Nouvelles sections HomeScreen
- **Streak badge compact** : Remplace le Hero 96px, affiché dans le header (🔥 12j)
- **Sleep Summary** : Durée totale + barres phases (Profond/Core/REM) + score qualité
- **Macro Summary** : Barre calories + 3 mini barres P/C/F avec pourcentages
- **Friend Activity** : 2 activités récentes avec avatar, nom, workout, timestamp

### Navigation inter-onglets
- **Callback `onNavigateToTab`** ajouté à HomeScreen
- **main.dart** modifié : Passe le callback pour navigation depuis les widgets
- Tap Sleep → Santé (index 4)
- Tap Nutrition → Nutrition (index 3)
- Tap Social → Social (index 2)

### Ordre final HomeScreen
1. Header (greeting + avatar + streak badge)
2. Today's Workout Card (héro)
3. Quick Stats Row (3 pills)
4. Sleep Summary Widget → tap = Santé
5. Macro Summary Widget → tap = Nutrition
6. Friend Activity Peek → tap = Social
7. Last Workout Row
8. Bottom CTA (inchangé)

### Résultat
- Mesh gradient animé préservé
- 7 nouveaux fichiers widgets
- `flutter analyze` : 0 nouvelles erreurs
- Navigation callback fonctionnel

## 2026-01-29 (Suite 6) - Connexion boutons stubs

### Nouveaux écrans créés
- **WorkoutHistoryScreen** (`lib/features/workout/history/workout_history_screen.dart`)
  - Liste des séances passées avec dates
  - Filtrage par type de session (Push/Pull/Leg)
  - Stats par séance : durée, volume, exercices, PRs
  - Badge PR avec icône trophée
  - Bottom sheet détail avec liste exercices
  - Design glassmorphism cohérent

- **ProgramEditScreen** (`lib/features/workout/edit/program_edit_screen.dart`)
  - Modification nom du programme
  - Liste ReorderableListView des séances avec drag-drop
  - Preview exercices par séance (3 premiers + compteur)
  - Boutons éditer/supprimer par séance
  - Ajout nouvelle séance
  - Confirmation abandon si modifications non sauvegardées
  - Bouton sauvegarder avec état actif/inactif

### Nouveaux sheets créés
- **PlaceholderSheet** (`lib/shared/sheets/placeholder_sheet.dart`)
  - Sheet réutilisable "Coming soon" avec titre, message et icône
  - Utilisé pour fonctionnalités pas encore implémentées

- **EditProfileSheet** (`lib/features/profile/sheets/edit_profile_sheet.dart`)
  - Modification avatar (8 emojis fitness)
  - Champs nom et email
  - Boutons annuler/sauvegarder

### WorkoutScreen - 4 boutons connectés
- Item récent → WorkoutHistoryScreen (filtré sur session)
- Bouton Modifier → ProgramEditScreen
- Bouton Historique → WorkoutHistoryScreen
- Bouton Séance libre → SessionCreationScreen

### ProfileScreen - 7 liens connectés
- Edit profile → EditProfileSheet
- Apple Health → PlaceholderSheet
- Sauvegarde → PlaceholderSheet
- Noter l'app → PlaceholderSheet
- Aide & Support → PlaceholderSheet
- CGU → PlaceholderSheet
- Confidentialité → PlaceholderSheet

### NutritionScreen - 6 callbacks implémentés
- `_showFoodLibrary` onSelectFood → `_addFoodToMeal()` avec setState
- `_showEditFood` onSave → `_updateFood()` avec setState
- `_showEditFood` onDelete → `_deleteFood()` avec setState
- `_showDuplicateSheet` onDuplicate → `_duplicateDayToTargets()` deep copy
- `_confirmReset` → `_resetDay()` vide les repas
- Bouton Partager → `_shareDayPlan()` avec share_plus
- `_showGenerateSheet` → `_generateAIPlan()` génération mock aléatoire

### Dépendances
- `share_plus: ^10.1.4` ajouté pour le partage

### Résultat
- 17 boutons/liens connectés
- `flutter analyze` : 0 erreurs (warnings mineurs existants non liés)

## 2026-01-28 (Suite) - Refactorisation majeure des screens
- **Refactorisation complète** pour améliorer la maintenabilité et réduire la complexité des fichiers
- **Objectif** : Réduire les fichiers massifs (>1400 lignes) à des tailles gérables (<700 lignes)

### Nutrition Feature (1,504 → 901 lignes, -40%)
- **Widgets créés** (6 fichiers):
  - `macro_pill.dart` - Badge compact pour afficher valeurs macro (P/C/F)
  - `quick_action_button.dart` - Bouton d'action rapide (Générer IA, Bibliothèque, etc.)
  - `food_item.dart` - Item aliment avec nom, quantité, macros et calories
  - `meal_card.dart` - Card repas extensible avec liste d'aliments (StatefulWidget)
  - `macro_dashboard.dart` - Dashboard calories avec ring principal + breakdown macros
  - `day_selector.dart` - Sélecteur de jour avec mini progress rings

### Workout Tracking Feature (1,407 → 610 lignes, -57%)
- **Widgets créés** (8 fichiers):
  - `workout_header.dart` - Header avec exercice, muscle, progression et timer
  - `stats_bar.dart` - Barre de stats (volume, séries, kcal)
  - `set_card.dart` - Card principale affichant poids/reps cible + record
  - `exercise_navigation.dart` - Dots de navigation entre exercices avec haptics
  - `set_indicators.dart` - Indicateurs de progression des séries
  - `weight_reps_input.dart` - Inputs poids/reps avec boutons +/- et number picker
  - `rest_timer_view.dart` - Vue repos avec timer circulaire et preview prochaine série
  - `pr_celebration.dart` - Overlay de célébration pour nouveau record

### Health Feature (déjà refactorisé)
- Statut : 778 lignes (painters, models, sheets, modals déjà extraits)

### Résultats globaux
- **Total initial** : ~5,849 lignes dans 3 screens
- **Total final** : 2,288 lignes (-61% de réduction)
- **Fichiers widgets créés** : 14 nouveaux composants réutilisables
- **Impact** : Facilite grandement le travail de Claude et la maintenance du code

## 2025-01-27
- Création projet Flutter avec `flutter create`
- Design system de base : FGColors, FGTypography, FGEffects, Spacing
- Composants créés : FGGlassCard, FGNeonButton
- Écran de test : DesignSystemTestScreen dans main.dart

## 2026-01-27
- Suppression de DesignSystemTestScreen (écran temporaire)
- Création de HomeScreen (`lib/features/home/home_screen.dart`) - écran d'accueil principal
- **Refonte complète HomeScreen** - Design premium avec hiérarchie visuelle forte
  - Mesh gradient animé : 2 orbes orange pulsants (3s cycle) pour l'atmosphère
  - Header avec avatar utilisateur (initiale + gradient)
  - **Hero Streak** : Nombre géant 96px orange italic avec glow, label "SÉRIE EN COURS"
  - Badge titre dynamique (DÉBUTANT → IMMORTEL) avec bordure accent
  - Stats en ligne : 3 pills compacts (séances, temps, kcal) au lieu de card
  - **Séance du jour** : Card avec header gradient accent, badge "AUJOURD'HUI", tags muscles (primary/secondary)
  - Dernière séance : Ligne subtile avec icône success, pas de card
  - CTA fixe en bas avec gradient fade vers le fond
- Refactoring de main.dart : nettoyage et import du HomeScreen
- **WorkoutScreen** - Nouvel écran de gestion d'entraînement (`lib/features/workout/workout_screen.dart`)
  - Programme actif : Card avec badge "ACTIF" vert, progression semaine X/Y, barre de progression séances
  - Actions rapides : 2 cards pour "Créer Programme" et "Créer Séance" avec icônes accent
  - Import : Card avec bottom sheet pour importer depuis CSV, PDF ou Photo
  - Liste programmes : Cards avec indicateur actif (point vert lumineux), infos semaines/fréquence
  - Liste séances : Cards avec muscles tags, bouton "GO" pour démarrer rapidement
  - Mesh gradient animé (position différente de HomeScreen pour variété)
  - Empty states élégants pour listes vides
- **MainNavigation** - Bottom navigation bar ajoutée à main.dart
  - 2 onglets : Accueil (home icon) et Entraînement (fitness icon)
  - Style custom avec accent orange sur sélection
  - IndexedStack pour conserver l'état des écrans
- **Refonte complète WorkoutScreen** - Simplification radicale de l'interface
  - Supprimé : compteur de jours, gros titre programme en haut de page, barre progression encombrante
  - **Next Session Card** : Hero card glassmorphism avec badge "PROCHAINE", nom séance en h1, muscles, icône play
  - **Program Card** : Card compacte avec progress ring circulaire (%), nom programme, semaine X/Y, tap → bottom sheet
  - **Récent** : Liste minimaliste des 3 dernières séances avec volume et date
  - **Quick Actions** : 3 boutons compacts (Modifier, Historique, Séance libre)
  - **Bottom Sheet programmes** : DraggableScrollableSheet avec liste programmes et bouton nouveau
  - Empty state épuré pour utilisateurs sans programme
  - Code réduit de ~1400 lignes à ~900 lignes
- **HealthScreen** - Nouvel écran Santé avec données Apple HealthKit (`lib/features/health/health_screen.dart`)
  - **Sommeil** : Durée totale hero (7h23 en violet), score calculé (EXCELLENT/BON/MOYEN/FAIBLE)
    - 4 jauges par phase : Profond, Léger, REM, Éveillé
    - Indicateur vert/orange/rouge selon recommandations scientifiques
    - Zone idéale affichée sur chaque jauge (ex: "Idéal: 13-23%")
    - Descriptions : "Récupération physique", "Mémoire & apprentissage", etc.
  - **Énergie** : Ring circulaire CustomPainter avec consommé (cyan) vs dépensé (orange)
    - Affichage déficit/surplus au centre avec couleur contextuelle
    - Stats : Consommé, Dépensé, Objectif avec icônes
  - **Activité** : Pas et distance en cards, breakdown calories par activité
    - Barres animées : BMR, Marche, Course, Musculation
  - **Cœur** : Fréquence repos, VFC avec badges status (ATHLÈTE/EXCELLENT/BON/NORMAL/ÉLEVÉ)
    - Moyenne et Max en card glassmorphism
  - Mesh gradient violet/cyan (différent des autres pages)
  - Animations jauges au chargement (1.5s ease)
- **MainNavigation** mis à jour : 3 onglets (Accueil, Entraînement, Santé)
- **Refonte HealthScreen** - Cartes expandables avec bottom sheets détaillés
  - 3 cartes principales : Énergie, Sommeil, Cœur (tap → bottom sheet)
  - Chaque carte a une icône dans un carré coloré + chevron indicateur
  - Haptic feedback au tap (lightImpact)
  - **Sleep Detail Sheet** : 5 jauges CustomPainter avec gradient rouge→jaune→vert
    - Sommeil profond (13-23% idéal)
    - Sommeil core/N1+N2 (45-55% idéal)
    - Sommeil paradoxal/REM (20-25% idéal)
    - Temps éveillé (<5% idéal, jauge inversée)
    - Temps d'endormissement (10-20min idéal)
    - Curseur blanc animé avec glow sur chaque jauge
    - Badge status (Optimal/Insuffisant/Élevé) pour chaque métrique
    - Efficacité sommeil calculée (temps sommeil / temps au lit)
  - **Energy Detail Sheet** : Stats détaillées + breakdown activités
    - Balance calorique avec séparateurs visuels
    - Barres de progression par type d'activité
    - Cards pas/distance
  - **Heart Detail Sheet** : Métriques cardiaques avancées
    - FC repos avec description contextuelle
    - Min/Moyenne/Max en cards
    - VFC avec status de récupération
    - VO₂ Max avec status fitness
- **Refonte Sleep Detail Sheet** - Layout compact avec toutes les jauges visibles
  - Header compact : icône réduite (40px), titre + badge efficacité alignés à droite
  - **5 jauges visibles sans scroll** : hauteur réduite (16px vs 32px), padding minimal
  - Chaque jauge : point coloré + label + icône info (ⓘ) + valeur + badge status
  - **Icône info tappable** : Ouvre modale éducative pour chaque phase de sommeil
  - **SleepInfoModal** : Description, bénéfices, impact fitness, zone idéale
  - Contenu éducatif complet pour : Profond, Core, REM, Éveillé, Latence
  - Painters renommés : _CompactSleepGaugePainter, _CompactLatencyGaugePainter
  - Code optimisé : jauges 50% plus petites, même lisibilité
- **Refonte complète Heart Card & Heart Detail Sheet** - Jauges et historique
  - **Carte Cœur principale** :
    - Nouvelle disposition : 2 métriques principales (Repos + VFC) au lieu de 3
    - Chaque métrique affiche valeur + unité + badge status coloré
    - Badge status avec couleurs contextuelles (vert=bon, jaune=moyen, rouge=faible)
    - Subtitle "Dernière nuit" pour clarifier les données
  - **Heart Detail Sheet** complètement réécrit :
    - **Onglets historique** : "Aujourd'hui", "7 jours", "14 jours" avec tab selector animé
    - **Vue Aujourd'hui** :
      - 2 jauges CustomPainter (FC Repos, VFC) avec même style que Sleep
      - Curseur lumineux + gradient couleur (cyan→vert→jaune→rouge)
      - Icône info tappable → modale éducative
      - Stats nuit : Min/Moy/Max en mini cards
      - VO₂ Max card avec status
    - **Vue Historique (7/14 jours)** :
      - Cards résumé : FC Repos moyenne + VFC moyenne + tendance
      - Graphique barres : évolution VFC sur 7 jours avec couleurs
      - Liste détail par jour : indicateur couleur + valeurs + icône tendance
    - **HeartInfoModal** : Descriptions éducatives pour FC repos, VFC, VO₂ Max
      - Bénéfices santé, impact entraînement, zone idéale
    - **_HeartGaugePainter** : Custom painter dédié aux métriques cardiaques
      - Support `higherIsBetter` pour VFC (gradient inversé)
      - Glow lumineux autour du curseur
    - **Mock historical data** : 7 jours de données FC/VFC pour démo
- **Flow Création Programme/Séance** - Nouveau système complet de création
  - **Bouton "+"** ajouté en haut à droite de WorkoutScreen
  - **CreateChoiceScreen** (`lib/features/workout/create/create_choice_screen.dart`)
    - Écran de choix : Programme vs Séance unique
    - Cards descriptives avec animations et glow
    - Navigation fluide avec slide transition
  - **ProgramCreationFlow** (`lib/features/workout/create/program_creation_flow.dart`)
    - Flow 3 étapes avec PageView et indicateur progression
    - Étape 1 : Nom du programme avec suggestions cliquables
    - Étape 2 : Durée & Cycle combinés
      - Toggle "Activer un cycle" (OFF = programme infini ∞)
      - Si cycle ON : durée (1-24 sem) + option deload
      - Config deload : fréquence (après X sem) + réduction poids (slider 20-60%)
      - Info card contextuelle dynamique
    - Étape 3 : Sélection jours (L-M-M-J-V-S-D) avec badges animés
    - Validation par étape avec bouton conditionnel
  - **SessionCreationScreen** (`lib/features/workout/create/session_creation_screen.dart`)
    - Création rapide de séance unique
    - Filtres par groupes musculaires (chips)
    - Liste exercices suggérés avec sélection tap
    - Ajout exercice personnalisé via bottom sheet
    - Liste réordonnableordonnable (drag & drop) des exercices
    - Compteur exercices en header
- **ProgramCreationFlow - Étape 4 Exercices par Jour** - Nouvelle étape de configuration
  - Flow étendu à 4 étapes (nom → cycle → jours → exercices)
  - **Navigation par onglets** : Un onglet par jour d'entraînement sélectionné (Lun, Mer, Ven...)
    - Badge compteur d'exercices sur chaque onglet
    - Bordure verte si au moins 1 exercice configuré
    - Animation glow orange sur onglet actif
  - **Résumé du jour** : Card avec lettre du jour + nom complet + compteur exercices + check vert si configuré
  - **Catalogue d'exercices** : 20 exercices pré-configurés, groupés par muscle
    - Pectoraux, Dos, Épaules, Biceps, Triceps, Jambes, Abdos
    - Chaque exercice cliquable pour ajouter/retirer
    - Visuel vert avec check quand ajouté
  - **Liste séance du jour** : ReorderableListView avec drag-and-drop
    - Numérotation automatique (1, 2, 3...)
    - Affichage sets×reps cliquable → bottom sheet édition
    - Bouton suppression par exercice
  - **Bottom sheet édition exercice** : Modifier sets (1-10) et reps (1-30) avec number pickers
  - **Bottom sheet exercice personnalisé** :
    - Champ nom
    - Sélecteur groupe musculaire (7 chips)
    - Number pickers sets/reps
  - **Validation** : Bouton "Créer le programme" actif uniquement si chaque jour a au moins 1 exercice
- **ProfileScreen** - Nouvel écran Profil complet (`lib/features/profile/profile_screen.dart`)
  - **Carte Profil** : Avatar avec initiale + gradient orange glow, nom, email, bouton édition
  - **Stats utilisateur** : 3 métriques (séances totales, jours série, membre depuis) avec dividers
  - **Notifications** : Section complète avec toggles animés
    - Toggle master "Notifications" activant/désactivant les sous-options
    - Sub-toggles : Rappels séances, Jours de repos, Alertes progression
    - Switches custom avec animation bounce et glow orange
  - **Préférences** :
    - Unité de poids (kg/lbs) avec segmented control animé
    - Langue (Français/English) avec segmented control
    - Apple Health : status connexion avec badge vert "Connecté"
    - Sauvegarde iCloud : status avec badge vert
  - **À propos** : Liens navigation (Noter l'app, Aide, CGU, Confidentialité)
  - Mesh gradient animé (position différente des autres écrans)
  - Haptic feedback sur tous les toggles et boutons
  - Version app en footer
- **MainNavigation** mis à jour : 4 onglets (Accueil, Entraînement, Santé, Profil)
- **NutritionScreen** - Planificateur de diète hebdomadaire complet (`lib/features/nutrition/nutrition_screen.dart`)
  - **Concept** : Planification semaine vs logging quotidien (différent de MyFitnessPal)
  - **Header** : Titre + chip objectif (Prise/Sèche/Maintien) + bouton génération IA (sparkle orange)
  - **Sélecteur jour** : 7 jours en horizontal avec :
    - Point orange lumineux sur jours d'entraînement
    - Mini progress rings montrant % calories
    - Swipe ou tap pour naviguer (PageView)
  - **Dashboard Macros** :
    - Calories hero animées avec compteur qui s'incrémente
    - Progress ring principal (vert 90-110%, jaune >110%, orange sinon)
    - 3 mini rings P/G/L avec couleurs distinctes (rouge/bleu/jaune)
  - **Badge Training** : Affiché sur jours d'entraînement avec icône haltère
  - **4 repas par jour** : Cards expandables (Petit-déj, Déjeuner, Collation, Dîner)
    - Header : icône thématique + nom + nombre aliments + calories + protéines
    - Contenu : liste aliments avec pills macros colorés (P/C/F)
    - Tap aliment → édition quantité (slider 0.25x-3x)
    - Bouton "+ Ajouter un aliment"
  - **Quick Actions** : Dupliquer jour / Réinitialiser / Partager
  - **Bottom Sheet Objectif** : 3 options avec descriptions (Prise/Sèche/Maintien)
  - **Bottom Sheet Génération IA** :
    - Toggle ajustement jours training (+ glucides)
    - Sélecteur repas/jour (3-6)
    - Bouton "Générer le plan"
  - **Bottom Sheet Bibliothèque** :
    - Recherche + bouton scanner + bouton créer aliment
    - Filtres catégories (chips horizontaux)
    - Liste aliments avec macros colorés
  - **Bottom Sheet Édition** : Slider quantité + macros recalculés en temps réel
  - **Bottom Sheet Dupliquer** : Sélection multiple des jours cibles
  - **Mock Data** : 7 jours complets avec ~15-20 aliments variés par jour
  - **CustomPainters** : _MacroRingPainter (avec glow), _MiniProgressRingPainter
  - Mesh gradient vert/orange (thème nutrition)
  - Animations : rings animés au chargement (1.2s), compteurs incrémentaux
- **MainNavigation** mis à jour : 5 onglets (Accueil, Entraînement, Nutrition, Santé, Profil)

## 2026-01-29 (Suite 5) - Bouton démarrer séance HomeScreen

- **HomeScreen** - Connexion du bouton "Commencer la séance" à ActiveWorkoutScreen
  - Méthode `_startWorkout()` ajoutée avec navigation slide-up
  - Bouton CTA en bas de page connecté
  - Tap sur la card "Today's Workout" lance aussi la séance
  - HapticFeedback mediumImpact au démarrage

## 2026-01-29 (Suite 4) - Sélecteur quantité aliments

- **FoodQuantitySheet** - Nouveau sheet pour choisir la quantité avant d'ajouter un aliment
  - **Fichier créé** : `create/sheets/food_quantity_sheet.dart`
  - Slider quantité (0.25x à 5x) avec presets rapides (0.5, 1, 1.5, 2, 3)
  - Affichage quantité en grand avec unité
  - Preview macros calculés en temps réel (Calories, P, C, F)
  - Bouton "Ajouter" confirme et ajoute au repas
- **Meal Planning Step modifié** :
  - Flow : FoodLibrarySheet → FoodQuantitySheet → ajout au repas
  - Affichage quantité dans les lignes d'aliments (ex: "2× 100g")
  - Macros recalculés selon la quantité choisie
- **Suppression étape Préférences** :
  - Flow réduit de 9 à 8 étapes
  - Étape "Préférences alimentaires" retirée (plus pertinente avec planning détaillé)
  - `preferences_step.dart` n'est plus utilisé dans le flow

## 2026-01-29 (Suite 3) - Amélioration DietCreationFlow

- **DietCreationFlow étendu** - Flow enrichi de 6 à 9 étapes avec fonctionnalités avancées
  - **Nouvelles étapes** :
    - Étape 6 : Noms des repas (personnalisation noms + icônes + réorganisation)
    - Étape 7 : Planification repas (Training/Repos + ajout aliments)
    - Étape 8 : Compléments alimentaires (catalogue + dosage + notifications)
  - **Nouveaux fichiers créés** :
    - `models/diet_models.dart` : FoodEntry, MealPlan, SupplementEntry, SupplementCatalog
    - `widgets/day_type_toggle.dart` : Toggle Training/Repos réutilisable
    - `steps/meal_names_step.dart` : Personnalisation noms repas avec drag-drop
    - `steps/meal_planning_step.dart` : Planning avec toggle jour + macro dashboard
    - `steps/supplements_step.dart` : Catalogue compléments avec config dosage/timing
  - **Meal Names Step** (Étape 6) :
    - Liste ReorderableListView pour réordonner les repas
    - TextField éditable pour chaque nom de repas
    - Icon picker bottom sheet avec 8 icônes disponibles
    - Numérotation automatique avec badge vert
  - **Meal Planning Step** (Étape 7) :
    - DayTypeToggle : Training (orange) / Repos (vert)
    - Macro dashboard temps réel (calories + P/C/F avec barres progression)
    - Cards repas expandables par jour type
    - Bouton "Copier Training → Repos"
    - Intégration FoodLibrarySheet existant
    - Étape optionnelle (bouton "Passer")
  - **Supplements Step** (Étape 8) :
    - Catalogue 8 compléments : Créatine, Whey, BCAA, Multivitamines, Oméga-3, Vit D, Zinc, Magnésium
    - Chips sélectionnables pour ajouter/retirer
    - Card par complément avec :
      - Dosage éditable (bottom sheet)
      - Timing picker : Matin, Pré-workout, Post-workout, Soir, Avec repas
      - Toggle notifications avec time picker
    - Étape optionnelle
  - **Models créés** :
    - `FoodEntry` : id, name, quantity, calories, protein, carbs, fat, unit
    - `MealPlan` : name, icon, foods[] avec getters totalCalories/Protein/Carbs/Fat
    - `SupplementEntry` : id, name, icon, dosage, timing, notificationsEnabled, reminderTime
    - `SupplementTiming` : enum avec labels français
    - `SupplementCatalog` : catalogue statique avec defaults
  - **DietSuccessModal mis à jour** :
    - Nouveau paramètre `supplementsCount`
    - Affiche nombre de compléments si > 0
  - **State étendu dans diet_creation_flow.dart** :
    - `_mealNames`, `_mealIcons` : noms et icônes personnalisés
    - `_trainingDayMeals`, `_restDayMeals` : plans repas par type de jour
    - `_supplements` : liste compléments configurés
    - Synchronisation automatique entre meals count et meal plans
  - `flutter analyze` : ✅ Pas d'erreurs dans les nouveaux fichiers

## 2026-01-29 (Suite 2) - Flow Création Diète

- **DietCreationFlow** - Nouveau flow complet de création de diète (`lib/features/nutrition/create/`)
  - **Structure créée** :
    - `diet_creation_flow.dart` : Orchestrateur principal avec PageView 6 étapes
    - `steps/` : 6 fichiers pour chaque étape
    - `sheets/` : Modal de succès
  - **Bouton "+"** remplace le bouton IA dans le header de NutritionScreen
    - Couleur verte (nutrition theme)
    - Navigation slide-up vers DietCreationFlow
  - **Étape 1 - Nom** (`name_step.dart`) :
    - Champ texte glassmorphism
    - Suggestions chips : "Plan Prise", "Diète Sèche", "Nutrition Équilibre", "Plan Perso"
    - Chips verts quand sélectionnés (thème nutrition)
  - **Étape 2 - Objectif** (`goal_step.dart`) :
    - 3 cards sélectionnables avec icônes et descriptions :
      - Prise de masse (trending_up, orange)
      - Sèche (trending_down, bleu)
      - Maintien (remove, vert)
    - Animation glow + bordure couleur quand sélectionné
    - Met à jour automatiquement les calories par défaut
  - **Étape 3 - Calories** (`calories_step.dart`) :
    - 2 cards : Jour Training (orange) + Jour Repos (vert)
    - Boutons +/- (±50 kcal) pour ajustement rapide
    - Tap sur valeur → ListWheelScrollView picker (1000-5000 kcal)
    - Indicateur de différence entre jours
    - Haptic feedback sur sélection
  - **Étape 4 - Macros** (`macros_step.dart`) :
    - 3 presets : "Équilibré" (30/45/25), "High Protein" (40/35/25), "Low Carb" (35/25/40)
    - 3 sliders P/C/F avec couleurs distinctes (rouge/bleu/jaune)
    - Validation total = 100% avec warning si != 100%
    - Affichage grammes calculés en temps réel
    - Card résumé avec badges P/C/F colorés
  - **Étape 5 - Repas** (`meals_step.dart`) :
    - Sélecteur horizontal : 3, 4, 5 ou 6 repas
    - Cards sélectionnables avec glow vert
    - Preview liste des repas avec icônes (soleil, resto, pomme, lune)
    - Noms dynamiques selon choix (Petit-déjeuner, Collation AM, Déjeuner, Collation PM, Dîner, Collation soir)
    - Info tip sur l'impact du nombre de repas
  - **Étape 6 - Préférences** (`preferences_step.dart`) :
    - Section restrictions (rouge) : Végétarien, Vegan, Sans gluten, Sans lactose
    - Section préférences aliments (vert) : Poulet, Poisson, Boeuf, Oeufs, Riz, Pâtes, Légumes, Fruits
    - Multi-select avec chips animés
    - Étape optionnelle (bouton "Passer" disponible)
  - **DietSuccessModal** (`sheets/diet_success_modal.dart`) :
    - Animation scale elasticOut
    - Icône restaurant_menu dans cercle vert
    - Stats : objectif + kcal + repas/jour
    - Bouton "Parfait" vert
  - **Orchestrateur** (`diet_creation_flow.dart`) :
    - Mesh gradient vert/teal pulsant (4s cycle)
    - Header avec bouton retour/fermer + indicateur étape X/6
    - Progress bar 6 segments avec glow sur actif
    - Validation par étape (nom requis, macros = 100%, etc.)
    - Mise à jour automatique des calories selon objectif
  - **NutritionScreen modifié** :
    - Import DietCreationFlow
    - Méthode `_openDietCreation()` avec slide transition
    - Bouton header : icône `add_rounded`, couleur verte, glow vert
  - `flutter analyze` : ✅ Pas d'erreurs dans les nouveaux fichiers

## 2026-01-29
- **Refactoring ProgramCreationFlow** - Extraction modulaire (2,832 → 280 lignes, -90%)
  - **Structure créée** : `lib/features/workout/create/`
    - `utils/` : 2 fichiers
    - `widgets/` : 6 fichiers
    - `sheets/` : 3 fichiers
    - `steps/` : 4 fichiers
  - **Utils** :
    - `exercise_catalog.dart` : Catalogue 20 exercices + groupes musculaires
    - `exercise_calculator.dart` : Calcul séries RPT/Pyramidal/Dropset/Classic + labels
  - **Widgets réutilisables** :
    - `number_picker.dart` : NumberPicker (compact) + ExpandedNumberPicker (forms)
    - `toggle_card.dart` : ToggleCard glassmorphism avec icône + switch animé
    - `mode_card.dart` : ModeCard pour sélection mode entraînement
    - `day_tabs.dart` : DayTabs pour navigation jours avec compteurs
    - `exercise_catalog_picker.dart` : Sélecteur exercices par groupe musculaire
    - `day_exercise_list.dart` : Liste réordonnables avec supersets
  - **Sheets** :
    - `success_modal.dart` : Modal succès avec animation scale + stats
    - `custom_exercise_sheet.dart` : Création exercice personnalisé
    - `exercise_config_sheet.dart` : Configuration mode/sets/reps/warmup
  - **Steps** :
    - `name_step.dart` : Étape 1 - Nom programme avec suggestions
    - `cycle_step.dart` : Étape 2 - Toggle cycle + config deload
    - `days_step.dart` : Étape 3 - Sélection jours entraînement
    - `exercises_step.dart` : Étape 4 - Configuration exercices par jour
  - **Orchestrateur** : `program_creation_flow.dart` réduit à ~280 lignes
    - État centralisé avec setState
    - Callbacks passés aux composants enfants
    - Navigation PageView + indicateur progression
  - **Total** : 15 nouveaux fichiers, architecture maintenable
  - `flutter analyze lib/features/workout/create/` : ✅ 0 issues

## 2026-01-29 (Suite) - Écran Social
- **SocialScreen** - Nouvel écran social complet avec Feed et Défis (`lib/features/social/social_screen.dart`)
  - **Navigation** : 6ème onglet "Social" ajouté entre Workout et Nutrition dans MainNavigation
  - **Structure feature** : models/, widgets/, sheets/, painters/

### Feed - Voir les séances des potes
- **ActivityCard** : Carte de séance d'un ami avec :
  - Header : Avatar + nom + workout name + timestamp relatif
  - **PRBadge** : Banner vert si nouveau PR avec exercice, poids et gain (+Xkg)
  - Muscles travaillés + stats (durée, volume, exos)
  - Top 3 exercices avec poids×reps dans chips compacts
  - Section respect : compteur + liste "Mike, Julie et X autres"
- **RespectButton** : Alternative au "like" avec culture gym
  - Icône haltère (fitness_center)
  - Animation scale 1.0→1.3→1.0 au tap
  - Glow orange pulsé
  - Haptic feedback mediumImpact
  - État respecté : fond orange, bordure accent
- **ActivityDetailSheet** : Bottom sheet détail complet
  - Stats grid (Durée/Volume/Exercices/Muscles)
  - Liste complète des exercices avec poids×reps
  - Section respect avec liste des noms

### Défis - Compétitions entre potes
- **ChallengeCard** : Carte de défi avec :
  - Header status : DÉFI ACTIF (orange) / TERMINÉ (vert) / EXPIRÉ (gris)
  - Badge temps restant ("3j restants")
  - Titre défi + exercice cible
  - Créateur + **ParticipantAvatars** (avatars empilés avec +N)
  - Leaderboard top 3 avec médailles 🥇🥈🥉
  - Progression % et valeur courante
  - Boutons "VOIR DÉTAILS" / "PARTICIPER"
- **ChallengeDetailSheet** : Bottom sheet détail complet
  - **ChallengeProgressPainter** : Ring circulaire avec progression leader
  - Info objectif/participants/deadline
  - Classement complet avec barres de progression
  - Avatars et status "Complété" pour les gagnants
- **CreateChallengeSheet** : Flow multi-étapes (4 étapes)
  - **Étape 1 - Type** : 4 options avec icônes
    - Défi poids (fitness_center) : Premier à X kg
    - Défi reps (repeat) : Max reps à X kg
    - Défi temps (timer) : Meilleur temps pour X reps
    - Défi libre (edit_note) : Description custom
  - **Étape 2 - Config** : Dropdown exercice + picker valeur + date limite optionnelle
  - **Étape 3 - Inviter** : Liste amis multi-select avec avatars + online status
  - **Étape 4 - Confirmer** : Preview card récap + liste participants chips
- **FAB** : Bouton + flottant visible uniquement sur l'onglet Défis

### Models
- **Activity** : id, userName, workoutName, muscles, duration, volume, exerciseCount, topExercises, pr, respectCount, respectGivers
- **ExerciseSummary** : name, shortName, weightKg, reps
- **PersonalRecord** : exerciseName, value, gain, unit
- **Challenge** : id, title, exerciseName, type, targetValue, unit, deadline, status, creator, participants
- **ChallengeType** : enum (weight, reps, time, custom)
- **ChallengeStatus** : enum (active, completed, expired)
- **ChallengeParticipant** : id, name, avatarUrl, currentValue, hasCompleted
- **Friend** : id, name, avatarUrl, isOnline, lastActive, totalWorkouts, streak

### Widgets & Painters
- **RespectButton** : Bouton respect animé avec glow
- **PRBadge** : Badge PR avec icône trophée et gain
- **ParticipantAvatars** : Avatars empilés avec overflow +N
- **ActivityCard** : Carte activité complète
- **ChallengeCard** : Carte défi avec leaderboard
- **ChallengeProgressPainter** : CustomPainter ring progression

### Sheets
- **ActivityDetailSheet** : Détail activité avec stats et exercices
- **ChallengeDetailSheet** : Détail défi avec classement
- **CreateChallengeSheet** : Flow création 4 étapes
- **FriendsListSheet** : Sélection amis avec recherche

### Mock Data
- 4 activités de potes (Thomas, Julie, Marc, Sarah) avec workouts variés
- 3 défis actifs (100kg bench, 20 tractions, 200kg squat)
- 5 amis avec statuts online/offline

## 2026-01-28
- **ProgramCreationFlow - Modes d'entraînement avancés** (`lib/features/workout/create/program_creation_flow.dart`)
  - **4 modes d'entraînement** par exercice avec calcul automatique :
    - Classique : Sets × Reps standards avec poids constant
    - RPT (Reverse Pyramid) : -10% poids, -2 reps par série
    - Pyramidal : Montée progressive 70%→100%, puis descente avec plus de reps
    - Dropset : 1 série lourde + 3 drops (-20%, -40%, -60%) avec +2 reps
  - **Échauffement adaptatif** : Toggle par exercice avec séries adaptées au mode
    - RPT : 2 séries (60%×8, 80%×5)
    - Classique/Dropset : 1 série (50%×10)
    - Pyramidal : Intégré dans la progression
    - Badge "WARMUP" jaune sur séries d'échauffement
  - **Supersets** : Liaison de 2+ exercices pour exécution consécutive
    - Long-press pour sélectionner exercices
    - Bouton "Créer superset" avec glow vert
    - Bordure verte + badge "S1", "S2" sur exercices liés
    - Pas de repos entre exercices du superset pendant workout
  - **Bottom sheet configuration avancée** :
    - 4 cards mode avec icône + description (Icons: fitness_center, trending_down, trending_up, arrow_downward)
    - Sélecteurs sets/reps pour modes Classic/RPT
    - Toggle échauffement avec description dynamique
    - **Preview table** temps réel : toutes séries + poids % + reps calculés
    - Badge "W" jaune pour séries warmup dans preview
    - Bouton "Config" avec icône tune sur chaque exercice
  - Labels mode affichés sur exercices (RPT, Pyramidal, Dropset)
  - Sélection visuelle pour superset (background vert translucide)
  - Tracking supersets par jour avec indices groupés
  - Calcul preview adaptatif selon mode choisi
- **ActiveWorkoutScreen** - Écran de tracking workout en temps réel (`lib/features/workout/tracking/active_workout_screen.dart`)
  - **Concept** : Interface "Cockpit de Performance" inspirée des tableaux de bord automobiles premium
  - **Header dynamique** :
    - Bouton fermer avec confirmation de sortie
    - Nom exercice + muscle badge coloré
    - Indicateur position (X/Y exercices)
    - Timer total de séance en temps réel (format MM:SS ou Xh MM)
  - **Navigation exercices** :
    - Dots indicators animés avec glow
    - Dot actif élargi + couleur accent
    - Dots complétés en vert
    - Tap sur dot pour naviguer entre exercices
  - **Carte série principale** :
    - Badge "ÉCHAUFFEMENT" jaune pour warmup sets
    - Indicateur "SÉRIE X" pour séries de travail
    - Affichage hero : Poids (orange 56px italic) × Reps (blanc 56px italic)
    - Indicateur record personnel avec icône trophée
  - **Zone d'entrée poids/reps** :
    - 2 cards glassmorphism côte à côte (Poids / Reps)
    - Boutons +/- pour ajustement rapide (±2.5kg / ±1 rep)
    - Tap sur valeur → bottom sheet avec clavier numérique et presets
    - Haptic feedback à chaque interaction
  - **Bouton valider série** :
    - Animation pulse subtile (0.95-1.0 scale)
    - Glow neon orange
    - Déclenche timer de repos après validation
  - **Progression séries** :
    - Indicateurs visuels pour chaque série (warmup icône, numéros)
    - Série active avec bordure accent + background
    - Séries complétées en vert avec check
    - Tap pour naviguer entre séries
  - **Stats live** :
    - Barre de stats : Volume (tonnes), Séries, Kcal estimées
    - Mise à jour en temps réel à chaque série validée
  - **Vue repos** :
    - Grand timer circulaire CustomPainter avec ring progression
    - Affichage minutes:secondes au centre (64px)
    - Preview prochaine série ou prochain exercice
    - Contrôles : +30s / Skip (bouton accent)
    - Haptic à 10s, 5s, 3s, 2s, 1s, 0s (intensité croissante)
  - **Célébration PR** :
    - Overlay fullscreen avec fond vert translucide
    - Icône trophée avec glow pulsant
    - Animation scale-in du texte "NOUVEAU RECORD !"
    - Triple haptic feedback
  - **Bottom sheets** :
    - NumberPickerSheet : clavier numérique + presets rapides
    - WorkoutCompleteSheet : récap durée/volume/kcal avec trophée
    - ExitConfirmationSheet : warning avec choix continuer/quitter
  - **Mock data** : 5 exercices leg day complets (Squat, Presse, Leg Ext, Leg Curl, Mollets)
  - **CustomPainter** : _RestTimerPainter avec track, progression et glow end-point
  - Mesh gradient dynamique (couleur change repos/actif : vert/orange)
- **WorkoutScreen** mis à jour :
  - Import ActiveWorkoutScreen
  - Méthode _startWorkout() avec slide transition
  - Bouton play et card "Next Session" déclenchent le tracking
