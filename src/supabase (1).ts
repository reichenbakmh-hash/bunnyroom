import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const isSupabaseConfigured = Boolean(url && anonKey)

if (!isSupabaseConfigured) {
  console.warn(
    '[BunnyRoom] Supabase non configuré — VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY sont absents.'
  )
}

// URL de repli syntaxiquement valide : évite un crash immédiat de createClient
// quand les variables d'environnement ne sont pas injectées au build.
// L'app affiche un écran d'erreur clair via isSupabaseConfigured plutôt que de planter.
export const supabase = createClient(
  isSupabaseConfigured ? url : 'https://placeholder.supabase.co',
  isSupabaseConfigured ? anonKey : 'placeholder-key'
)
