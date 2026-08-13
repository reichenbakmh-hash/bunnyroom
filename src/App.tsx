import { AuthProvider, useAuth } from '@/hooks/useAuth'
import { useRelationship } from '@/hooks/useRelationship'
import AuthPage from '@/pages/AuthPage'
import OnboardingPage from '@/pages/OnboardingPage'
import DashboardPage from '@/pages/DashboardPage'

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
  return (
    <AuthProvider>
      <Gate />
    </AuthProvider>
  )
}
