// Goal configuration used across the application
// Centralized to avoid duplication

export const goalConfig = {
  bulk: { label: 'Prise de masse', color: 'success', icon: '📈', desc: 'Surplus calorique contrôlé' },
  cut: { label: 'Sèche', color: 'warning', icon: '🔥', desc: 'Déficit calorique modéré' },
  maintain: { label: 'Maintien', color: 'info', icon: '⚖️', desc: 'Équilibre énergétique' },
  strength: { label: 'Force', color: 'default', icon: '💪', desc: 'Protéines élevées, énergie' },
  endurance: { label: 'Endurance', color: 'info', icon: '🏃', desc: 'Glucides, récupération' },
  recomp: { label: 'Recomposition', color: 'success', icon: '🔄', desc: 'Équilibre, timing précis' },
  other: { label: 'Autre', color: 'default', icon: '🎯', desc: 'Plan personnalisé' },
} as const

export type GoalType = keyof typeof goalConfig

// Extended config with 'all' option for filter UIs
export const goalFilterConfig = {
  all: { label: 'Tous' },
  ...goalConfig,
} as const

export type FilterGoalType = keyof typeof goalFilterConfig
