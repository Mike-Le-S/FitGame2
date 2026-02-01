import { describe, it, expect } from 'vitest'
import { render, screen } from '../../helpers/test-utils'
import { Badge } from '@/components/ui/badge'

describe('Badge', () => {
  describe('rendering', () => {
    it('renders with text', () => {
      render(<Badge>Active</Badge>)
      expect(screen.getByText('Active')).toBeInTheDocument()
    })

    it('renders as a span element', () => {
      render(<Badge>Status</Badge>)
      const badge = screen.getByText('Status')
      expect(badge.tagName).toBe('SPAN')
    })

    it('renders complex children', () => {
      render(
        <Badge>
          <span data-testid="icon">*</span>
          New
        </Badge>
      )
      expect(screen.getByTestId('icon')).toBeInTheDocument()
      expect(screen.getByText('New')).toBeInTheDocument()
    })
  })

  describe('variants', () => {
    it('renders default variant by default', () => {
      render(<Badge>Default</Badge>)
      const badge = screen.getByText('Default')
      expect(badge).toHaveClass('bg-surface-elevated')
      expect(badge).toHaveClass('text-text-secondary')
    })

    it('renders default variant explicitly', () => {
      render(<Badge variant="default">Default</Badge>)
      const badge = screen.getByText('Default')
      expect(badge).toHaveClass('bg-surface-elevated')
      expect(badge).toHaveClass('text-text-secondary')
    })

    it('renders success variant', () => {
      render(<Badge variant="success">Success</Badge>)
      const badge = screen.getByText('Success')
      expect(badge).toHaveClass('bg-success/15')
      expect(badge).toHaveClass('text-success')
    })

    it('renders warning variant', () => {
      render(<Badge variant="warning">Warning</Badge>)
      const badge = screen.getByText('Warning')
      expect(badge).toHaveClass('bg-warning/15')
      expect(badge).toHaveClass('text-warning')
    })

    it('renders error variant', () => {
      render(<Badge variant="error">Error</Badge>)
      const badge = screen.getByText('Error')
      expect(badge).toHaveClass('bg-error/15')
      expect(badge).toHaveClass('text-error')
    })

    it('renders info variant', () => {
      render(<Badge variant="info">Info</Badge>)
      const badge = screen.getByText('Info')
      expect(badge).toHaveClass('bg-info/15')
      expect(badge).toHaveClass('text-info')
    })

    it('renders accent variant', () => {
      render(<Badge variant="accent">Accent</Badge>)
      const badge = screen.getByText('Accent')
      expect(badge).toHaveClass('bg-accent-muted')
      expect(badge).toHaveClass('text-accent')
    })
  })

  describe('className', () => {
    it('applies custom className', () => {
      render(<Badge className="custom-badge">Custom</Badge>)
      const badge = screen.getByText('Custom')
      expect(badge).toHaveClass('custom-badge')
    })

    it('merges with default classes', () => {
      render(<Badge className="custom-badge">Custom</Badge>)
      const badge = screen.getByText('Custom')
      expect(badge).toHaveClass('custom-badge')
      expect(badge).toHaveClass('inline-flex')
      expect(badge).toHaveClass('items-center')
      expect(badge).toHaveClass('rounded-md')
    })

    it('allows overriding default styles', () => {
      render(<Badge className="rounded-full">Pill</Badge>)
      const badge = screen.getByText('Pill')
      expect(badge).toHaveClass('rounded-full')
    })
  })

  describe('base styles', () => {
    it('has inline-flex display', () => {
      render(<Badge>Badge</Badge>)
      const badge = screen.getByText('Badge')
      expect(badge).toHaveClass('inline-flex')
    })

    it('has items-center alignment', () => {
      render(<Badge>Badge</Badge>)
      const badge = screen.getByText('Badge')
      expect(badge).toHaveClass('items-center')
    })

    it('has proper padding', () => {
      render(<Badge>Badge</Badge>)
      const badge = screen.getByText('Badge')
      expect(badge).toHaveClass('px-2')
      expect(badge).toHaveClass('py-0.5')
    })

    it('has proper typography', () => {
      render(<Badge>Badge</Badge>)
      const badge = screen.getByText('Badge')
      expect(badge).toHaveClass('text-xs')
      expect(badge).toHaveClass('font-medium')
    })

    it('has rounded corners', () => {
      render(<Badge>Badge</Badge>)
      const badge = screen.getByText('Badge')
      expect(badge).toHaveClass('rounded-md')
    })
  })

  describe('HTML attributes', () => {
    it('passes through HTML attributes', () => {
      render(<Badge data-testid="custom-badge" id="my-badge">Badge</Badge>)
      const badge = screen.getByTestId('custom-badge')
      expect(badge).toHaveAttribute('id', 'my-badge')
    })

    it('supports title attribute for tooltip', () => {
      render(<Badge title="This is a badge">Badge</Badge>)
      const badge = screen.getByText('Badge')
      expect(badge).toHaveAttribute('title', 'This is a badge')
    })

    it('supports aria attributes', () => {
      render(<Badge aria-label="Status indicator">Active</Badge>)
      const badge = screen.getByText('Active')
      expect(badge).toHaveAttribute('aria-label', 'Status indicator')
    })
  })

  describe('use cases', () => {
    it('works as a status indicator', () => {
      render(
        <div>
          <span>User:</span>
          <Badge variant="success">Online</Badge>
        </div>
      )
      expect(screen.getByText('Online')).toBeInTheDocument()
    })

    it('works for count badges', () => {
      render(<Badge variant="accent">5</Badge>)
      expect(screen.getByText('5')).toBeInTheDocument()
    })

    it('works for category labels', () => {
      render(
        <div>
          <Badge>Strength</Badge>
          <Badge>Cardio</Badge>
        </div>
      )
      expect(screen.getByText('Strength')).toBeInTheDocument()
      expect(screen.getByText('Cardio')).toBeInTheDocument()
    })
  })
})
