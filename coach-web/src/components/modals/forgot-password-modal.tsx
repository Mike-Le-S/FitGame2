import { useState } from 'react'
import { X, Mail, Loader2, Check, ArrowLeft, Send } from 'lucide-react'
import { cn } from '@/lib/utils'
import { supabase } from '@/lib/supabase'

interface ForgotPasswordModalProps {
  isOpen: boolean
  onClose: () => void
}

export function ForgotPasswordModal({ isOpen, onClose }: ForgotPasswordModalProps) {
  const [email, setEmail] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isSuccess, setIsSuccess] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setIsSubmitting(true)

    const { error } = await supabase.auth.resetPasswordForEmail(email)
    if (error) {
      setError(error.message)
      setIsSubmitting(false)
      return
    }
    setIsSubmitting(false)
    setIsSuccess(true)
  }

  const handleClose = () => {
    setEmail('')
    setIsSuccess(false)
    setError('')
    onClose()
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={handleClose}
      />

      <div className={cn(
        'relative w-full max-w-md mx-4',
        'bg-surface border border-border rounded-2xl',
        'shadow-2xl animate-[fadeIn_0.2s_ease-out]'
      )}>
        <div className="flex items-center justify-between p-6 border-b border-border">
          <div className="flex items-center gap-3">
            <div className={cn(
              'w-10 h-10 rounded-xl flex items-center justify-center',
              isSuccess ? 'bg-success/10' : 'bg-accent/10'
            )}>
              {isSuccess ? (
                <Check className="w-5 h-5 text-success" />
              ) : (
                <Mail className="w-5 h-5 text-accent" />
              )}
            </div>
            <div>
              <h2 className="text-lg font-semibold text-text-primary">
                {isSuccess ? 'Email envoyé !' : 'Mot de passe oublié'}
              </h2>
              <p className="text-sm text-text-muted">
                {isSuccess ? 'Vérifiez votre boîte mail' : 'Réinitialisez votre mot de passe'}
              </p>
            </div>
          </div>
          <button
            onClick={handleClose}
            className="p-2 rounded-lg text-text-muted hover:text-text-primary hover:bg-surface-elevated transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6">
          {isSuccess ? (
            <div className="text-center py-4">
              <div className="w-16 h-16 mx-auto rounded-full bg-success/10 flex items-center justify-center mb-4">
                <Send className="w-8 h-8 text-success" />
              </div>
              <p className="text-text-secondary mb-2">
                Un email de réinitialisation a été envoyé à
              </p>
              <p className="font-semibold text-text-primary mb-6">
                {email}
              </p>
              <p className="text-sm text-text-muted mb-6">
                Cliquez sur le lien dans l'email pour créer un nouveau mot de passe.
                Si vous ne recevez rien, vérifiez vos spams.
              </p>
              <button
                onClick={handleClose}
                className={cn(
                  'w-full flex items-center justify-center gap-2 h-11 rounded-xl font-semibold text-white',
                  'bg-gradient-to-r from-accent to-[#ff8f5c]',
                  'hover:shadow-[0_0_25px_rgba(255,107,53,0.35)]',
                  'transition-all duration-300'
                )}
              >
                <ArrowLeft className="w-4 h-4" />
                Retour à la connexion
              </button>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-5">
              <p className="text-text-secondary text-sm">
                Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.
              </p>

              <div className="space-y-2">
                <label className="text-sm font-medium text-text-secondary">
                  Adresse email
                </label>
                <div className="relative">
                  <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-text-muted" />
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="votre@email.com"
                    className={cn(
                      'w-full h-12 pl-12 pr-4 rounded-xl',
                      'bg-surface-elevated border border-border',
                      'text-text-primary placeholder:text-text-muted',
                      'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                      'transition-all duration-200'
                    )}
                  />
                </div>
              </div>

              {error && (
                <p className="text-sm text-error">{error}</p>
              )}

              <div className="flex items-center gap-3 pt-2">
                <button
                  type="button"
                  onClick={handleClose}
                  className={cn(
                    'flex-1 h-11 rounded-xl font-medium',
                    'bg-surface-elevated border border-border',
                    'text-text-secondary hover:text-text-primary',
                    'transition-all duration-200'
                  )}
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting || !email}
                  className={cn(
                    'flex-1 flex items-center justify-center gap-2 h-11 rounded-xl font-semibold text-white',
                    'bg-gradient-to-r from-accent to-[#ff8f5c]',
                    'hover:shadow-[0_0_25px_rgba(255,107,53,0.35)]',
                    'disabled:opacity-50 disabled:cursor-not-allowed',
                    'transition-all duration-300'
                  )}
                >
                  {isSubmitting ? (
                    <>
                      <Loader2 className="w-4 h-4 animate-spin" />
                      Envoi...
                    </>
                  ) : (
                    <>
                      <Send className="w-4 h-4" />
                      Envoyer le lien
                    </>
                  )}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  )
}
