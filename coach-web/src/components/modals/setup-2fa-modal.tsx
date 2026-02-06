import { Shield, X } from 'lucide-react'
import { cn } from '@/lib/utils'

interface Setup2FAModalProps {
  isOpen: boolean
  onClose: () => void
}

export function Setup2FAModal({ isOpen, onClose }: Setup2FAModalProps) {
  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={onClose}
      />

      <div className={cn(
        'relative w-full max-w-md mx-4',
        'bg-surface border border-border rounded-2xl',
        'shadow-2xl animate-[fadeIn_0.2s_ease-out]'
      )}>
        <div className="flex items-center justify-between p-6 border-b border-border">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-accent/10 flex items-center justify-center">
              <Shield className="w-5 h-5 text-accent" />
            </div>
            <h2 className="text-lg font-semibold text-text-primary">
              Authentification 2FA
            </h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-lg text-text-muted hover:text-text-primary hover:bg-surface-elevated transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6 text-center">
          <div className="w-16 h-16 mx-auto rounded-full bg-accent/10 flex items-center justify-center mb-4">
            <Shield className="w-8 h-8 text-accent" />
          </div>
          <h3 className="text-lg font-semibold text-text-primary mb-2">
            Bientot disponible
          </h3>
          <p className="text-text-muted mb-6">
            L'authentification a deux facteurs sera disponible dans une prochaine mise a jour.
          </p>
          <button
            onClick={onClose}
            className={cn(
              'w-full flex items-center justify-center gap-2 h-11 rounded-xl font-semibold text-white',
              'bg-gradient-to-r from-accent to-[#ff8f5c]',
              'hover:shadow-[0_0_25px_rgba(255,107,53,0.35)]',
              'transition-all duration-300'
            )}
          >
            Fermer
          </button>
        </div>
      </div>
    </div>
  )
}
