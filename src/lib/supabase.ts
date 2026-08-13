import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!url || !anonKey) {
  // Le backend n'est pas encore branché : on log un avertissement
  // plutôt que de faire planter l'app pendant le développement du design.
  console.warn(
    '[BunnyRoom] Supabase non configuré — VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY sont absents.'
  )
}

export const supabase = createClient(url ?? '', anonKey ?? '')
