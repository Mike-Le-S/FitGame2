import { useState } from 'react'
import { useNavigate, Navigate } from 'react-router-dom'
import {
  Dumbbell,
  Mail,
  Lock,
  AlertCircle,
  Eye,
  EyeOff,
  ArrowRight,
  Users,
  TrendingUp,
  Zap,
} from 'lucide-react'
import { useAuthStore } from '@/store/auth-store'
import { ForgotPasswordModal } from '@/components/modals/forgot-password-modal'
import { cn } from '@/lib/utils'

export function LoginPage() {
  const navigate = useNavigate()
  const { login, loginWithGoogle, isAuthenticated } = useAuthStore()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [googleLoading, setGoogleLoading] = useState(false)
  const [focusedField, setFocusedField] = useState<string | null>(null)
  const [isForgotPasswordOpen, setIsForgotPasswordOpen] = useState(false)

  if (isAuthenticated) {
    return <Navigate to="/" replace />
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      await login(email, password)
      navigate('/')
    } catch {
      setError('Email ou mot de passe incorrect')
    } finally {
      setLoading(false)
    }
  }

  const handleGoogleLogin = async () => {
    setError('')
    setGoogleLoading(true)

    try {
      await loginWithGoogle()
    } catch {
      setError('Erreur de connexion Google')
      setGoogleLoading(false)
    }
  }

  const features = [
    { icon: Users, label: 'Gestion élèves', desc: 'Suivez tous vos clients' },
    { icon: TrendingUp, label: 'Analytics', desc: 'Métriques détaillées' },
    { icon: Zap, label: 'Programmes', desc: 'Créez en quelques clics' },
  ]

  return (
    <div className="min-h-screen bg-background flex">
      {/* Left Panel - Branding */}
      <div className="hidden lg:block lg:w-1/2 xl:w-[55%] relative overflow-hidden bg-gradient-to-br from-surface via-background to-surface">
        {/* Animated gradient orbs */}
        <div className="absolute top-1/4 left-1/4 w-[600px] h-[600px] bg-accent/10 rounded-full blur-[150px] animate-pulse" />
        <div className="absolute bottom-1/4 right-1/4 w-[400px] h-[400px] bg-accent/5 rounded-full blur-[120px]" />

        {/* Grid pattern */}
        <div
          className="absolute inset-0 opacity-[0.03]"
          style={{
            backgroundImage: `
              linear-gradient(rgba(255,107,53,0.3) 1px, transparent 1px),
              linear-gradient(90deg, rgba(255,107,53,0.3) 1px, transparent 1px)
            `,
            backgroundSize: '60px 60px',
          }}
        />

        {/* Diagonal lines accent */}
        <div className="absolute top-0 right-0 w-full h-full overflow-hidden opacity-10">
          <div className="absolute top-[-50%] right-[-50%] w-[200%] h-[200%] rotate-12">
            {[...Array(20)].map((_, i) => (
              <div
                key={i}
                className="absolute h-px bg-gradient-to-r from-transparent via-accent to-transparent"
                style={{
                  top: `${i * 8}%`,
                  left: 0,
                  right: 0,
                  opacity: 0.3 + (i % 3) * 0.2,
                }}
              />
            ))}
          </div>
        </div>

        {/* Content container */}
        <div className="relative z-10 h-full flex flex-col justify-between p-12 xl:p-16">
          {/* Logo */}
          <div className="flex items-center gap-4">
            <div className="relative">
              <div className="absolute inset-0 bg-accent/30 blur-xl rounded-2xl" />
              <div className="relative w-14 h-14 rounded-2xl bg-gradient-to-br from-accent to-[#ff8f5c] flex items-center justify-center shadow-lg shadow-accent/30">
                <Dumbbell className="w-8 h-8 text-white" />
              </div>
            </div>
            <div>
              <span className="text-3xl font-bold tracking-tight text-text-primary">
                Fit<span className="text-accent">Game</span>
              </span>
              <p className="text-sm text-text-muted tracking-wide">Coach Dashboard</p>
            </div>
          </div>

          {/* Hero text */}
          <div className="max-w-lg">
            <h1 className="text-5xl xl:text-6xl font-bold text-text-primary leading-tight mb-6">
              Transformez vos
              <span className="block text-accent">coaching sessions</span>
            </h1>
            <p className="text-lg text-text-secondary leading-relaxed mb-10">
              La plateforme tout-en-un pour gérer vos élèves, créer des programmes
              personnalisés et suivre leur progression en temps réel.
            </p>

            {/* Feature pills */}
            <div className="flex flex-wrap gap-3">
              {features.map((feature, index) => (
                <div
                  key={feature.label}
                  className={cn(
                    'flex items-center gap-3 px-4 py-3 rounded-xl',
                    'bg-surface-elevated/50 border border-border/50',
                    'backdrop-blur-sm',
                    'animate-[fadeIn_0.5s_ease-out_forwards] opacity-0'
                  )}
                  style={{ animationDelay: `${index * 100 + 200}ms` }}
                >
                  <div className="w-9 h-9 rounded-lg bg-accent/10 flex items-center justify-center">
                    <feature.icon className="w-5 h-5 text-accent" />
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-text-primary">{feature.label}</p>
                    <p className="text-xs text-text-muted">{feature.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Bottom stats */}
          <div className="flex items-center gap-8">
            <div>
              <p className="text-3xl font-bold text-accent">500+</p>
              <p className="text-sm text-text-muted">Coachs actifs</p>
            </div>
            <div className="w-px h-12 bg-border" />
            <div>
              <p className="text-3xl font-bold text-text-primary">10k+</p>
              <p className="text-sm text-text-muted">Élèves suivis</p>
            </div>
            <div className="w-px h-12 bg-border" />
            <div>
              <p className="text-3xl font-bold text-text-primary">98%</p>
              <p className="text-sm text-text-muted">Satisfaction</p>
            </div>
          </div>
        </div>
      </div>

      {/* Right Panel - Login Form */}
      <div className="flex-1 flex items-center justify-center p-6 lg:p-12 relative">
        {/* Subtle background glow */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-accent/5 rounded-full blur-[150px]" />

        <div className="w-full max-w-md relative z-10">
          {/* Mobile logo */}
          <div className="lg:hidden flex items-center justify-center gap-3 mb-10">
            <div className="relative">
              <div className="absolute inset-0 bg-accent/20 blur-xl rounded-xl" />
              <div className="relative w-12 h-12 rounded-xl bg-gradient-to-br from-accent to-[#ff8f5c] flex items-center justify-center">
                <Dumbbell className="w-7 h-7 text-white" />
              </div>
            </div>
            <span className="text-2xl font-bold text-text-primary">
              Fit<span className="text-accent">Game</span>
            </span>
          </div>

          {/* Form header */}
          <div className="text-center lg:text-left mb-8">
            <h2 className="text-2xl lg:text-3xl font-bold text-text-primary mb-2">
              Bon retour !
            </h2>
            <p className="text-text-secondary">
              Connectez-vous pour accéder à votre dashboard
            </p>
          </div>

          {/* Error message */}
          {error && (
            <div className={cn(
              'flex items-center gap-3 p-4 mb-6 rounded-xl',
              'bg-error/10 border border-error/20',
              'animate-[fadeIn_0.3s_ease-out]'
            )}>
              <div className="w-8 h-8 rounded-lg bg-error/20 flex items-center justify-center flex-shrink-0">
                <AlertCircle className="w-4 h-4 text-error" />
              </div>
              <p className="text-sm text-error">{error}</p>
            </div>
          )}

          {/* Login form */}
          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Email field */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-text-secondary">
                Email
              </label>
              <div className="relative group">
                {/* Glow effect on focus */}
                {focusedField === 'email' && (
                  <div className="absolute inset-0 bg-accent/10 blur-xl rounded-xl" />
                )}

                <div className={cn(
                  'relative flex items-center gap-3 h-12 px-4 rounded-xl',
                  'bg-surface-elevated border transition-all duration-300',
                  focusedField === 'email'
                    ? 'border-accent shadow-[0_0_0_3px_rgba(255,107,53,0.1)]'
                    : 'border-border hover:border-[rgba(255,255,255,0.12)]'
                )}>
                  <Mail className={cn(
                    'w-5 h-5 transition-colors',
                    focusedField === 'email' ? 'text-accent' : 'text-text-muted'
                  )} />
                  <input
                    type="email"
                    placeholder="votre@email.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    onFocus={() => setFocusedField('email')}
                    onBlur={() => setFocusedField(null)}
                    className="flex-1 bg-transparent text-text-primary placeholder:text-text-muted outline-none"
                    required
                  />
                </div>
              </div>
            </div>

            {/* Password field */}
            <div className="space-y-2">
              <label className="text-sm font-medium text-text-secondary">
                Mot de passe
              </label>
              <div className="relative group">
                {focusedField === 'password' && (
                  <div className="absolute inset-0 bg-accent/10 blur-xl rounded-xl" />
                )}

                <div className={cn(
                  'relative flex items-center gap-3 h-12 px-4 rounded-xl',
                  'bg-surface-elevated border transition-all duration-300',
                  focusedField === 'password'
                    ? 'border-accent shadow-[0_0_0_3px_rgba(255,107,53,0.1)]'
                    : 'border-border hover:border-[rgba(255,255,255,0.12)]'
                )}>
                  <Lock className={cn(
                    'w-5 h-5 transition-colors',
                    focusedField === 'password' ? 'text-accent' : 'text-text-muted'
                  )} />
                  <input
                    type={showPassword ? 'text' : 'password'}
                    placeholder="Votre mot de passe"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    onFocus={() => setFocusedField('password')}
                    onBlur={() => setFocusedField(null)}
                    className="flex-1 bg-transparent text-text-primary placeholder:text-text-muted outline-none"
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="p-1 rounded-md text-text-muted hover:text-text-secondary transition-colors"
                  >
                    {showPassword ? (
                      <EyeOff className="w-4 h-4" />
                    ) : (
                      <Eye className="w-4 h-4" />
                    )}
                  </button>
                </div>
              </div>
            </div>

            {/* Remember me & Forgot password */}
            <div className="flex items-center justify-between">
              <label className="flex items-center gap-2 cursor-pointer group">
                <div className="relative">
                  <input type="checkbox" className="sr-only peer" />
                  <div className={cn(
                    'w-5 h-5 rounded-md border transition-all',
                    'border-border bg-surface-elevated',
                    'peer-checked:bg-accent peer-checked:border-accent',
                    'group-hover:border-text-muted'
                  )} />
                  <svg
                    className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-3 h-3 text-white opacity-0 peer-checked:opacity-100 transition-opacity"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    strokeWidth={3}
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <span className="text-sm text-text-secondary">Se souvenir de moi</span>
              </label>

              <button
                type="button"
                onClick={() => setIsForgotPasswordOpen(true)}
                className="text-sm text-accent hover:text-accent-hover transition-colors"
              >
                Mot de passe oublié ?
              </button>
            </div>

            {/* Submit button */}
            <button
              type="submit"
              disabled={loading}
              className={cn(
                'group relative w-full h-12 rounded-xl font-semibold text-white',
                'bg-gradient-to-r from-accent to-[#ff8f5c]',
                'transition-all duration-300',
                'hover:shadow-[0_0_30px_rgba(255,107,53,0.4)]',
                'disabled:opacity-60 disabled:cursor-not-allowed',
                'overflow-hidden'
              )}
            >
              {/* Shimmer effect */}
              <div className={cn(
                'absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent',
                'translate-x-[-200%] group-hover:translate-x-[200%]',
                'transition-transform duration-700'
              )} />

              <span className="relative flex items-center justify-center gap-2">
                {loading ? (
                  <>
                    <svg className="animate-spin w-5 h-5" viewBox="0 0 24 24">
                      <circle
                        className="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        strokeWidth="4"
                        fill="none"
                      />
                      <path
                        className="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                      />
                    </svg>
                    Connexion...
                  </>
                ) : (
                  <>
                    Se connecter
                    <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                  </>
                )}
              </span>
            </button>

            {/* Divider */}
            <div className="flex items-center gap-4 my-6">
              <div className="flex-1 h-px bg-border" />
              <span className="text-sm text-text-muted">ou</span>
              <div className="flex-1 h-px bg-border" />
            </div>

            {/* Google Sign-In button */}
            <button
              type="button"
              onClick={handleGoogleLogin}
              disabled={googleLoading}
              className={cn(
                'w-full h-12 rounded-xl font-medium',
                'bg-surface-elevated border border-border',
                'text-text-primary',
                'transition-all duration-300',
                'hover:border-[rgba(255,255,255,0.15)] hover:bg-surface',
                'disabled:opacity-60 disabled:cursor-not-allowed',
                'flex items-center justify-center gap-3'
              )}
            >
              {googleLoading ? (
                <svg className="animate-spin w-5 h-5" viewBox="0 0 24 24">
                  <circle
                    className="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    strokeWidth="4"
                    fill="none"
                  />
                  <path
                    className="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                  />
                </svg>
              ) : (
                <>
                  {/* Google Logo SVG */}
                  <svg className="w-5 h-5" viewBox="0 0 24 24">
                    <path
                      fill="#4285F4"
                      d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                    />
                    <path
                      fill="#34A853"
                      d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                    />
                    <path
                      fill="#FBBC05"
                      d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                    />
                    <path
                      fill="#EA4335"
                      d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                    />
                  </svg>
                  Continuer avec Google
                </>
              )}
            </button>
          </form>

          {/* Footer */}
          <p className="mt-8 text-center text-sm text-text-muted">
            Pas encore de compte ?{' '}
            <a
              href="mailto:support@fitgame.app"
              className="text-accent hover:text-accent-hover font-medium transition-colors"
            >
              Contactez-nous
            </a>
          </p>
        </div>
      </div>

      {/* Forgot Password Modal */}
      <ForgotPasswordModal
        isOpen={isForgotPasswordOpen}
        onClose={() => setIsForgotPasswordOpen(false)}
      />
    </div>
  )
}
