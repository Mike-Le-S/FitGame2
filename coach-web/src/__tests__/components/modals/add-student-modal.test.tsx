import { describe, it, expect, vi, beforeEach, Mock } from 'vitest'
import { render, screen, fireEvent, waitFor } from '../../helpers/test-utils'
import userEvent from '@testing-library/user-event'
import { AddStudentModal } from '@/components/modals/add-student-modal'
import { useStudentsStore } from '@/store/students-store'
import { useProgramsStore } from '@/store/programs-store'
import { useNutritionStore } from '@/store/nutrition-store'

// Mock the stores
vi.mock('@/store/students-store', () => ({
  useStudentsStore: vi.fn(),
}))

vi.mock('@/store/programs-store', () => ({
  useProgramsStore: vi.fn(),
}))

vi.mock('@/store/nutrition-store', () => ({
  useNutritionStore: vi.fn(),
}))

const mockAddStudent = vi.fn()
const mockAssignProgramToStudent = vi.fn()
const mockAssignDietToStudent = vi.fn()

const mockPrograms = [
  { id: 'prog-1', name: 'Programme Force' },
  { id: 'prog-2', name: 'Programme Endurance' },
]

const mockDietPlans = [
  { id: 'diet-1', name: 'Plan Prise de masse' },
  { id: 'diet-2', name: 'Plan Seche' },
]

describe('AddStudentModal', () => {
  const defaultProps = {
    isOpen: true,
    onClose: vi.fn(),
  }

  beforeEach(() => {
    vi.clearAllMocks()
    mockAddStudent.mockResolvedValue('new-student-id')
    mockAssignProgramToStudent.mockResolvedValue(undefined)
    mockAssignDietToStudent.mockResolvedValue(undefined)

    ;(useStudentsStore as unknown as Mock).mockReturnValue({
      addStudent: mockAddStudent,
    })

    ;(useProgramsStore as unknown as Mock).mockReturnValue({
      programs: mockPrograms,
      assignToStudent: mockAssignProgramToStudent,
    })

    ;(useNutritionStore as unknown as Mock).mockReturnValue({
      dietPlans: mockDietPlans,
      assignToStudent: mockAssignDietToStudent,
    })
  })

  describe('rendering', () => {
    it('renders when isOpen is true', () => {
      render(<AddStudentModal {...defaultProps} />)

      expect(screen.getByText('Ajouter un élève')).toBeInTheDocument()
      expect(screen.getByText('Créer un nouveau profil élève')).toBeInTheDocument()
    })

    it('does not render when isOpen is false', () => {
      render(<AddStudentModal isOpen={false} onClose={defaultProps.onClose} />)

      expect(screen.queryByText('Ajouter un élève')).not.toBeInTheDocument()
    })

    it('renders all form fields', () => {
      render(<AddStudentModal {...defaultProps} />)

      expect(screen.getByPlaceholderText('Marie Laurent')).toBeInTheDocument()
      expect(screen.getByPlaceholderText('marie@email.com')).toBeInTheDocument()
      expect(screen.getByText('Prise de masse')).toBeInTheDocument()
      expect(screen.getByText('Sèche')).toBeInTheDocument()
      expect(screen.getByText('Maintien')).toBeInTheDocument()
    })

    it('renders program select with options', () => {
      render(<AddStudentModal {...defaultProps} />)

      expect(screen.getByText('Programme (optionnel)')).toBeInTheDocument()
      expect(screen.getByText('Aucun programme')).toBeInTheDocument()
      expect(screen.getByText('Programme Force')).toBeInTheDocument()
      expect(screen.getByText('Programme Endurance')).toBeInTheDocument()
    })

    it('renders diet plan select with options', () => {
      render(<AddStudentModal {...defaultProps} />)

      expect(screen.getByText('Plan nutrition (optionnel)')).toBeInTheDocument()
      expect(screen.getByText('Aucun plan')).toBeInTheDocument()
      expect(screen.getByText('Plan Prise de masse')).toBeInTheDocument()
      expect(screen.getByText('Plan Seche')).toBeInTheDocument()
    })

    it('renders submit and cancel buttons', () => {
      render(<AddStudentModal {...defaultProps} />)

      expect(screen.getByRole('button', { name: /créer l'élève/i })).toBeInTheDocument()
      expect(screen.getByRole('button', { name: /annuler/i })).toBeInTheDocument()
    })
  })

  describe('form inputs', () => {
    it('allows typing in name field', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const nameInput = screen.getByPlaceholderText('Marie Laurent')
      await user.type(nameInput, 'Jean Dupont')

      expect(nameInput).toHaveValue('Jean Dupont')
    })

    it('allows typing in email field', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const emailInput = screen.getByPlaceholderText('marie@email.com')
      await user.type(emailInput, 'jean@test.com')

      expect(emailInput).toHaveValue('jean@test.com')
    })

    it('allows selecting goal', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      // Default is 'maintain'
      const bulkButton = screen.getByRole('button', { name: 'Prise de masse' })
      await user.click(bulkButton)

      // Button should have the selected style
      expect(bulkButton).toHaveClass('bg-success/10')
    })

    it('allows selecting a program', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      // Get the first combobox (program select)
      const selects = screen.getAllByRole('combobox')
      const programSelect = selects[0]
      await user.selectOptions(programSelect, 'prog-1')

      expect(programSelect).toHaveValue('prog-1')
    })

    it('allows selecting a diet plan', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      // Get the second combobox (diet select)
      const selects = screen.getAllByRole('combobox')
      const dietSelect = selects[1]
      await user.selectOptions(dietSelect, 'diet-1')

      expect(dietSelect).toHaveValue('diet-1')
    })
  })

  describe('form validation', () => {
    it('submit button is disabled when name is empty', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const emailInput = screen.getByPlaceholderText('marie@email.com')
      await user.type(emailInput, 'test@email.com')

      const submitButton = screen.getByRole('button', { name: /créer l'élève/i })
      expect(submitButton).toBeDisabled()
    })

    it('submit button is disabled when email is empty', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const nameInput = screen.getByPlaceholderText('Marie Laurent')
      await user.type(nameInput, 'Jean Dupont')

      const submitButton = screen.getByRole('button', { name: /créer l'élève/i })
      expect(submitButton).toBeDisabled()
    })

    it('submit button is enabled when both name and email are filled', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const nameInput = screen.getByPlaceholderText('Marie Laurent')
      const emailInput = screen.getByPlaceholderText('marie@email.com')

      await user.type(nameInput, 'Jean Dupont')
      await user.type(emailInput, 'jean@test.com')

      const submitButton = screen.getByRole('button', { name: /créer l'élève/i })
      expect(submitButton).not.toBeDisabled()
    })
  })

  describe('form submission', () => {
    it('calls addStudent with form data on submit', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const nameInput = screen.getByPlaceholderText('Marie Laurent')
      const emailInput = screen.getByPlaceholderText('marie@email.com')

      await user.type(nameInput, 'Jean Dupont')
      await user.type(emailInput, 'jean@test.com')

      const submitButton = screen.getByRole('button', { name: /créer l'élève/i })
      await user.click(submitButton)

      await waitFor(() => {
        expect(mockAddStudent).toHaveBeenCalledWith({
          name: 'Jean Dupont',
          email: 'jean@test.com',
          goal: 'maintain',
          assignedProgramId: undefined,
          assignedDietId: undefined,
        })
      })
    })

    it('calls addStudent with selected program', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const nameInput = screen.getByPlaceholderText('Marie Laurent')
      const emailInput = screen.getByPlaceholderText('marie@email.com')
      const selects = screen.getAllByRole('combobox')
      const programSelect = selects[0]

      await user.type(nameInput, 'Jean Dupont')
      await user.type(emailInput, 'jean@test.com')
      await user.selectOptions(programSelect, 'prog-1')

      const submitButton = screen.getByRole('button', { name: /créer l'élève/i })
      await user.click(submitButton)

      await waitFor(() => {
        expect(mockAddStudent).toHaveBeenCalledWith(
          expect.objectContaining({
            assignedProgramId: 'prog-1',
          })
        )
      })
    })

    it('assigns program to student after creation', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const nameInput = screen.getByPlaceholderText('Marie Laurent')
      const emailInput = screen.getByPlaceholderText('marie@email.com')
      const selects = screen.getAllByRole('combobox')
      const programSelect = selects[0]

      await user.type(nameInput, 'Jean Dupont')
      await user.type(emailInput, 'jean@test.com')
      await user.selectOptions(programSelect, 'prog-1')

      const submitButton = screen.getByRole('button', { name: /créer l'élève/i })
      await user.click(submitButton)

      await waitFor(() => {
        expect(mockAssignProgramToStudent).toHaveBeenCalledWith('prog-1', 'new-student-id')
      })
    })

    it('assigns diet to student after creation', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const nameInput = screen.getByPlaceholderText('Marie Laurent')
      const emailInput = screen.getByPlaceholderText('marie@email.com')
      const selects = screen.getAllByRole('combobox')
      const dietSelect = selects[1]

      await user.type(nameInput, 'Jean Dupont')
      await user.type(emailInput, 'jean@test.com')
      await user.selectOptions(dietSelect, 'diet-1')

      const submitButton = screen.getByRole('button', { name: /créer l'élève/i })
      await user.click(submitButton)

      await waitFor(() => {
        expect(mockAssignDietToStudent).toHaveBeenCalledWith('diet-1', 'new-student-id')
      })
    })

    it('closes modal after successful submission', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const nameInput = screen.getByPlaceholderText('Marie Laurent')
      const emailInput = screen.getByPlaceholderText('marie@email.com')

      await user.type(nameInput, 'Jean Dupont')
      await user.type(emailInput, 'jean@test.com')

      const submitButton = screen.getByRole('button', { name: /créer l'élève/i })
      await user.click(submitButton)

      await waitFor(() => {
        expect(defaultProps.onClose).toHaveBeenCalled()
      })
    })

    it('shows loading state during submission', async () => {
      // Make addStudent take time
      mockAddStudent.mockImplementation(
        () => new Promise((resolve) => setTimeout(() => resolve('new-id'), 100))
      )

      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const nameInput = screen.getByPlaceholderText('Marie Laurent')
      const emailInput = screen.getByPlaceholderText('marie@email.com')

      await user.type(nameInput, 'Jean Dupont')
      await user.type(emailInput, 'jean@test.com')

      const submitButton = screen.getByRole('button', { name: /créer l'élève/i })
      await user.click(submitButton)

      expect(screen.getByText('Création...')).toBeInTheDocument()
    })
  })

  describe('error handling', () => {
    it('displays error alert on submission failure', async () => {
      const alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {})
      mockAddStudent.mockRejectedValue(new Error('Email already exists'))

      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const nameInput = screen.getByPlaceholderText('Marie Laurent')
      const emailInput = screen.getByPlaceholderText('marie@email.com')

      await user.type(nameInput, 'Jean Dupont')
      await user.type(emailInput, 'existing@test.com')

      const submitButton = screen.getByRole('button', { name: /créer l'élève/i })
      await user.click(submitButton)

      await waitFor(() => {
        expect(alertSpy).toHaveBeenCalledWith('Email already exists')
      })

      alertSpy.mockRestore()
    })

    it('does not close modal on submission failure', async () => {
      const alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {})
      mockAddStudent.mockRejectedValue(new Error('Network error'))

      const user = userEvent.setup()
      const onClose = vi.fn()
      render(<AddStudentModal isOpen={true} onClose={onClose} />)

      const nameInput = screen.getByPlaceholderText('Marie Laurent')
      const emailInput = screen.getByPlaceholderText('marie@email.com')

      await user.type(nameInput, 'Jean Dupont')
      await user.type(emailInput, 'jean@test.com')

      const submitButton = screen.getByRole('button', { name: /créer l'élève/i })
      await user.click(submitButton)

      // Wait for the error alert to appear
      await waitFor(() => {
        expect(alertSpy).toHaveBeenCalledWith('Network error')
      })

      // Now check that onClose was not called
      expect(onClose).not.toHaveBeenCalled()

      alertSpy.mockRestore()
    })
  })

  describe('closing behavior', () => {
    it('closes when clicking X button', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const closeButtons = screen.getAllByRole('button')
      const xButton = closeButtons.find(
        (btn) => btn.querySelector('.lucide-x') !== null
      )

      if (xButton) {
        await user.click(xButton)
        expect(defaultProps.onClose).toHaveBeenCalled()
      }
    })

    it('closes when clicking Annuler button', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const cancelButton = screen.getByRole('button', { name: /annuler/i })
      await user.click(cancelButton)

      expect(defaultProps.onClose).toHaveBeenCalled()
    })

    it('closes when clicking backdrop', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      // The backdrop is the first div with bg-black/60
      const backdrop = document.querySelector('.bg-black\\/60')
      if (backdrop) {
        await user.click(backdrop)
        expect(defaultProps.onClose).toHaveBeenCalled()
      }
    })
  })

  describe('goal selection', () => {
    it('default goal is maintain', () => {
      render(<AddStudentModal {...defaultProps} />)

      const maintainButton = screen.getByRole('button', { name: 'Maintien' })
      expect(maintainButton).toHaveClass('bg-info/10')
    })

    it('can select bulk goal', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const bulkButton = screen.getByRole('button', { name: 'Prise de masse' })
      await user.click(bulkButton)

      expect(bulkButton).toHaveClass('bg-success/10')
    })

    it('can select cut goal', async () => {
      const user = userEvent.setup()
      render(<AddStudentModal {...defaultProps} />)

      const cutButton = screen.getByRole('button', { name: 'Sèche' })
      await user.click(cutButton)

      expect(cutButton).toHaveClass('bg-warning/10')
    })
  })
})
