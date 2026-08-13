import { useState, type FormEvent } from 'react'
import { supabase } from '@/lib/supabase'

export default function AuthPage() {
  const [mode, setMode] = useState<'login' | 'signup'>('login')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [displayName, setDisplayName] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setLoading(true)

    if (mode === 'signup') {
      const { data, error: signUpError } = await supabase.auth.signUp({ email, password })
      if (signUpError) {
        setError(traduireErreur(signUpError.message))
        setLoading(false)
        return
      }
      if (data.user) {
        const { error: profileError } = await supabase
          .from('profiles')
          .insert({ id: data.user.id, display_name: displayName || 'Sans nom' })
        if (profileError) {
          setError(traduireErreur(profileError.message))
        }
      }
    } else {
      const { error: signInError } = await supabase.auth.signInWithPassword({ email, password })
      if (signInError) {
        setError(traduireErreur(signInError.message))
      }
    }

    setLoading(false)
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-neutral-950 px-4">
      <div className="w-full max-w-sm space-y-6">
        <div className="text-center space-y-1">
          <h1 className="text-2xl font-light tracking-wide text-neutral-100">BunnyRoom</h1>
          <p className="text-sm text-neutral-500">Espace privé de relation</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {mode === 'signup' && (
            <div>
              <label className="block text-xs text-neutral-400 mb-1" htmlFor="displayName">
                Prénom / pseudo
              </label>
              <input
                id="displayName"
                type="text"
                required
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                className="w-full rounded-lg bg-neutral-900 border border-neutral-800 px-3 py-2 text-neutral-100 text-sm focus:outline-none focus:ring-1 focus:ring-neutral-600"
              />
            </div>
          )}

          <div>
            <label className="block text-xs text-neutral-400 mb-1" htmlFor="email">
              Email
            </label>
            <input
              id="email"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full rounded-lg bg-neutral-900 border border-neutral-800 px-3 py-2 text-neutral-100 text-sm focus:outline-none focus:ring-1 focus:ring-neutral-600"
            />
          </div>

          <div>
            <label className="block text-xs text-neutral-400 mb-1" htmlFor="password">
              Mot de passe
            </label>
            <input
              id="password"
              type="password"
              required
              minLength={6}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-lg bg-neutral-900 border border-neutral-800 px-3 py-2 text-neutral-100 text-sm focus:outline-none focus:ring-1 focus:ring-neutral-600"
            />
          </div>

          {error && <p className="text-sm text-red-400">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-lg bg-neutral-100 text-neutral-900 py-2 text-sm font-medium disabled:opacity-50"
          >
            {loading ? 'Un instant…' : mode === 'login' ? 'Se connecter' : 'Créer mon compte'}
          </button>
        </form>

        <button
          type="button"
          onClick={() => setMode(mode === 'login' ? 'signup' : 'login')}
          className="w-full text-center text-xs text-neutral-500"
        >
          {mode === 'login'
            ? "Pas encore de compte ? S'inscrire"
            : 'Déjà un compte ? Se connecter'}
        </button>
      </div>
    </div>
  )
}

function traduireErreur(message: string): string {
  if (message.includes('Invalid login credentials')) return 'Email ou mot de passe incorrect.'
  if (message.includes('User already registered')) return 'Un compte existe déjà avec cet email.'
  if (message.includes('Password should be')) return 'Le mot de passe doit contenir au moins 6 caractères.'
  return "Une erreur s'est produite. Réessaie."
}
