import { useQuery } from '@tanstack/react-query'
import { api } from '@/lib/api/cliente'
import type { Yo } from '@/features/seguridad/tipos'

/** Clave compartida por la barra superior y la navegación para consultar `/yo` una vez. */
export const claveYo = ['yo'] as const

export function consultarYo(): Promise<Yo> {
  return api.get<Yo>('/yo')
}

/**
 * Datos del usuario actual (H-01.3). Sin reintentos automáticos: un 401 debe
 * cerrar la sesión de inmediato y los demás errores se muestran con un botón
 * para reintentar.
 */
export function useYo() {
  return useQuery({
    queryKey: claveYo,
    queryFn: consultarYo,
    retry: false,
  })
}
