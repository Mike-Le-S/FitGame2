import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '../../helpers/test-utils'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card'

describe('Card', () => {
  describe('rendering', () => {
    it('renders children', () => {
      render(<Card>Card content</Card>)
      expect(screen.getByText('Card content')).toBeInTheDocument()
    })

    it('renders complex children', () => {
      render(
        <Card>
          <h2>Title</h2>
          <p>Description</p>
        </Card>
      )
      expect(screen.getByText('Title')).toBeInTheDocument()
      expect(screen.getByText('Description')).toBeInTheDocument()
    })
  })

  describe('className', () => {
    it('applies custom className', () => {
      render(<Card className="custom-card" data-testid="card">Content</Card>)
      const card = screen.getByTestId('card')
      expect(card).toHaveClass('custom-card')
    })

    it('merges with default classes', () => {
      render(<Card className="custom-card" data-testid="card">Content</Card>)
      const card = screen.getByTestId('card')
      expect(card).toHaveClass('custom-card')
      expect(card).toHaveClass('rounded-xl')
      expect(card).toHaveClass('p-5')
    })
  })

  describe('variants', () => {
    it('renders default variant by default', () => {
      render(<Card data-testid="card">Default</Card>)
      const card = screen.getByTestId('card')
      expect(card).toHaveClass('bg-surface')
      expect(card).toHaveClass('border')
      expect(card).toHaveClass('border-border')
    })

    it('renders default variant explicitly', () => {
      render(<Card variant="default" data-testid="card">Default</Card>)
      const card = screen.getByTestId('card')
      expect(card).toHaveClass('bg-surface')
    })

    it('renders glass variant', () => {
      render(<Card variant="glass" data-testid="card">Glass</Card>)
      const card = screen.getByTestId('card')
      expect(card).toHaveClass('bg-glass')
      expect(card).toHaveClass('border-glass-border')
      expect(card).toHaveClass('backdrop-blur-xl')
    })

    it('renders interactive variant', () => {
      render(<Card variant="interactive" data-testid="card">Interactive</Card>)
      const card = screen.getByTestId('card')
      expect(card).toHaveClass('bg-surface')
      expect(card).toHaveClass('cursor-pointer')
      expect(card).toHaveClass('transition-all')
    })
  })

  describe('event handlers', () => {
    it('handles onClick', () => {
      const handleClick = vi.fn()
      render(<Card onClick={handleClick}>Clickable</Card>)

      fireEvent.click(screen.getByText('Clickable'))
      expect(handleClick).toHaveBeenCalledTimes(1)
    })
  })

  describe('forwarded ref', () => {
    it('forwards ref to div element', () => {
      const ref = vi.fn()
      render(<Card ref={ref}>With Ref</Card>)
      expect(ref).toHaveBeenCalled()
      expect(ref.mock.calls[0][0]).toBeInstanceOf(HTMLDivElement)
    })
  })
})

describe('CardHeader', () => {
  it('renders children', () => {
    render(<CardHeader>Header content</CardHeader>)
    expect(screen.getByText('Header content')).toBeInTheDocument()
  })

  it('applies custom className', () => {
    render(<CardHeader className="custom-header" data-testid="header">Header</CardHeader>)
    const header = screen.getByTestId('header')
    expect(header).toHaveClass('custom-header')
  })

  it('has default flex layout', () => {
    render(<CardHeader data-testid="header">Header</CardHeader>)
    const header = screen.getByTestId('header')
    expect(header).toHaveClass('flex')
    expect(header).toHaveClass('flex-col')
    expect(header).toHaveClass('gap-1')
    expect(header).toHaveClass('mb-4')
  })

  it('forwards ref', () => {
    const ref = vi.fn()
    render(<CardHeader ref={ref}>Header</CardHeader>)
    expect(ref).toHaveBeenCalled()
  })
})

describe('CardTitle', () => {
  it('renders as h3', () => {
    render(<CardTitle>Title</CardTitle>)
    expect(screen.getByRole('heading', { level: 3 })).toBeInTheDocument()
  })

  it('renders text', () => {
    render(<CardTitle>Card Title</CardTitle>)
    expect(screen.getByText('Card Title')).toBeInTheDocument()
  })

  it('applies custom className', () => {
    render(<CardTitle className="custom-title">Title</CardTitle>)
    const title = screen.getByText('Title')
    expect(title).toHaveClass('custom-title')
  })

  it('has default typography styles', () => {
    render(<CardTitle>Title</CardTitle>)
    const title = screen.getByText('Title')
    expect(title).toHaveClass('text-lg')
    expect(title).toHaveClass('font-semibold')
    expect(title).toHaveClass('text-text-primary')
  })

  it('forwards ref', () => {
    const ref = vi.fn()
    render(<CardTitle ref={ref}>Title</CardTitle>)
    expect(ref).toHaveBeenCalled()
  })
})

describe('CardDescription', () => {
  it('renders as paragraph', () => {
    render(<CardDescription>Description</CardDescription>)
    const desc = screen.getByText('Description')
    expect(desc.tagName).toBe('P')
  })

  it('renders text', () => {
    render(<CardDescription>Card description text</CardDescription>)
    expect(screen.getByText('Card description text')).toBeInTheDocument()
  })

  it('applies custom className', () => {
    render(<CardDescription className="custom-desc">Description</CardDescription>)
    const desc = screen.getByText('Description')
    expect(desc).toHaveClass('custom-desc')
  })

  it('has default typography styles', () => {
    render(<CardDescription>Description</CardDescription>)
    const desc = screen.getByText('Description')
    expect(desc).toHaveClass('text-sm')
    expect(desc).toHaveClass('text-text-secondary')
  })

  it('forwards ref', () => {
    const ref = vi.fn()
    render(<CardDescription ref={ref}>Description</CardDescription>)
    expect(ref).toHaveBeenCalled()
  })
})

describe('CardContent', () => {
  it('renders children', () => {
    render(<CardContent>Content here</CardContent>)
    expect(screen.getByText('Content here')).toBeInTheDocument()
  })

  it('applies custom className', () => {
    render(<CardContent className="custom-content" data-testid="content">Content</CardContent>)
    const content = screen.getByTestId('content')
    expect(content).toHaveClass('custom-content')
  })

  it('forwards ref', () => {
    const ref = vi.fn()
    render(<CardContent ref={ref}>Content</CardContent>)
    expect(ref).toHaveBeenCalled()
  })
})

describe('Card composition', () => {
  it('works with all subcomponents', () => {
    render(
      <Card>
        <CardHeader>
          <CardTitle>Program Details</CardTitle>
          <CardDescription>8 week strength program</CardDescription>
        </CardHeader>
        <CardContent>
          <p>Main content goes here</p>
        </CardContent>
      </Card>
    )

    expect(screen.getByRole('heading', { name: 'Program Details' })).toBeInTheDocument()
    expect(screen.getByText('8 week strength program')).toBeInTheDocument()
    expect(screen.getByText('Main content goes here')).toBeInTheDocument()
  })

  it('maintains proper DOM structure', () => {
    const { container } = render(
      <Card data-testid="card">
        <CardHeader data-testid="header">
          <CardTitle>Title</CardTitle>
        </CardHeader>
        <CardContent data-testid="content">Content</CardContent>
      </Card>
    )

    const card = screen.getByTestId('card')
    const header = screen.getByTestId('header')
    const content = screen.getByTestId('content')

    expect(card).toContainElement(header)
    expect(card).toContainElement(content)
  })
})
