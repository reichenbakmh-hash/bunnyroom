export type Role = 'mistress' | 'submissive'

export type RelationshipStatus = 'active' | 'paused' | 'archived'

export interface Relationship {
  id: string
  mistress_id: string
  submissive_id: string | null
  status: RelationshipStatus
  started_at: string
  invite_code: string | null
}

export type RuleStatus = 'draft' | 'active' | 'suspended' | 'expired' | 'archived'

export interface Rule {
  id: string
  relationship_id: string
  article_number: number
  title: string
  category: string
  description: string
  status: RuleStatus
  frequency: string | null
  priority: 'low' | 'medium' | 'high'
  effective_date: string | null
  expiration_date: string | null
  created_at: string
  updated_at: string
}

export type TaskStatus =
  | 'assigned'
  | 'in_progress'
  | 'submitted'
  | 'approved'
  | 'rejected'
  | 'expired'

export interface Task {
  id: string
  relationship_id: string
  title: string
  description: string
  assigned_date: string
  due_date: string | null
  recurrence: string | null
  priority: 'low' | 'medium' | 'high'
  points: number
  proof_required: boolean
  status: TaskStatus
  created_at: string
}

export interface Ritual {
  id: string
  relationship_id: string
  title: string
  description: string
  schedule: string | null
  recurrence: string | null
  active: boolean
}

export interface RitualStep {
  id: string
  ritual_id: string
  order_index: number
  content: string
}

export type RequestStatus = 'pending' | 'approved' | 'rejected' | 'cancelled'

export interface RelationshipRequest {
  id: string
  relationship_id: string
  title: string
  message: string
  status: RequestStatus
  mistress_response: string | null
  created_at: string
}

export interface Reward {
  id: string
  relationship_id: string
  title: string
  description: string
  point_cost: number
  active: boolean
}

export interface JournalEntry {
  id: string
  relationship_id: string
  author_id: string
  title: string
  content: string
  mood: string | null
  tags: string[]
  visibility: 'private' | 'shared' | 'mistress_note'
  created_at: string
}
