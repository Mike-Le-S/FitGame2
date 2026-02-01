import { useState } from 'react'
import { X, Smartphone, Loader2, Check, Shield, Copy, CheckCircle } from 'lucide-react'
import { cn } from '@/lib/utils'

interface Setup2FAModalProps {
  isOpen: boolean
  onClose: () => void
  onSuccess: () => void
}

export function Setup2FAModal({ isOpen, onClose, onSuccess }: Setup2FAModalProps) {
  const [step, setStep] = useState<'qr' | 'verify' | 'success'>('qr')
  const [code, setCode] = useState('')
  const [isVerifying, setIsVerifying] = useState(false)
  const [error, setError] = useState('')
  const [copied, setCopied] = useState(false)

  // Mock secret key for demo
  const secretKey = 'JBSWY3DPEHPK3PXP'

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setIsVerifying(true)

    await new Promise(resolve => setTimeout(resolve, 1000))

    // Accept any 6-digit code for demo
    if (code.length === 6 && /^\d+$/.test(code)) {
      setIsVerifying(false)
      setStep('success')
      onSuccess()
    } else {
      setIsVerifying(false)
      setError('Code invalide. Veuillez réessayer.')
    }
  }

  const handleCopyKey = () => {
    navigator.clipboard.writeText(secretKey)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const handleClose = () => {
    setStep('qr')
    setCode('')
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
              step === 'success' ? 'bg-success/10' : 'bg-success/10'
            )}>
              {step === 'success' ? (
                <CheckCircle className="w-5 h-5 text-success" />
              ) : (
                <Smartphone className="w-5 h-5 text-success" />
              )}
            </div>
            <div>
              <h2 className="text-lg font-semibold text-text-primary">
                {step === 'success' ? '2FA activée !' : 'Configurer la 2FA'}
              </h2>
              <p className="text-sm text-text-muted">
                {step === 'qr' && 'Étape 1/2 : Scanner le QR code'}
                {step === 'verify' && 'Étape 2/2 : Vérifier le code'}
                {step === 'success' && 'Votre compte est sécurisé'}
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
          {step === 'qr' && (
            <div className="space-y-6">
              <p className="text-text-secondary text-sm">
                Scannez ce QR code avec votre application d'authentification (Google Authenticator, Authy, etc.)
              </p>

              {/* Fake QR Code */}
              <div className="flex justify-center">
                <div className={cn(
                  'w-48 h-48 rounded-2xl',
                  'bg-white p-4',
                  'shadow-lg'
                )}>
                  {/* SVG QR Code simulation */}
                  <svg viewBox="0 0 100 100" className="w-full h-full">
                    <rect fill="#000" x="0" y="0" width="30" height="30" />
                    <rect fill="#fff" x="5" y="5" width="20" height="20" />
                    <rect fill="#000" x="10" y="10" width="10" height="10" />

                    <rect fill="#000" x="70" y="0" width="30" height="30" />
                    <rect fill="#fff" x="75" y="5" width="20" height="20" />
                    <rect fill="#000" x="80" y="10" width="10" height="10" />

                    <rect fill="#000" x="0" y="70" width="30" height="30" />
                    <rect fill="#fff" x="5" y="75" width="20" height="20" />
                    <rect fill="#000" x="10" y="80" width="10" height="10" />

                    {/* Random pattern in middle */}
                    <rect fill="#000" x="35" y="0" width="5" height="5" />
                    <rect fill="#000" x="45" y="5" width="5" height="10" />
                    <rect fill="#000" x="55" y="0" width="5" height="5" />
                    <rect fill="#000" x="35" y="15" width="10" height="5" />
                    <rect fill="#000" x="50" y="15" width="5" height="5" />

                    <rect fill="#000" x="0" y="35" width="5" height="10" />
                    <rect fill="#000" x="10" y="40" width="10" height="5" />
                    <rect fill="#000" x="0" y="50" width="5" height="5" />
                    <rect fill="#000" x="15" y="50" width="5" height="10" />

                    <rect fill="#000" x="35" y="35" width="30" height="30" />
                    <rect fill="#fff" x="40" y="40" width="20" height="20" />
                    <rect fill="#000" x="45" y="45" width="10" height="10" />

                    <rect fill="#000" x="70" y="35" width="10" height="5" />
                    <rect fill="#000" x="85" y="40" width="15" height="5" />
                    <rect fill="#000" x="75" y="50" width="5" height="10" />
                    <rect fill="#000" x="90" y="50" width="10" height="5" />

                    <rect fill="#000" x="35" y="70" width="5" height="5" />
                    <rect fill="#000" x="45" y="75" width="10" height="5" />
                    <rect fill="#000" x="35" y="85" width="5" height="15" />
                    <rect fill="#000" x="50" y="85" width="5" height="5" />
                    <rect fill="#000" x="60" y="90" width="5" height="10" />

                    <rect fill="#000" x="70" y="70" width="5" height="5" />
                    <rect fill="#000" x="80" y="75" width="10" height="5" />
                    <rect fill="#000" x="75" y="85" width="5" height="5" />
                    <rect fill="#000" x="90" y="80" width="10" height="10" />
                    <rect fill="#000" x="85" y="95" width="15" height="5" />
                  </svg>
                </div>
              </div>

              {/* Manual entry */}
              <div className={cn(
                'p-4 rounded-xl',
                'bg-surface-elevated border border-border'
              )}>
                <p className="text-xs text-text-muted mb-2">
                  Ou entrez cette clé manuellement :
                </p>
                <div className="flex items-center gap-2">
                  <code className="flex-1 font-mono text-sm text-text-primary bg-surface px-3 py-2 rounded-lg">
                    {secretKey}
                  </code>
                  <button
                    onClick={handleCopyKey}
                    className={cn(
                      'p-2 rounded-lg transition-colors',
                      copied
                        ? 'bg-success/10 text-success'
                        : 'bg-surface text-text-muted hover:text-text-primary'
                    )}
                  >
                    {copied ? (
                      <Check className="w-4 h-4" />
                    ) : (
                      <Copy className="w-4 h-4" />
                    )}
                  </button>
                </div>
              </div>

              <button
                onClick={() => setStep('verify')}
                className={cn(
                  'w-full flex items-center justify-center gap-2 h-11 rounded-xl font-semibold text-white',
                  'bg-gradient-to-r from-success to-[#4ade80]',
                  'hover:shadow-[0_0_25px_rgba(34,197,94,0.35)]',
                  'transition-all duration-300'
                )}
              >
                Continuer
              </button>
            </div>
          )}

          {step === 'verify' && (
            <form onSubmit={handleVerify} className="space-y-6">
              <p className="text-text-secondary text-sm">
                Entrez le code à 6 chiffres affiché dans votre application d'authentification.
              </p>

              <div className="space-y-2">
                <label className="text-sm font-medium text-text-secondary">
                  Code de vérification
                </label>
                <input
                  type="text"
                  inputMode="numeric"
                  maxLength={6}
                  required
                  value={code}
                  onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))}
                  placeholder="000000"
                  className={cn(
                    'w-full h-14 px-4 rounded-xl text-center text-2xl font-mono tracking-[0.5em]',
                    'bg-surface-elevated border border-border',
                    'text-text-primary placeholder:text-text-muted',
                    'focus:outline-none focus:border-success focus:ring-2 focus:ring-success/20',
                    'transition-all duration-200'
                  )}
                />
              </div>

              {error && (
                <p className="text-sm text-error text-center">{error}</p>
              )}

              <div className="flex items-center gap-3">
                <button
                  type="button"
                  onClick={() => setStep('qr')}
                  className={cn(
                    'flex-1 h-11 rounded-xl font-medium',
                    'bg-surface-elevated border border-border',
                    'text-text-secondary hover:text-text-primary',
                    'transition-all duration-200'
                  )}
                >
                  Retour
                </button>
                <button
                  type="submit"
                  disabled={isVerifying || code.length !== 6}
                  className={cn(
                    'flex-1 flex items-center justify-center gap-2 h-11 rounded-xl font-semibold text-white',
                    'bg-gradient-to-r from-success to-[#4ade80]',
                    'hover:shadow-[0_0_25px_rgba(34,197,94,0.35)]',
                    'disabled:opacity-50 disabled:cursor-not-allowed',
                    'transition-all duration-300'
                  )}
                >
                  {isVerifying ? (
                    <>
                      <Loader2 className="w-4 h-4 animate-spin" />
                      Vérification...
                    </>
                  ) : (
                    <>
                      <Shield className="w-4 h-4" />
                      Activer la 2FA
                    </>
                  )}
                </button>
              </div>
            </form>
          )}

          {step === 'success' && (
            <div className="text-center py-4">
              <div className="w-16 h-16 mx-auto rounded-full bg-success/10 flex items-center justify-center mb-4">
                <CheckCircle className="w-8 h-8 text-success" />
              </div>
              <h3 className="text-lg font-semibold text-text-primary mb-2">
                2FA activée avec succès !
              </h3>
              <p className="text-text-muted mb-6">
                Votre compte est maintenant protégé par l'authentification à deux facteurs.
                Vous devrez entrer un code à chaque connexion.
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
                <Check className="w-4 h-4" />
                Terminé
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
