import { forwardRef, type InputHTMLAttributes } from 'react'
import { cn } from '@/lib/utils'

export interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className, label, error, id, ...props }, ref) => {
    const inputId = id || label?.toLowerCase().replace(/\s+/g, '-')

    return (
      <div className="flex flex-col gap-1.5">
        {label && (
          <label htmlFor={inputId} className="text-sm font-medium text-text-secondary">
            {label}
          </label>
        )}
        <input
          ref={ref}
          id={inputId}
          className={cn(
            'h-10 px-3 rounded-lg',
            'bg-surface-elevated border border-border',
            'text-text-primary placeholder:text-text-muted',
            'transition-colors duration-200',
            'hover:border-[rgba(255,255,255,0.12)]',
            'focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent/30',
            error && 'border-error focus:border-error focus:ring-error/30',
            className
          )}
          {...props}
        />
        {error && <span className="text-xs text-error">{error}</span>}
      </div>
    )
  }
)

Input.displayName = 'Input'
