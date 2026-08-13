import { useAuth } from '@/hooks/useAuth'
import { useRelationship } from '@/hooks/useRelationship'

export default function DashboardPage() {
  const { profile, signOut } = useAuth()
  const { relationship, role, partnerName, loading } = useRelationship()

  return (
    <div className="min-h-screen bg-neutral-950 text-neutral-100 px-4 py-8">
      <div className="max-w-sm mx-auto space-y-6">
        <div>
          <p className="text-xs text-neutral-500 uppercase tracking-wide">BunnyRoom</p>
          <h1 className="text-xl font-light">Bonjour, {profile?.display_name ?? '…'}</h1>
        </div>

        {loading ? (
          <p className="text-sm text-neutral-500">Chargement de votre relation…</p>
        ) : relationship ? (
          <div className="rounded-lg border border-neutral-800 p-4 space-y-1">
            <p className="text-sm text-neutral-400">
              Rôle : <span className="text-neutral-100">{role === 'mistress' ? 'Mistress' : 'Submissive'}</span>
            </p>
            <p className="text-sm text-neutral-400">
              Partenaire :{' '}
              <span className="text-neutral-100">
                {partnerName ?? "en attente qu'iel rejoigne avec le code"}
              </span>
            </p>
            <p className="text-sm text-neutral-400">
              Statut : <span className="text-neutral-100">{relationship.status}</span>
            </p>
            {relationship.invite_code && !partnerName && (
              <p className="text-sm text-neutral-400 pt-2">
                Code d'invitation :{' '}
                <span className="text-neutral-100 tracking-widest">{relationship.invite_code}</span>
              </p>
            )}
          </div>
        ) : (
          <p className="text-sm text-neutral-500">Aucune relation trouvée.</p>
        )}

        <p className="text-xs text-neutral-600">
          Règles, tâches, rituels et demandes arrivent dans la prochaine phase.
        </p>

        <button
          onClick={signOut}
          className="text-xs text-neutral-500 underline underline-offset-2"
        >
          Se déconnecter
        </button>
      </div>
    </div>
  )
}
