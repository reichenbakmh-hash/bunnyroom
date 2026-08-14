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
    return (
      <div className="min-h-screen flex items-center justify-center bg-neutral-950 px-6">
        <div className="text-center space-y-2 max-w-sm">
          <h1 className="text-lg font-light text-neutral-100">Configuration manquante</h1>
          <p className="text-sm text-neutral-500">
            Les variables VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY ne sont pas
            disponibles dans ce déploiement. Vérifie qu'elles sont bien définies
            dans Cloudflare Pages → Settings → Environment variables, puis
            redéploie.
          </p>
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
