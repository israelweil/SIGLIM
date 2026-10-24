import { useCallback, useState } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { useNavigate } from 'react-router'
import { supabase } from '@/lib/supabase'
import type { Asignacion } from '@/features/seguridad/tipos'

function nombreDelAmbito(asignacion: Asignacion): string {
  if (asignacion.ambito === 'CLUB') {
    return asignacion.club?.nombre ?? 'Club'
  }

  return asignacion.ambito === 'LIGA' ? 'Liga' : 'Propio'
}

/**
 * Texto de la barra superior con el rol y el ámbito de la asignación principal
 * (H-01, criterio 1). El backend ordena las asignaciones por ámbito y rol.
 */
export function descripcionDeAcceso(asignaciones: readonly Asignacion[]): string {
  const [principal] = asignaciones

  if (!principal) {
    return 'Sin rol asignado'
  }

  const adicionales = asignaciones.length > 1 ? ` (+${asignaciones.length - 1})` : ''

  return `${principal.rol.nombre} · ${nombreDelAmbito(principal)}${adicionales}`
}

/**
 * Elimina la sesión de Supabase Auth (criterio 4 de H-01). Si el cierre global
 * falla, fuerza el cierre local para que el token no quede en el navegador.
 */
export async function cerrarSesionSupabase(): Promise<void> {
  try {
    const { error } = await supabase.auth.signOut()

    if (!error) {
      return
    }
  } catch {
    // Se intenta el cierre local antes de devolver el control.
  }

  try {
    await supabase.auth.signOut({ scope: 'local' })
  } catch {
    // La navegación al acceso se hace de todos modos; allí se vuelve a comprobar la sesión.
  }
}

/** Cierra la sesión, descarta los datos cacheados y vuelve a `/login`. */
export function useCerrarSesion() {
  const navegar = useNavigate()
  const clienteConsultas = useQueryClient()
  const [cerrando, setCerrando] = useState(false)

  const cerrar = useCallback(async () => {
    setCerrando(true)

    try {
      await cerrarSesionSupabase()
      clienteConsultas.clear()
      navegar('/login', { replace: true })
    } finally {
      setCerrando(false)
    }
  }, [clienteConsultas, navegar])

  return { cerrar, cerrando }
}
