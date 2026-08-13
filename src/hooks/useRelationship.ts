import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { useAuth } from './useAuth'
import type { Relationship, Role } from '../types'

interface RelationshipState {
  relationship: Relationship | null
  role: Role | null
  partnerName: string | null
  loading: boolean
  refresh: () => Promise<void>
}

export function useRelationship(): RelationshipState {
  const { user } = useAuth()
  const [relationship, setRelationship] = useState<Relationship | null>(null)
  const [role, setRole] = useState<Role | null>(null)
  const [partnerName, setPartnerName] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  const refresh = useCallback(async () => {
    if (!user) {
      setRelationship(null)
      setRole(null)
      setPartnerName(null)
      setLoading(false)
      return
    }

    setLoading(true)

    const { data: membership } = await supabase
      .from('relationship_members')
      .select('relationship_id, role')
      .eq('user_id', user.id)
      .maybeSingle()

    if (!membership) {
      setRelationship(null)
      setRole(null)
      setPartnerName(null)
      setLoading(false)
      return
    }

    setRole(membership.role as Role)

    const { data: rel } = await supabase
      .from('relationships')
      .select('*')
      .eq('id', membership.relationship_id)
      .maybeSingle()

    setRelationship(rel as Relationship | null)

    const { data: partner } = await supabase
      .from('relationship_members')
      .select('user_id, role, profiles(display_name)')
      .eq('relationship_id', membership.relationship_id)
      .neq('user_id', user.id)
      .maybeSingle()

    // @ts-expect-error — jointure imbriquée typée en any par supabase-js
    setPartnerName(partner?.profiles?.display_name ?? null)

    setLoading(false)
  }, [user])

  useEffect(() => {
    refresh()
  }, [refresh])

  return { relationship, role, partnerName, loading, refresh }
}
