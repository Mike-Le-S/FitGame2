import { jsPDF } from 'jspdf'
import type { Program, DietPlan, MuscleGroup, Goal, ExerciseMode } from '@/types'

// FitGame brand colors
const COLORS = {
  accent: [255, 107, 53] as [number, number, number],     // #FF6B35
  background: [10, 10, 10] as [number, number, number],   // #0a0a0a
  surface: [20, 20, 20] as [number, number, number],      // #141414
  text: [255, 255, 255] as [number, number, number],      // white
  textMuted: [156, 163, 175] as [number, number, number], // gray-400
  success: [34, 197, 94] as [number, number, number],     // green
  warning: [234, 179, 8] as [number, number, number],     // yellow
  info: [59, 130, 246] as [number, number, number],       // blue
}

// Translations
const goalLabels: Record<Goal, string> = {
  bulk: 'Prise de masse',
  cut: 'Sèche',
  maintain: 'Maintien',
  strength: 'Force',
  endurance: 'Endurance',
  recomp: 'Recomposition',
  other: 'Autre',
}

const muscleLabels: Record<MuscleGroup, string> = {
  chest: 'Pectoraux',
  back: 'Dos',
  shoulders: 'Épaules',
  biceps: 'Biceps',
  triceps: 'Triceps',
  forearms: 'Avant-bras',
  quads: 'Quadriceps',
  hamstrings: 'Ischio-jambiers',
  glutes: 'Fessiers',
  calves: 'Mollets',
  abs: 'Abdominaux',
  cardio: 'Cardio',
}

const modeLabels: Record<ExerciseMode, string> = {
  classic: 'Classique',
  rpt: 'RPT',
  pyramidal: 'Pyramidal',
  dropset: 'Dropset',
}

export function exportProgramToPDF(program: Program, coachName?: string): void {
  const doc = new jsPDF()
  const pageWidth = doc.internal.pageSize.getWidth()
  const pageHeight = doc.internal.pageSize.getHeight()
  const margin = 20
  const contentWidth = pageWidth - margin * 2
  let y = margin

  // Helper to add new page if needed
  const checkPageBreak = (neededHeight: number) => {
    if (y + neededHeight > pageHeight - margin) {
      doc.addPage()
      y = margin
      return true
    }
    return false
  }

  // Header with gradient effect (simulated with rectangle)
  doc.setFillColor(...COLORS.accent)
  doc.rect(0, 0, pageWidth, 45, 'F')

  // Logo text
  doc.setTextColor(255, 255, 255)
  doc.setFontSize(24)
  doc.setFont('helvetica', 'bold')
  doc.text('FitGame', margin, 22)

  doc.setFontSize(10)
  doc.setFont('helvetica', 'normal')
  doc.text('Programme d\'entraînement', margin, 32)

  // Program title
  y = 60
  doc.setTextColor(0, 0, 0)
  doc.setFontSize(20)
  doc.setFont('helvetica', 'bold')
  doc.text(program.name, margin, y)

  // Metadata row
  y += 12
  doc.setFontSize(10)
  doc.setFont('helvetica', 'normal')
  doc.setTextColor(100, 100, 100)

  const metadata = [
    `Objectif: ${goalLabels[program.goal] || program.goal}`,
    `Durée: ${program.durationWeeks} semaines`,
    `${program.days.filter(d => !d.isRestDay).length} jours d'entraînement`,
  ]
  if (program.deloadFrequency) {
    metadata.push(`Deload: toutes les ${program.deloadFrequency} semaines`)
  }

  doc.text(metadata.join('  •  '), margin, y)

  // Coach info
  if (coachName) {
    y += 6
    doc.text(`Créé par: ${coachName}`, margin, y)
  }

  // Description
  if (program.description) {
    y += 10
    doc.setTextColor(60, 60, 60)
    doc.setFontSize(10)
    const descLines = doc.splitTextToSize(program.description, contentWidth)
    doc.text(descLines, margin, y)
    y += descLines.length * 5
  }

  // Separator
  y += 8
  doc.setDrawColor(220, 220, 220)
  doc.line(margin, y, pageWidth - margin, y)
  y += 10

  // Days
  for (const day of program.days) {
    checkPageBreak(50)

    // Day header
    doc.setFillColor(245, 245, 245)
    doc.roundedRect(margin, y - 4, contentWidth, 14, 2, 2, 'F')

    doc.setTextColor(0, 0, 0)
    doc.setFontSize(12)
    doc.setFont('helvetica', 'bold')
    doc.text(day.name, margin + 4, y + 5)

    if (day.isRestDay) {
      doc.setFont('helvetica', 'italic')
      doc.setTextColor(100, 100, 100)
      doc.text('Jour de repos', margin + 80, y + 5)
    }

    y += 16

    if (!day.isRestDay && day.exercises.length > 0) {
      // Exercises table header
      doc.setFontSize(8)
      doc.setFont('helvetica', 'bold')
      doc.setTextColor(100, 100, 100)

      const colWidths = [70, 35, 50, 15]
      let x = margin

      doc.text('EXERCICE', x, y)
      x += colWidths[0]
      doc.text('MUSCLE', x, y)
      x += colWidths[1]
      doc.text('SETS × REPS @ POIDS', x, y)
      x += colWidths[2]
      doc.text('MODE', x, y)

      y += 6

      // Exercises
      doc.setFont('helvetica', 'normal')
      doc.setFontSize(9)

      for (const exercise of day.exercises) {
        checkPageBreak(8)

        x = margin
        doc.setTextColor(0, 0, 0)

        // Exercise name (truncate if too long)
        const exName = exercise.name.length > 28 ? exercise.name.substring(0, 25) + '...' : exercise.name
        doc.text(exName, x, y)
        x += colWidths[0]

        // Muscle
        doc.setTextColor(80, 80, 80)
        doc.text(muscleLabels[exercise.muscle] || exercise.muscle, x, y)
        x += colWidths[1]

        // Sets info
        const workingSets = exercise.sets.filter(s => !s.isWarmup)
        if (workingSets.length > 0) {
          const firstSet = workingSets[0]
          const setsInfo = `${workingSets.length} × ${firstSet.targetReps} @ ${firstSet.targetWeight}kg`
          doc.text(setsInfo, x, y)
        } else {
          doc.text('-', x, y)
        }
        x += colWidths[2]

        // Mode
        doc.text(modeLabels[exercise.mode] || exercise.mode, x, y)

        y += 6

        // Notes if any
        if (exercise.notes) {
          checkPageBreak(6)
          doc.setFontSize(8)
          doc.setTextColor(120, 120, 120)
          doc.setFont('helvetica', 'italic')
          const noteLines = doc.splitTextToSize(`Note: ${exercise.notes}`, contentWidth - 10)
          doc.text(noteLines, margin + 5, y)
          y += noteLines.length * 4
          doc.setFont('helvetica', 'normal')
          doc.setFontSize(9)
        }
      }
    }

    y += 8
  }

  // Footer on last page
  const addFooter = () => {
    doc.setFontSize(8)
    doc.setTextColor(150, 150, 150)
    const date = new Date().toLocaleDateString('fr-FR', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    })
    doc.text(`Généré le ${date} via FitGame Coach`, margin, pageHeight - 10)
    doc.text(`Page ${doc.internal.pages.length - 1}`, pageWidth - margin - 15, pageHeight - 10)
  }

  addFooter()

  // Save
  const filename = `${program.name.replace(/[^a-zA-Z0-9]/g, '_')}_programme.pdf`
  doc.save(filename)
}

export function exportDietPlanToPDF(dietPlan: DietPlan, coachName?: string): void {
  const doc = new jsPDF()
  const pageWidth = doc.internal.pageSize.getWidth()
  const pageHeight = doc.internal.pageSize.getHeight()
  const margin = 20
  const contentWidth = pageWidth - margin * 2
  let y = margin

  const checkPageBreak = (neededHeight: number) => {
    if (y + neededHeight > pageHeight - margin) {
      doc.addPage()
      y = margin
      return true
    }
    return false
  }

  // Header
  doc.setFillColor(...COLORS.success)
  doc.rect(0, 0, pageWidth, 45, 'F')

  doc.setTextColor(255, 255, 255)
  doc.setFontSize(24)
  doc.setFont('helvetica', 'bold')
  doc.text('FitGame', margin, 22)

  doc.setFontSize(10)
  doc.setFont('helvetica', 'normal')
  doc.text('Plan nutritionnel', margin, 32)

  // Plan title
  y = 60
  doc.setTextColor(0, 0, 0)
  doc.setFontSize(20)
  doc.setFont('helvetica', 'bold')
  doc.text(dietPlan.name, margin, y)

  // Metadata
  y += 12
  doc.setFontSize(10)
  doc.setFont('helvetica', 'normal')
  doc.setTextColor(100, 100, 100)
  doc.text(`Objectif: ${goalLabels[dietPlan.goal] || dietPlan.goal}`, margin, y)

  if (coachName) {
    y += 6
    doc.text(`Créé par: ${coachName}`, margin, y)
  }

  // Macros boxes
  y += 15

  const boxWidth = (contentWidth - 10) / 2
  const boxHeight = 35

  // Training day box
  doc.setFillColor(240, 253, 244) // light green
  doc.roundedRect(margin, y, boxWidth, boxHeight, 3, 3, 'F')
  doc.setDrawColor(34, 197, 94)
  doc.roundedRect(margin, y, boxWidth, boxHeight, 3, 3, 'S')

  doc.setTextColor(34, 197, 94)
  doc.setFontSize(10)
  doc.setFont('helvetica', 'bold')
  doc.text('JOUR D\'ENTRAÎNEMENT', margin + 5, y + 8)

  doc.setTextColor(0, 0, 0)
  doc.setFontSize(14)
  doc.text(`${dietPlan.trainingCalories} kcal`, margin + 5, y + 18)

  doc.setFontSize(9)
  doc.setTextColor(80, 80, 80)
  doc.text(
    `P: ${dietPlan.trainingMacros.protein}g  C: ${dietPlan.trainingMacros.carbs}g  F: ${dietPlan.trainingMacros.fat}g`,
    margin + 5,
    y + 28
  )

  // Rest day box
  const restBoxX = margin + boxWidth + 10
  doc.setFillColor(254, 249, 195) // light yellow
  doc.roundedRect(restBoxX, y, boxWidth, boxHeight, 3, 3, 'F')
  doc.setDrawColor(234, 179, 8)
  doc.roundedRect(restBoxX, y, boxWidth, boxHeight, 3, 3, 'S')

  doc.setTextColor(180, 140, 0)
  doc.setFontSize(10)
  doc.setFont('helvetica', 'bold')
  doc.text('JOUR DE REPOS', restBoxX + 5, y + 8)

  doc.setTextColor(0, 0, 0)
  doc.setFontSize(14)
  doc.text(`${dietPlan.restCalories} kcal`, restBoxX + 5, y + 18)

  doc.setFontSize(9)
  doc.setTextColor(80, 80, 80)
  doc.text(
    `P: ${dietPlan.restMacros.protein}g  C: ${dietPlan.restMacros.carbs}g  F: ${dietPlan.restMacros.fat}g`,
    restBoxX + 5,
    y + 28
  )

  y += boxHeight + 15

  // Separator
  doc.setDrawColor(220, 220, 220)
  doc.line(margin, y, pageWidth - margin, y)
  y += 10

  // Meals
  if (dietPlan.meals.length > 0) {
    doc.setTextColor(0, 0, 0)
    doc.setFontSize(14)
    doc.setFont('helvetica', 'bold')
    doc.text('Repas', margin, y)
    y += 10

    for (const meal of dietPlan.meals) {
      checkPageBreak(30)

      // Meal header
      doc.setFillColor(245, 245, 245)
      doc.roundedRect(margin, y - 4, contentWidth, 12, 2, 2, 'F')

      doc.setTextColor(0, 0, 0)
      doc.setFontSize(11)
      doc.setFont('helvetica', 'bold')
      doc.text(meal.name, margin + 4, y + 4)

      if (meal.targetTime) {
        doc.setFont('helvetica', 'normal')
        doc.setTextColor(100, 100, 100)
        doc.text(meal.targetTime, pageWidth - margin - 30, y + 4)
      }

      y += 14

      // Foods
      if (meal.foods.length > 0) {
        doc.setFontSize(9)
        doc.setFont('helvetica', 'normal')

        for (const food of meal.foods) {
          checkPageBreak(8)

          doc.setTextColor(0, 0, 0)
          doc.text(`• ${food.name}`, margin + 5, y)

          doc.setTextColor(100, 100, 100)
          const foodInfo = `${food.quantity}${food.unit} - ${food.calories}kcal (P:${food.macros.protein}g C:${food.macros.carbs}g F:${food.macros.fat}g)`
          doc.text(foodInfo, margin + 60, y)

          y += 6
        }
      }

      y += 6
    }
  }

  // Supplements
  if (dietPlan.supplements && dietPlan.supplements.length > 0) {
    checkPageBreak(40)

    y += 5
    doc.setTextColor(0, 0, 0)
    doc.setFontSize(14)
    doc.setFont('helvetica', 'bold')
    doc.text('Suppléments', margin, y)
    y += 10

    doc.setFontSize(9)
    doc.setFont('helvetica', 'normal')

    for (const supp of dietPlan.supplements) {
      checkPageBreak(8)

      doc.setTextColor(0, 0, 0)
      doc.text(`• ${supp.name}`, margin + 5, y)

      doc.setTextColor(100, 100, 100)
      const timingLabels: Record<string, string> = {
        morning: 'Matin',
        'pre-workout': 'Pré-entraînement',
        'post-workout': 'Post-entraînement',
        evening: 'Soir',
        'with-meal': 'Avec repas',
      }
      doc.text(`${supp.dosage} - ${timingLabels[supp.timing] || supp.timing}`, margin + 60, y)

      y += 6
    }
  }

  // Notes
  if (dietPlan.notes) {
    checkPageBreak(30)

    y += 10
    doc.setTextColor(0, 0, 0)
    doc.setFontSize(12)
    doc.setFont('helvetica', 'bold')
    doc.text('Notes', margin, y)
    y += 8

    doc.setFontSize(9)
    doc.setFont('helvetica', 'normal')
    doc.setTextColor(60, 60, 60)
    const noteLines = doc.splitTextToSize(dietPlan.notes, contentWidth)
    doc.text(noteLines, margin, y)
  }

  // Footer
  doc.setFontSize(8)
  doc.setTextColor(150, 150, 150)
  const date = new Date().toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
  doc.text(`Généré le ${date} via FitGame Coach`, margin, pageHeight - 10)

  // Save
  const filename = `${dietPlan.name.replace(/[^a-zA-Z0-9]/g, '_')}_nutrition.pdf`
  doc.save(filename)
}
