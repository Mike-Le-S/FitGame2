import { type HTMLAttributes } from 'react'
import { cn } from '@/lib/utils'

export interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: 'default' | 'success' | 'warning' | 'error' | 'info' | 'accent'
}

export function Badge({ className, variant = 'default', ...props }: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md',
        variant === 'default' && 'bg-surface-elevated text-text-secondary',
        variant === 'success' && 'bg-success/15 text-success',
        variant === 'warning' && 'bg-warning/15 text-warning',
        variant === 'error' && 'bg-error/15 text-error',
        variant === 'info' && 'bg-info/15 text-info',
        variant === 'accent' && 'bg-accent-muted text-accent',
        className
      )}
      {...props}
    />
  )
}
