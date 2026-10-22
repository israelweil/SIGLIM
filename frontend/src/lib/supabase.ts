import { createClient } from '@supabase/supabase-js'
import { env } from '@/config/env'

/** Cliente de Supabase solo para iniciar sesión y renovar el token (AGENTS.md §9). */
export const supabase = createClient(env.supabaseUrl, env.supabasePublishableKey)
