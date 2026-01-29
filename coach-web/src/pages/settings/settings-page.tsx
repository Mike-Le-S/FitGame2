import { useState } from 'react'
import {
  User,
  Bell,
  Shield,
  Palette,
  HelpCircle,
  LogOut,
  ChevronRight,
  Check,
  Camera,
  Mail,
  Lock,
  Smartphone,
  Moon,
  Sun,
  Monitor,
  ExternalLink,
  MessageCircle,
  Bug,
  BookOpen,
  Sparkles,
  KeyRound,
  Eye,
  EyeOff,
} from 'lucide-react'
import { Header } from '@/components/layout'
import { Avatar } from '@/components/ui'
import { useAuthStore } from '@/store/auth-store'
import { cn } from '@/lib/utils'

type SettingsSection = 'profile' | 'notifications' | 'security' | 'appearance' | 'help'

const accentColors = [
  { id: 'orange', color: '#FF6B35', label: 'Orange' },
  { id: 'blue', color: '#3B82F6', label: 'Bleu' },
  { id: 'green', color: '#22C55E', label: 'Vert' },
  { id: 'purple', color: '#A855F7', label: 'Violet' },
  { id: 'pink', color: '#EC4899', label: 'Rose' },
]

const themes = [
  { id: 'dark', label: 'Sombre', icon: Moon, bg: '#0a0a0a', available: true },
  { id: 'light', label: 'Clair', icon: Sun, bg: '#f5f5f5', available: false },
  { id: 'system', label: 'Système', icon: Monitor, bg: 'linear-gradient(135deg, #0a0a0a 50%, #f5f5f5 50%)', available: false },
]

export function SettingsPage() {
  const { coach, logout } = useAuthStore()
  const [activeSection, setActiveSection] = useState<SettingsSection>('profile')
  const [selectedTheme, setSelectedTheme] = useState('dark')
  const [selectedAccent, setSelectedAccent] = useState('orange')
  const [showPassword, setShowPassword] = useState<Record<string, boolean>>({})

  const sections = [
    { id: 'profile' as const, label: 'Profil', icon: User, description: 'Informations personnelles' },
    { id: 'notifications' as const, label: 'Notifications', icon: Bell, description: 'Gérer les alertes' },
    { id: 'security' as const, label: 'Sécurité', icon: Shield, description: 'Mot de passe & 2FA' },
    { id: 'appearance' as const, label: 'Apparence', icon: Palette, description: 'Thème & couleurs' },
    { id: 'help' as const, label: 'Aide', icon: HelpCircle, description: 'Support & docs' },
  ]

  const notifications = [
    { id: 'messages', label: 'Nouveaux messages', description: 'Recevoir une notification pour chaque nouveau message', enabled: true },
    { id: 'sessions', label: 'Séances terminées', description: 'Être notifié quand un élève termine une séance', enabled: true },
    { id: 'alerts', label: 'Alertes de compliance', description: 'Recevoir des alertes pour les élèves en difficulté', enabled: true },
    { id: 'checkins', label: 'Rappels de check-in', description: 'Rappels pour les check-ins programmés', enabled: false },
    { id: 'weekly', label: 'Rapport hebdomadaire', description: 'Résumé des performances de vos élèves', enabled: true },
  ]

  const helpLinks = [
    { icon: BookOpen, label: 'Guide de démarrage', description: 'Apprenez les bases de FitGame Coach', color: 'accent' },
    { icon: Sparkles, label: 'Nouveautés', description: 'Découvrez les dernières fonctionnalités', color: 'info' },
    { icon: MessageCircle, label: 'Contacter le support', description: 'Envoyez-nous un message', color: 'success' },
    { icon: Bug, label: 'Signaler un bug', description: 'Aidez-nous à améliorer l\'application', color: 'warning' },
  ]

  const togglePassword = (field: string) => {
    setShowPassword(prev => ({ ...prev, [field]: !prev[field] }))
  }

  return (
    <div className="min-h-screen">
      <Header
        title="Paramètres"
        subtitle="Gérez votre compte et vos préférences"
      />

      <div className="p-8">
        <div className="grid grid-cols-4 gap-6">
          {/* Sidebar Navigation */}
          <div className={cn(
            'p-4 rounded-2xl h-fit',
            'bg-surface border border-border',
            'animate-[fadeIn_0.4s_ease-out]'
          )}>
            <nav className="space-y-1">
              {sections.map((section, index) => (
                <button
                  key={section.id}
                  onClick={() => setActiveSection(section.id)}
                  className={cn(
                    'w-full flex items-center gap-3 px-4 py-3 rounded-xl text-left transition-all duration-300',
                    'animate-[fadeIn_0.3s_ease-out]',
                    activeSection === section.id
                      ? 'bg-accent/10 border border-accent/30 shadow-[0_0_20px_rgba(255,107,53,0.1)]'
                      : 'border border-transparent hover:bg-surface-elevated'
                  )}
                  style={{ animationDelay: `${index * 50}ms` }}
                >
                  <div className={cn(
                    'w-10 h-10 rounded-xl flex items-center justify-center transition-all duration-300',
                    activeSection === section.id
                      ? 'bg-gradient-to-br from-accent/20 to-accent/5'
                      : 'bg-surface-elevated'
                  )}>
                    <section.icon className={cn(
                      'w-5 h-5 transition-colors',
                      activeSection === section.id ? 'text-accent' : 'text-text-muted'
                    )} />
                  </div>
                  <div>
                    <p className={cn(
                      'text-sm font-semibold transition-colors',
                      activeSection === section.id ? 'text-accent' : 'text-text-primary'
                    )}>
                      {section.label}
                    </p>
                    <p className="text-xs text-text-muted">{section.description}</p>
                  </div>
                </button>
              ))}

              <div className="border-t border-border my-4" />

              <button
                onClick={logout}
                className={cn(
                  'w-full flex items-center gap-3 px-4 py-3 rounded-xl',
                  'border border-transparent hover:border-error/30 hover:bg-error/5',
                  'transition-all duration-300 group'
                )}
              >
                <div className="w-10 h-10 rounded-xl bg-error/10 flex items-center justify-center group-hover:bg-error/20 transition-colors">
                  <LogOut className="w-5 h-5 text-error" />
                </div>
                <div className="text-left">
                  <p className="text-sm font-semibold text-error">Déconnexion</p>
                  <p className="text-xs text-text-muted">Se déconnecter du compte</p>
                </div>
              </button>
            </nav>
          </div>

          {/* Content */}
          <div className="col-span-3 space-y-6">
            {/* Profile Section */}
            {activeSection === 'profile' && (
              <div className={cn(
                'p-6 rounded-2xl',
                'bg-surface border border-border',
                'animate-[fadeIn_0.4s_ease-out]'
              )}>
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-accent/20 to-accent/5 flex items-center justify-center">
                    <User className="w-6 h-6 text-accent" />
                  </div>
                  <div>
                    <h2 className="text-lg font-semibold text-text-primary">Profil</h2>
                    <p className="text-sm text-text-muted">Gérez vos informations personnelles</p>
                  </div>
                </div>

                {/* Avatar Section */}
                <div className={cn(
                  'flex items-center gap-6 p-5 rounded-xl mb-6',
                  'bg-surface-elevated border border-border'
                )}>
                  <div className="relative group">
                    <Avatar name={coach?.name || 'Coach'} size="xl" className="w-24 h-24 text-2xl" />
                    <button className={cn(
                      'absolute inset-0 flex items-center justify-center rounded-full',
                      'bg-black/50 opacity-0 group-hover:opacity-100',
                      'transition-opacity duration-200'
                    )}>
                      <Camera className="w-6 h-6 text-white" />
                    </button>
                  </div>
                  <div>
                    <h3 className="font-semibold text-text-primary mb-1">{coach?.name || 'Coach'}</h3>
                    <p className="text-sm text-text-muted mb-3">{coach?.email || 'coach@fitgame.app'}</p>
                    <button className={cn(
                      'flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium',
                      'bg-surface border border-border',
                      'hover:border-accent/30 hover:text-accent',
                      'transition-all duration-200'
                    )}>
                      <Camera className="w-4 h-4" />
                      Changer la photo
                    </button>
                  </div>
                </div>

                {/* Form Fields */}
                <div className="grid grid-cols-2 gap-4 mb-6">
                  <div className="space-y-2">
                    <label className="flex items-center gap-2 text-sm font-medium text-text-secondary">
                      <User className="w-4 h-4" />
                      Nom complet
                    </label>
                    <input
                      type="text"
                      defaultValue={coach?.name}
                      className={cn(
                        'w-full h-12 px-4 rounded-xl',
                        'bg-surface-elevated border border-border',
                        'text-text-primary placeholder:text-text-muted',
                        'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                        'transition-all duration-200'
                      )}
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="flex items-center gap-2 text-sm font-medium text-text-secondary">
                      <Mail className="w-4 h-4" />
                      Email
                    </label>
                    <input
                      type="email"
                      defaultValue={coach?.email}
                      className={cn(
                        'w-full h-12 px-4 rounded-xl',
                        'bg-surface-elevated border border-border',
                        'text-text-primary placeholder:text-text-muted',
                        'focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/20',
                        'transition-all duration-200'
                      )}
                    />
                  </div>
                </div>

                {/* Save Button */}
                <div className="flex justify-end">
                  <button className={cn(
                    'flex items-center gap-2 h-11 px-6 rounded-xl font-semibold text-white',
                    'bg-gradient-to-r from-accent to-[#ff8f5c]',
                    'hover:shadow-[0_0_25px_rgba(255,107,53,0.35)]',
                    'transition-all duration-300'
                  )}>
                    <Check className="w-5 h-5" />
                    Enregistrer
                  </button>
                </div>
              </div>
            )}

            {/* Notifications Section */}
            {activeSection === 'notifications' && (
              <div className={cn(
                'p-6 rounded-2xl',
                'bg-surface border border-border',
                'animate-[fadeIn_0.4s_ease-out]'
              )}>
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-info/20 to-info/5 flex items-center justify-center">
                    <Bell className="w-6 h-6 text-info" />
                  </div>
                  <div>
                    <h2 className="text-lg font-semibold text-text-primary">Notifications</h2>
                    <p className="text-sm text-text-muted">Configurez vos préférences de notification</p>
                  </div>
                </div>

                <div className="space-y-3">
                  {notifications.map((item, index) => (
                    <div
                      key={item.id}
                      className={cn(
                        'flex items-center justify-between p-4 rounded-xl',
                        'bg-surface-elevated border border-border',
                        'hover:border-info/20 transition-all duration-200',
                        'animate-[fadeIn_0.3s_ease-out]'
                      )}
                      style={{ animationDelay: `${index * 50}ms` }}
                    >
                      <div>
                        <p className="font-medium text-text-primary">{item.label}</p>
                        <p className="text-sm text-text-muted">{item.description}</p>
                      </div>
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input
                          type="checkbox"
                          defaultChecked={item.enabled}
                          className="sr-only peer"
                        />
                        <div className={cn(
                          'w-12 h-7 rounded-full transition-all duration-300',
                          'bg-surface border border-border',
                          'peer-checked:bg-gradient-to-r peer-checked:from-accent peer-checked:to-[#ff8f5c] peer-checked:border-transparent',
                          'peer-checked:shadow-[0_0_15px_rgba(255,107,53,0.3)]',
                          'after:content-[\'\'] after:absolute after:top-1 after:left-1',
                          'after:bg-text-muted after:peer-checked:bg-white',
                          'after:rounded-full after:h-5 after:w-5 after:transition-all after:duration-300',
                          'peer-checked:after:translate-x-5'
                        )} />
                      </label>
                    </div>
                  ))}
                </div>

                {/* Save Button */}
                <div className="flex justify-end mt-6">
                  <button className={cn(
                    'flex items-center gap-2 h-11 px-6 rounded-xl font-semibold text-white',
                    'bg-gradient-to-r from-info to-[#60a5fa]',
                    'hover:shadow-[0_0_25px_rgba(59,130,246,0.35)]',
                    'transition-all duration-300'
                  )}>
                    <Check className="w-5 h-5" />
                    Enregistrer
                  </button>
                </div>
              </div>
            )}

            {/* Security Section */}
            {activeSection === 'security' && (
              <div className="space-y-6">
                {/* Password Change */}
                <div className={cn(
                  'p-6 rounded-2xl',
                  'bg-surface border border-border',
                  'animate-[fadeIn_0.4s_ease-out]'
                )}>
                  <div className="flex items-center gap-3 mb-6">
                    <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-warning/20 to-warning/5 flex items-center justify-center">
                      <Lock className="w-6 h-6 text-warning" />
                    </div>
                    <div>
                      <h2 className="text-lg font-semibold text-text-primary">Mot de passe</h2>
                      <p className="text-sm text-text-muted">Changez votre mot de passe</p>
                    </div>
                  </div>

                  <div className="space-y-4">
                    {[
                      { id: 'current', label: 'Mot de passe actuel' },
                      { id: 'new', label: 'Nouveau mot de passe' },
                      { id: 'confirm', label: 'Confirmer le mot de passe' },
                    ].map((field, index) => (
                      <div
                        key={field.id}
                        className="space-y-2 animate-[fadeIn_0.3s_ease-out]"
                        style={{ animationDelay: `${index * 50}ms` }}
                      >
                        <label className="flex items-center gap-2 text-sm font-medium text-text-secondary">
                          <KeyRound className="w-4 h-4" />
                          {field.label}
                        </label>
                        <div className="relative">
                          <input
                            type={showPassword[field.id] ? 'text' : 'password'}
                            placeholder="••••••••"
                            className={cn(
                              'w-full h-12 px-4 pr-12 rounded-xl',
                              'bg-surface-elevated border border-border',
                              'text-text-primary placeholder:text-text-muted',
                              'focus:outline-none focus:border-warning focus:ring-2 focus:ring-warning/20',
                              'transition-all duration-200'
                            )}
                          />
                          <button
                            onClick={() => togglePassword(field.id)}
                            className="absolute right-4 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-primary transition-colors"
                          >
                            {showPassword[field.id] ? (
                              <EyeOff className="w-5 h-5" />
                            ) : (
                              <Eye className="w-5 h-5" />
                            )}
                          </button>
                        </div>
                      </div>
                    ))}

                    <button className={cn(
                      'flex items-center gap-2 h-11 px-6 rounded-xl font-semibold',
                      'bg-warning/10 text-warning border border-warning/30',
                      'hover:bg-warning/20 hover:shadow-[0_0_15px_rgba(234,179,8,0.2)]',
                      'transition-all duration-300'
                    )}>
                      <Lock className="w-4 h-4" />
                      Mettre à jour
                    </button>
                  </div>
                </div>

                {/* 2FA */}
                <div className={cn(
                  'p-6 rounded-2xl',
                  'bg-surface border border-border',
                  'animate-[fadeIn_0.4s_ease-out_100ms]'
                )}>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-success/20 to-success/5 flex items-center justify-center">
                        <Smartphone className="w-7 h-7 text-success" />
                      </div>
                      <div>
                        <h3 className="font-semibold text-text-primary">
                          Authentification à deux facteurs
                        </h3>
                        <p className="text-sm text-text-muted">
                          Ajoutez une couche de sécurité supplémentaire à votre compte
                        </p>
                      </div>
                    </div>
                    <button className={cn(
                      'flex items-center gap-2 h-11 px-5 rounded-xl font-semibold',
                      'bg-gradient-to-r from-success to-[#4ade80] text-white',
                      'hover:shadow-[0_0_25px_rgba(34,197,94,0.35)]',
                      'transition-all duration-300'
                    )}>
                      <Shield className="w-4 h-4" />
                      Configurer
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* Appearance Section */}
            {activeSection === 'appearance' && (
              <div className={cn(
                'p-6 rounded-2xl',
                'bg-surface border border-border',
                'animate-[fadeIn_0.4s_ease-out]'
              )}>
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-purple-500/20 to-purple-500/5 flex items-center justify-center">
                    <Palette className="w-6 h-6 text-purple-500" />
                  </div>
                  <div>
                    <h2 className="text-lg font-semibold text-text-primary">Apparence</h2>
                    <p className="text-sm text-text-muted">Personnalisez l'interface de l'application</p>
                  </div>
                </div>

                {/* Theme Selection */}
                <div className="mb-8">
                  <h4 className="text-sm font-semibold text-text-primary mb-4">Thème</h4>
                  <div className="grid grid-cols-3 gap-4">
                    {themes.map((theme, index) => (
                      <button
                        key={theme.id}
                        onClick={() => theme.available && setSelectedTheme(theme.id)}
                        disabled={!theme.available}
                        className={cn(
                          'relative p-4 rounded-xl transition-all duration-300',
                          'animate-[fadeIn_0.3s_ease-out]',
                          selectedTheme === theme.id
                            ? 'bg-accent/10 border-2 border-accent shadow-[0_0_20px_rgba(255,107,53,0.1)]'
                            : 'bg-surface-elevated border border-border hover:border-border',
                          !theme.available && 'opacity-50 cursor-not-allowed'
                        )}
                        style={{ animationDelay: `${index * 50}ms` }}
                      >
                        {/* Theme preview */}
                        <div
                          className="w-full h-20 rounded-lg mb-3 overflow-hidden border border-border"
                          style={{ background: theme.bg }}
                        >
                          {theme.id === 'dark' && (
                            <div className="p-2 space-y-1">
                              <div className="w-1/2 h-2 bg-white/10 rounded" />
                              <div className="w-3/4 h-2 bg-white/5 rounded" />
                              <div className="w-1/3 h-2 bg-accent/30 rounded" />
                            </div>
                          )}
                        </div>
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <theme.icon className={cn(
                              'w-4 h-4',
                              selectedTheme === theme.id ? 'text-accent' : 'text-text-muted'
                            )} />
                            <span className={cn(
                              'text-sm font-medium',
                              selectedTheme === theme.id ? 'text-accent' : 'text-text-primary'
                            )}>
                              {theme.label}
                            </span>
                          </div>
                          {selectedTheme === theme.id && (
                            <div className="w-5 h-5 rounded-full bg-accent flex items-center justify-center">
                              <Check className="w-3 h-3 text-white" />
                            </div>
                          )}
                        </div>
                        {!theme.available && (
                          <span className="absolute top-2 right-2 text-xs px-2 py-0.5 rounded-full bg-surface-elevated text-text-muted">
                            Bientôt
                          </span>
                        )}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Accent Color */}
                <div>
                  <h4 className="text-sm font-semibold text-text-primary mb-4">Couleur d'accent</h4>
                  <div className="flex items-center gap-3">
                    {accentColors.map((accent, index) => (
                      <button
                        key={accent.id}
                        onClick={() => index === 0 && setSelectedAccent(accent.id)}
                        disabled={index !== 0}
                        className={cn(
                          'relative w-12 h-12 rounded-xl transition-all duration-300',
                          'animate-[fadeIn_0.3s_ease-out]',
                          selectedAccent === accent.id && 'ring-2 ring-white/20 ring-offset-2 ring-offset-background',
                          index !== 0 && 'opacity-40 cursor-not-allowed'
                        )}
                        style={{
                          backgroundColor: accent.color,
                          animationDelay: `${index * 50}ms`
                        }}
                        title={accent.label}
                      >
                        {selectedAccent === accent.id && (
                          <Check className="w-5 h-5 text-white absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2" />
                        )}
                        {index !== 0 && (
                          <Lock className="w-3 h-3 text-white/70 absolute bottom-1 right-1" />
                        )}
                      </button>
                    ))}
                  </div>
                  <p className="text-xs text-text-muted mt-3">
                    Plus de couleurs disponibles prochainement
                  </p>
                </div>
              </div>
            )}

            {/* Help Section */}
            {activeSection === 'help' && (
              <div className="space-y-6">
                <div className={cn(
                  'p-6 rounded-2xl',
                  'bg-surface border border-border',
                  'animate-[fadeIn_0.4s_ease-out]'
                )}>
                  <div className="flex items-center gap-3 mb-6">
                    <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-cyan-500/20 to-cyan-500/5 flex items-center justify-center">
                      <HelpCircle className="w-6 h-6 text-cyan-500" />
                    </div>
                    <div>
                      <h2 className="text-lg font-semibold text-text-primary">Aide & Support</h2>
                      <p className="text-sm text-text-muted">Ressources et assistance</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    {helpLinks.map((link, index) => (
                      <button
                        key={link.label}
                        className={cn(
                          'group flex items-center gap-4 p-4 rounded-xl text-left',
                          'bg-surface-elevated border border-border',
                          'hover:border-accent/30 hover:shadow-[0_0_20px_rgba(255,107,53,0.05)]',
                          'transition-all duration-300',
                          'animate-[fadeIn_0.3s_ease-out]'
                        )}
                        style={{ animationDelay: `${index * 50}ms` }}
                      >
                        <div className={cn(
                          'w-12 h-12 rounded-xl flex items-center justify-center transition-all duration-300',
                          link.color === 'accent' && 'bg-accent/10 group-hover:bg-accent/20',
                          link.color === 'info' && 'bg-info/10 group-hover:bg-info/20',
                          link.color === 'success' && 'bg-success/10 group-hover:bg-success/20',
                          link.color === 'warning' && 'bg-warning/10 group-hover:bg-warning/20'
                        )}>
                          <link.icon className={cn(
                            'w-5 h-5',
                            link.color === 'accent' && 'text-accent',
                            link.color === 'info' && 'text-info',
                            link.color === 'success' && 'text-success',
                            link.color === 'warning' && 'text-warning'
                          )} />
                        </div>
                        <div className="flex-1">
                          <p className="font-medium text-text-primary group-hover:text-accent transition-colors">
                            {link.label}
                          </p>
                          <p className="text-sm text-text-muted">{link.description}</p>
                        </div>
                        <ExternalLink className="w-4 h-4 text-text-muted opacity-0 group-hover:opacity-100 transition-opacity" />
                      </button>
                    ))}
                  </div>
                </div>

                {/* Version Info */}
                <div className={cn(
                  'p-6 rounded-2xl text-center',
                  'bg-surface border border-border',
                  'animate-[fadeIn_0.4s_ease-out_100ms]'
                )}>
                  <div className="w-16 h-16 mx-auto rounded-2xl bg-gradient-to-br from-accent/20 to-accent/5 flex items-center justify-center mb-4">
                    <Sparkles className="w-8 h-8 text-accent" />
                  </div>
                  <h3 className="font-semibold text-text-primary mb-1">FitGame Coach</h3>
                  <p className="text-sm text-text-muted mb-4">Version 1.0.0</p>
                  <div className="flex items-center justify-center gap-4 text-xs text-text-muted">
                    <button className="hover:text-accent transition-colors">Conditions d'utilisation</button>
                    <span>•</span>
                    <button className="hover:text-accent transition-colors">Politique de confidentialité</button>
                  </div>
                  <p className="text-xs text-text-muted mt-4">
                    © 2026 FitGame. Tous droits réservés.
                  </p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
