import { forwardRef, type ButtonHTMLAttributes } from 'react'
import { cn } from '@/lib/utils'

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger'
  size?: 'sm' | 'md' | 'lg'
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', children, disabled, ...props }, ref) => {
    return (
      <button
        ref={ref}
        disabled={disabled}
        className={cn(
          'inline-flex items-center justify-center font-medium transition-all duration-200',
          'disabled:opacity-50 disabled:cursor-not-allowed',
          // Variants
          variant === 'primary' && [
            'bg-accent text-white hover:bg-accent-hover',
            'shadow-[0_0_20px_rgba(255,107,53,0.2)] hover:shadow-[0_0_30px_rgba(255,107,53,0.3)]',
          ],
          variant === 'secondary' && [
            'bg-surface-elevated text-text-primary border border-border',
            'hover:bg-[#222] hover:border-border',
          ],
          variant === 'ghost' && [
            'text-text-secondary hover:text-text-primary hover:bg-surface-elevated',
          ],
          variant === 'danger' && [
            'bg-error/10 text-error border border-error/20',
            'hover:bg-error/20',
          ],
          // Sizes
          size === 'sm' && 'h-8 px-3 text-sm rounded-md gap-1.5',
          size === 'md' && 'h-10 px-4 text-sm rounded-lg gap-2',
          size === 'lg' && 'h-12 px-6 text-base rounded-lg gap-2',
          className
        )}
        {...props}
      >
        {children}
      </button>
    )
  }
)

Button.displayName = 'Button'
