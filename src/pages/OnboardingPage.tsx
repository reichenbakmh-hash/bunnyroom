import { useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/hooks/useAuth'
import type { Role } from '@/types'

function genererCodeInvitation(): string {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789' // sans 0/O/1/I ambigus
  let code = ''
  for (let i = 0; i < 6; i++) {
    code += alphabet[Math.floor(Math.random() * alphabet.length)]
  }
  return code
}

export default function OnboardingPage({ onDone }: { onDone: () => void }) {
  const { user } = useAuth()
  const [mode, setMode] = useState<'choice' | 'create' | 'join'>('choice')
  const [role, setRole] = useState<Role>('submissive')
  const [joinCode, setJoinCode] = useState('')
  const [createdCode, setCreatedCode] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  async function handleCreate() {
    if (!user) return
    setError(null)
    setLoading(true)

    const code = genererCodeInvitation()

    const { data: relationship, error: relError } = await supabase
      .from('relationships')
      .insert({ created_by: user.id, invite_code: code })
      .select()
      .single()

    if (relError || !relationship) {
      setError("Impossible de créer la relation. Réessaie.")
      setLoading(false)
      return
    }

    const { error: memberError } = await supabase
      .from('relationship_members')
      .insert({ relationship_id: relationship.id, user_id: user.id, role })

    if (memberError) {
      setError("Impossible de t'ajouter à la relation. Réessaie.")
      setLoading(false)
      return
    }

    setCreatedCode(code)
    setLoading(false)
  }

  async function handleJoin() {
    if (!user) return
    setError(null)
    setLoading(true)

    const cleanCode = joinCode.trim().toUpperCase()

    const { data: relationship, error: findError } = await supabase
      .from('relationships')
      .select('id')
      .eq('invite_code', cleanCode)
      .maybeSingle()

    if (findError || !relationship) {
      setError('Code introuvable. Vérifie-le auprès de ton/ta partenaire.')
      setLoading(false)
      return
    }

    const { data: existingMembers } = await supabase
      .from('relationship_members')
      .select('role')
      .eq('relationship_id', relationship.id)

    if (existingMembers && existingMembers.length >= 2) {
      setError('Cette relation a déjà ses deux membres.')
      setLoading(false)
      return
    }

    const takenRole = existingMembers?.[0]?.role
    const myRole: Role = takenRole === 'mistress' ? 'submissive' : 'mistress'

    const { error: joinError } = await supabase
      .from('relationship_members')
      .insert({ relationship_id: relationship.id, user_id: user.id, role: myRole })

    if (joinError) {
      setError("Impossible de rejoindre cette relation. Réessaie.")
      setLoading(false)
      return
    }

    setLoading(false)
    onDone()
  }

  if (createdCode) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-neutral-950 px-4">
        <div className="w-full max-w-sm text-center space-y-4">
          <h2 className="text-lg font-light text-neutral-100">Relation créée</h2>
          <p className="text-sm text-neutral-500">
            Partage ce code avec ton/ta partenaire pour qu'iel puisse te rejoindre :
          </p>
          <div className="rounded-lg bg-neutral-900 border border-neutral-800 py-4 text-2xl tracking-[0.3em] text-neutral-100">
            {createdCode}
          </div>
          <button
            onClick={onDone}
            className="w-full rounded-lg bg-neutral-100 text-neutral-900 py-2 text-sm font-medium"
          >
            Continuer
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-neutral-950 px-4">
      <div className="w-full max-w-sm space-y-6">
        <div className="text-center space-y-1">
          <h1 className="text-xl font-light tracking-wide text-neutral-100">
            Bienvenue sur BunnyRoom
          </h1>
          <p className="text-sm text-neutral-500">
            Crée votre espace privé ou rejoins celui de ton/ta partenaire.
          </p>
        </div>

        {mode === 'choice' && (
          <div className="space-y-3">
            <button
              onClick={() => setMode('create')}
              className="w-full rounded-lg bg-neutral-100 text-neutral-900 py-2.5 text-sm font-medium"
            >
              Créer une relation
            </button>
            <button
              onClick={() => setMode('join')}
              className="w-full rounded-lg border border-neutral-800 text-neutral-200 py-2.5 text-sm font-medium"
            >
              Rejoindre avec un code
            </button>
          </div>
        )}

        {mode === 'create' && (
          <div className="space-y-4">
            <div>
              <p className="text-xs text-neutral-400 mb-2">Ton rôle dans cette relation</p>
              <div className="grid grid-cols-2 gap-2">
                <button
                  onClick={() => setRole('mistress')}
                  className={`rounded-lg border py-2.5 text-sm ${
                    role === 'mistress'
                      ? 'border-neutral-100 text-neutral-100'
                      : 'border-neutral-800 text-neutral-500'
                  }`}
                >
                  Mistress
                </button>
                <button
                  onClick={() => setRole('submissive')}
                  className={`rounded-lg border py-2.5 text-sm ${
                    role === 'submissive'
                      ? 'border-neutral-100 text-neutral-100'
                      : 'border-neutral-800 text-neutral-500'
                  }`}
                >
                  Submissive
                </button>
              </div>
            </div>

            {error && <p className="text-sm text-red-400">{error}</p>}

            <button
              onClick={handleCreate}
              disabled={loading}
              className="w-full rounded-lg bg-neutral-100 text-neutral-900 py-2.5 text-sm font-medium disabled:opacity-50"
            >
              {loading ? 'Un instant…' : 'Créer et générer le code'}
            </button>
            <button
              onClick={() => setMode('choice')}
              className="w-full text-center text-xs text-neutral-500"
            >
              Retour
            </button>
          </div>
        )}

        {mode === 'join' && (
          <div className="space-y-4">
            <div>
              <label className="block text-xs text-neutral-400 mb-1" htmlFor="code">
                Code d'invitation
              </label>
              <input
                id="code"
                type="text"
                value={joinCode}
                onChange={(e) => setJoinCode(e.target.value)}
                placeholder="ABC123"
                className="w-full rounded-lg bg-neutral-900 border border-neutral-800 px-3 py-2 text-neutral-100 text-sm tracking-widest text-center focus:outline-none focus:ring-1 focus:ring-neutral-600"
              />
            </div>

            {error && <p className="text-sm text-red-400">{error}</p>}

            <button
              onClick={handleJoin}
              disabled={loading || joinCode.trim().length === 0}
              className="w-full rounded-lg bg-neutral-100 text-neutral-900 py-2.5 text-sm font-medium disabled:opacity-50"
            >
              {loading ? 'Un instant…' : 'Rejoindre'}
            </button>
            <button
              onClick={() => setMode('choice')}
              className="w-full text-center text-xs text-neutral-500"
            >
              Retour
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
