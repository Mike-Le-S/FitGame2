import { Check } from 'lucide-react'
import { cn } from '@/lib/utils'

interface Step {
  id: string
  label: string
}

interface StepperProps {
  steps: Step[]
  currentStep: number
  className?: string
}

export function Stepper({ steps, currentStep, className }: StepperProps) {
  return (
    <div className={cn('flex items-center justify-center', className)}>
      {steps.map((step, index) => {
        const isCompleted = index < currentStep
        const isCurrent = index === currentStep

        return (
          <div
            key={step.id}
            className={cn(
              'flex items-center',
              'animate-[fadeIn_0.4s_ease-out_forwards] opacity-0'
            )}
            style={{ animationDelay: `${index * 100}ms` }}
          >
            <div className="flex items-center gap-3">
              {/* Step circle */}
              <div className="relative">
                {/* Glow effect for current step */}
                {isCurrent && (
                  <div className="absolute inset-0 bg-accent/30 blur-xl rounded-full animate-pulse" />
                )}

                <div
                  className={cn(
                    'relative w-10 h-10 rounded-full flex items-center justify-center',
                    'text-sm font-semibold transition-all duration-300',
                    isCompleted && 'bg-gradient-to-br from-accent to-[#ff8f5c] text-white shadow-lg shadow-accent/30',
                    isCurrent && 'bg-gradient-to-br from-accent to-[#ff8f5c] text-white shadow-lg shadow-accent/30',
                    !isCompleted && !isCurrent && 'bg-surface-elevated text-text-muted border border-border'
                  )}
                >
                  {isCompleted ? (
                    <Check className="w-5 h-5" />
                  ) : (
                    <span>{index + 1}</span>
                  )}
                </div>
              </div>

              {/* Step label */}
              <span
                className={cn(
                  'text-sm font-medium transition-colors duration-200',
                  isCurrent && 'text-text-primary',
                  isCompleted && 'text-accent',
                  !isCurrent && !isCompleted && 'text-text-muted'
                )}
              >
                {step.label}
              </span>
            </div>

            {/* Connector line */}
            {index < steps.length - 1 && (
              <div className="relative w-16 xl:w-24 h-0.5 mx-4">
                <div className="absolute inset-0 bg-border rounded-full" />
                <div
                  className={cn(
                    'absolute inset-y-0 left-0 rounded-full transition-all duration-500',
                    'bg-gradient-to-r from-accent to-[#ff8f5c]'
                  )}
                  style={{
                    width: isCompleted ? '100%' : '0%',
                  }}
                />
              </div>
            )}
          </div>
        )
      })}
    </div>
  )
}
