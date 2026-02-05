# Nutrition Screen Upgrade - Design Document

**Date:** 2026-02-05
**Status:** Approved
**Author:** Mike + Claude

---

## Overview

Refonte de l'écran Nutrition pour ajouter :
- A) Bilan calories (consommé vs brûlé via Apple Santé)
- B) Séparation Plan (template) vs Tracking (réel)
- C) Ajout d'aliments rapide (scanner, favoris, templates)

---

## A) Bilan Calories

### Card "Bilan du jour"

Position : En haut de l'écran, après le day selector, avant les repas.

```
┌─────────────────────────────────────────┐
│  📊 BILAN DU JOUR                       │
│                                         │
│  Consommé        Brûlé        Balance   │
│  1 850 kcal      2 340 kcal   -490 kcal │
│  ██████████░░    (Apple Santé)  ✓ Déficit│
│                                         │
│  ─────────────────────────────────────  │
│  Prédiction fin de journée: ~2 650 kcal │
│  Basé sur tes 7 derniers jours          │
└─────────────────────────────────────────┘
```

### Logique prédiction
- Récupérer calories brûlées des 7 derniers jours
- Calculer le ratio actuel (ex: à 14h = ~50% du total journalier)
- Extrapoler : `calories_actuelles / ratio_moyen`

### Couleurs selon objectif
| Objectif | Déficit | Surplus |
|----------|---------|---------|
| Cut | Vert ✓ | Orange ⚠ |
| Bulk | Orange ⚠ | Vert ✓ |
| Maintain | Neutre | Neutre |

---

## B) Plan vs Tracking

### Concepts

- **Plan** = Template de ce qu'on doit manger (inchangé)
- **Tracking** = Ce qu'on a réellement mangé ce jour-là

### Nouvelle table `daily_nutrition_logs`

```sql
CREATE TABLE daily_nutrition_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  date DATE NOT NULL,
  diet_plan_id UUID REFERENCES diet_plans,
  meals JSONB NOT NULL DEFAULT '[]',
  calories_consumed INT DEFAULT 0,
  calories_burned INT,
  calories_burned_predicted INT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);
```

### Workflow

1. Utilisateur ouvre l'écran Nutrition
2. On charge le log du jour (ou on le crée depuis le plan actif)
3. Modifications des quantités → sauvegardées dans le log
4. Le plan template reste intact

### UI Changes

- Menu ⋯ dans le header avec :
  - "Éditer le plan actif"
  - "Créer un nouveau plan"
  - "Mes plans"
  - "Supprimer ce plan"
- Indicateur sur les aliments modifiés : "120g / 150g prévu"

---

## C) Ajout d'aliments rapide

### Nouveau sheet d'ajout

```
┌─────────────────────────────────────────┐
│  Ajouter un aliment                     │
│                                         │
│  [🔍 Rechercher...]                     │
│                                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│  │ 📷      │ │ ⭐       │ │ 📋       │ │
│  │ Scanner │ │ Favoris  │ │ Template │ │
│  └──────────┘ └──────────┘ └──────────┘ │
│                                         │
│  RÉCENTS                                │
│  ├─ 🥚 Œufs (x3)           45 kcal     │
│  ├─ 🍚 Riz basmati 150g    180 kcal    │
│  └─ 🥛 Whey 30g            120 kcal    │
└─────────────────────────────────────────┘
```

### Scanner code-barres

Flow :
1. Scanner le code-barres
2. Rechercher dans OpenFoodFacts API
3. Si trouvé → afficher infos, ajuster quantité, ajouter
4. Si pas trouvé → chercher dans `community_foods`
5. Si toujours pas → proposer contribution communautaire

### Contribution communautaire

```
┌───────────────────────────────────────┐
│  📸 Ajouter pour la communauté        │
│                                       │
│  Cet aliment sera partagé avec tous   │
│  les utilisateurs FitGame             │
│                                       │
│  1. Nom du produit: [___________]     │
│  2. 📷 Photo étiquette nutritionnelle │
│  3. Valeurs pour 100g:                │
│     - Calories: [___] kcal            │
│     - Protéines: [___] g              │
│     - Glucides: [___] g               │
│     - Lipides: [___] g                │
│                                       │
│  [Contribuer] [Annuler]               │
└───────────────────────────────────────┘
```

### Favoris

Table `user_favorite_foods` :
```sql
CREATE TABLE user_favorite_foods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  food_data JSONB NOT NULL,
  use_count INT DEFAULT 1,
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

- Triés par `use_count` DESC
- Un tap = ajoute avec quantité par défaut
- Long press = modifier quantité avant ajout

### Templates de repas

Table `meal_templates` :
```sql
CREATE TABLE meal_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  name VARCHAR(100) NOT NULL,
  foods JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

- Sauvegarder un repas existant comme template
- Un tap = ajoute tous les aliments du template

### Aliments communautaires

Table `community_foods` :
```sql
CREATE TABLE community_foods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  barcode VARCHAR(50) UNIQUE,
  name VARCHAR(200) NOT NULL,
  brand VARCHAR(100),
  nutrition_per_100g JSONB NOT NULL,
  image_url TEXT,
  contributed_by UUID REFERENCES auth.users,
  verified BOOLEAN DEFAULT FALSE,
  use_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Technical Implementation

### Nouveaux widgets

| Widget | Fichier |
|--------|---------|
| CalorieBalanceCard | `widgets/calorie_balance_card.dart` |
| FoodAddSheet | `sheets/food_add_sheet.dart` |
| BarcodeScannerSheet | `sheets/barcode_scanner_sheet.dart` |
| ContributeFoodSheet | `sheets/contribute_food_sheet.dart` |
| FavoriteFoodsSheet | `sheets/favorite_foods_sheet.dart` |
| MealTemplatesSheet | `sheets/meal_templates_sheet.dart` |
| PlanMenuSheet | `sheets/plan_menu_sheet.dart` |

### Fichiers à modifier

| Fichier | Changements |
|---------|-------------|
| `nutrition_screen.dart` | Ajouter CalorieBalanceCard, menu ⋯, logique tracking |
| `meal_card.dart` | Afficher quantité réelle vs prévue |
| `supabase_service.dart` | CRUD pour les 4 nouvelles tables |
| `health_service.dart` | Historique calories pour prédiction |

### Dépendances

```yaml
mobile_scanner: ^5.1.1  # Scanner code-barres
```

### API externe

- OpenFoodFacts : `https://world.openfoodfacts.org/api/v2/product/{barcode}`
- Gratuit, pas de clé API requise
- Bonne couverture France

---

## Migration Supabase

```sql
-- 1. daily_nutrition_logs
CREATE TABLE daily_nutrition_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  date DATE NOT NULL,
  diet_plan_id UUID REFERENCES diet_plans,
  meals JSONB NOT NULL DEFAULT '[]',
  calories_consumed INT DEFAULT 0,
  calories_burned INT,
  calories_burned_predicted INT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- 2. user_favorite_foods
CREATE TABLE user_favorite_foods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  food_data JSONB NOT NULL,
  use_count INT DEFAULT 1,
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. meal_templates
CREATE TABLE meal_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  name VARCHAR(100) NOT NULL,
  foods JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. community_foods
CREATE TABLE community_foods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  barcode VARCHAR(50) UNIQUE,
  name VARCHAR(200) NOT NULL,
  brand VARCHAR(100),
  nutrition_per_100g JSONB NOT NULL,
  image_url TEXT,
  contributed_by UUID REFERENCES auth.users,
  verified BOOLEAN DEFAULT FALSE,
  use_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE daily_nutrition_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorite_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_foods ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can CRUD own nutrition logs" ON daily_nutrition_logs
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can CRUD own favorite foods" ON user_favorite_foods
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can CRUD own meal templates" ON meal_templates
  FOR ALL USING (auth.uid() = user_id);

-- Community foods: everyone can read, authenticated can insert
CREATE POLICY "Anyone can read community foods" ON community_foods
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can contribute foods" ON community_foods
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
```

---

## Summary

| Feature | Priority | Complexity |
|---------|----------|------------|
| Bilan calories card | High | Medium |
| Plan vs Tracking séparation | High | High |
| Scanner code-barres | High | Medium |
| Contribution communautaire | Medium | Medium |
| Favoris | High | Low |
| Templates de repas | Medium | Low |
| Prédiction calories | Medium | Medium |
