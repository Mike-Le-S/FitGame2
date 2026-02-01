import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '../../helpers/test-utils'
import { Input } from '@/components/ui/input'

describe('Input', () => {
  describe('rendering', () => {
    it('renders an input element', () => {
      render(<Input />)
      expect(screen.getByRole('textbox')).toBeInTheDocument()
    })

    it('renders with placeholder', () => {
      render(<Input placeholder="Enter your name" />)
      expect(screen.getByPlaceholderText('Enter your name')).toBeInTheDocument()
    })

    it('renders with label', () => {
      render(<Input label="Email" />)
      expect(screen.getByLabelText('Email')).toBeInTheDocument()
      expect(screen.getByText('Email')).toBeInTheDocument()
    })

    it('associates label with input via htmlFor', () => {
      render(<Input label="Username" />)
      const label = screen.getByText('Username')
      const input = screen.getByLabelText('Username')
      expect(label).toHaveAttribute('for', 'username')
      expect(input).toHaveAttribute('id', 'username')
    })

    it('uses custom id when provided', () => {
      render(<Input label="Email" id="custom-email-id" />)
      const input = screen.getByLabelText('Email')
      expect(input).toHaveAttribute('id', 'custom-email-id')
    })
  })

  describe('value changes', () => {
    it('calls onChange handler when typing', () => {
      const handleChange = vi.fn()
      render(<Input onChange={handleChange} />)

      const input = screen.getByRole('textbox')
      fireEvent.change(input, { target: { value: 'test' } })

      expect(handleChange).toHaveBeenCalledTimes(1)
    })

    it('updates value when controlled', () => {
      const { rerender } = render(<Input value="initial" onChange={() => {}} />)
      expect(screen.getByRole('textbox')).toHaveValue('initial')

      rerender(<Input value="updated" onChange={() => {}} />)
      expect(screen.getByRole('textbox')).toHaveValue('updated')
    })

    it('allows typing in uncontrolled input', () => {
      render(<Input defaultValue="" />)
      const input = screen.getByRole('textbox')

      fireEvent.change(input, { target: { value: 'hello' } })
      expect(input).toHaveValue('hello')
    })
  })

  describe('error state', () => {
    it('displays error message', () => {
      render(<Input error="This field is required" />)
      expect(screen.getByText('This field is required')).toBeInTheDocument()
    })

    it('applies error styles to input', () => {
      render(<Input error="Error" />)
      const input = screen.getByRole('textbox')
      expect(input).toHaveClass('border-error')
    })

    it('does not show error message when not provided', () => {
      render(<Input />)
      expect(screen.queryByText('This field is required')).not.toBeInTheDocument()
    })
  })

  describe('disabled state', () => {
    it('is disabled when disabled prop is true', () => {
      render(<Input disabled />)
      expect(screen.getByRole('textbox')).toBeDisabled()
    })

    it('is not disabled by default', () => {
      render(<Input />)
      expect(screen.getByRole('textbox')).not.toBeDisabled()
    })

    it('has disabled attribute when disabled', () => {
      render(<Input disabled />)
      const input = screen.getByRole('textbox')
      expect(input).toHaveAttribute('disabled')
    })
  })

  describe('input types', () => {
    it('renders as textbox by default (no explicit type)', () => {
      render(<Input />)
      const input = screen.getByRole('textbox')
      // HTML default type is "text" when no type attribute is specified
      expect(input).toBeInTheDocument()
    })

    it('renders as email type', () => {
      render(<Input type="email" />)
      const input = screen.getByRole('textbox')
      expect(input).toHaveAttribute('type', 'email')
    })

    it('renders as password type', () => {
      render(<Input type="password" />)
      // Password inputs don't have role="textbox"
      const input = document.querySelector('input[type="password"]')
      expect(input).toBeInTheDocument()
    })

    it('renders as number type', () => {
      render(<Input type="number" />)
      const input = screen.getByRole('spinbutton')
      expect(input).toHaveAttribute('type', 'number')
    })
  })

  describe('custom className', () => {
    it('applies custom className to input', () => {
      render(<Input className="custom-input" />)
      const input = screen.getByRole('textbox')
      expect(input).toHaveClass('custom-input')
    })

    it('merges with default classes', () => {
      render(<Input className="custom-input" />)
      const input = screen.getByRole('textbox')
      expect(input).toHaveClass('custom-input')
      expect(input).toHaveClass('h-10')
      expect(input).toHaveClass('px-3')
    })
  })

  describe('accessibility', () => {
    it('has accessible name when label is provided', () => {
      render(<Input label="Full Name" />)
      expect(screen.getByRole('textbox', { name: 'Full Name' })).toBeInTheDocument()
    })

    it('supports aria-label', () => {
      render(<Input aria-label="Search query" />)
      expect(screen.getByRole('textbox', { name: 'Search query' })).toBeInTheDocument()
    })

    it('supports aria-describedby', () => {
      render(
        <>
          <Input aria-describedby="help-text" />
          <span id="help-text">Enter your full name</span>
        </>
      )
      const input = screen.getByRole('textbox')
      expect(input).toHaveAttribute('aria-describedby', 'help-text')
    })

    it('can be required', () => {
      render(<Input required label="Email" />)
      const input = screen.getByRole('textbox')
      expect(input).toBeRequired()
    })
  })

  describe('forwarded ref', () => {
    it('forwards ref to input element', () => {
      const ref = vi.fn()
      render(<Input ref={ref} />)
      expect(ref).toHaveBeenCalled()
      expect(ref.mock.calls[0][0]).toBeInstanceOf(HTMLInputElement)
    })

    it('allows focus via ref', () => {
      const ref = { current: null as HTMLInputElement | null }
      render(<Input ref={ref} />)

      ref.current?.focus()
      expect(document.activeElement).toBe(ref.current)
    })
  })

  describe('label id generation', () => {
    it('generates id from label with spaces', () => {
      render(<Input label="First Name" />)
      const input = screen.getByLabelText('First Name')
      expect(input).toHaveAttribute('id', 'first-name')
    })

    it('generates id from label with multiple spaces', () => {
      render(<Input label="Date of Birth" />)
      const input = screen.getByLabelText('Date of Birth')
      expect(input).toHaveAttribute('id', 'date-of-birth')
    })
  })
})
