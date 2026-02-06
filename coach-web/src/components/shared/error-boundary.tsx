import { Component, type ReactNode } from 'react'
import { AlertTriangle, RefreshCw } from 'lucide-react'

interface ErrorBoundaryProps {
  children: ReactNode
  fallback?: ReactNode
}

interface ErrorBoundaryState {
  hasError: boolean
  error?: Error
}

export class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  state: ErrorBoundaryState = { hasError: false }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error }
  }

  handleReset = () => {
    this.setState({ hasError: false, error: undefined })
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) return this.props.fallback

      return (
        <div className="flex flex-col items-center justify-center min-h-[400px] p-8">
          <AlertTriangle className="w-12 h-12 text-orange-500 mb-4" />
          <h2 className="text-xl font-bold text-white mb-2">Une erreur est survenue</h2>
          <p className="text-zinc-400 text-center mb-6 max-w-md">
            {this.state.error?.message || "Quelque chose s'est mal passe."}
          </p>
          <button
            onClick={this.handleReset}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-zinc-800 text-white hover:bg-zinc-700 transition-colors"
          >
            <RefreshCw className="w-4 h-4" />
            Reessayer
          </button>
        </div>
      )
    }

    return this.props.children
  }
}
