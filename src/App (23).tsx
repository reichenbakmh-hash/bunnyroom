import { AuthProvider, useAuth } from './hooks/useAuth'
import { useRelationship } from './hooks/useRelationship'
import { isSupabaseConfigured } from './lib/supabase'
import AuthPage from './pages/AuthPage'
import OnboardingPage from './pages/OnboardingPage'
import DashboardPage from './pages/DashboardPage'

function Gate() {
  const { user, loading: authLoading } = useAuth()
  const { relationship, loading: relLoading, refresh } = useRelationship()

  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-neutral-950">
        <p className="text-sm text-neutral-500">Chargement…</p>
      </div>
    )
  }

  if (!user) return <AuthPage />

  if (relLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-neutral-950">
        <p className="text-sm text-neutral-500">Chargement…</p>
      </div>
    )
  }

  if (!relationship) return <OnboardingPage onDone={refresh} />

  return <DashboardPage />
}

export default function App() {
  if (!isSupabaseConfigured) {
    const rawUrl = import.meta.env.VITE_SUPABASE_URL
    const rawKey = import.meta.env.VITE_SUPABASE_ANON_KEY
    return (
      <div className="min-h-screen flex items-center justify-center bg-neutral-950 px-6">
        <div className="text-center space-y-3 max-w-sm">
          <h1 className="text-lg font-light text-neutral-100">Configuration manquante</h1>
          <p className="text-sm text-neutral-500">
            Les variables VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY ne sont pas
            disponibles dans ce déploiement.
          </p>
          <div className="text-left text-xs text-neutral-600 bg-neutral-900 rounded-lg p-3 space-y-1 break-all">
            <p>VITE_SUPABASE_URL reçue : {rawUrl ? `"${rawUrl}"` : '(absente / vide)'}</p>
            <p>VITE_SUPABASE_ANON_KEY reçue : {rawKey ? `${rawKey.length} caractères` : '(absente / vide)'}</p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <AuthProvider>
      <Gate />
    </AuthProvider>
  )
}
