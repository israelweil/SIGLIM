import {
  createContext,
  useContext,
  useEffect,
  useRef,
  type ReactNode,
} from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { useLocation, useNavigate } from 'react-router'
import { CircleAlert, RefreshCw } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { useYo } from '@/features/seguridad/api'
import { cerrarSesionSupabase } from '@/features/seguridad/sesion'
import type { Yo } from '@/features/seguridad/tipos'
import { ApiError } from '@/lib/api/ApiError'

type Props = {
  children: ReactNode
}

type ContextoSesion = {
  yo: Yo
}

const ContextoSesion = createContext<ContextoSesion | null>(null)

/** Datos de `/yo` compartidos por la barra superior y la navegación interna. */
export function useSesionActual(): ContextoSesion {
  const contexto = useContext(ContextoSesion)

  if (!contexto) {
    throw new Error('useSesionActual debe usarse dentro de ProveedorSesionActual.')
  }

  return contexto
}

/**
 * Carga `GET /api/v1/yo` antes de mostrar la aplicación interna (H-01.3).
 * Si el backend responde 401, cierra la sesión de Supabase y vuelve a `/login`
 * conservando el destino interno. Otros errores se muestran con reintento.
 */
export function ProveedorSesionActual({ children }: Props) {
  const { data: yo, error, isPending, refetch } = useYo()
  const navegar = useNavigate()
  const ubicacion = useLocation()
  const clienteConsultas = useQueryClient()
  const redirigiendo = useRef(false)
  // Se decide por el código del problema, no por el estado HTTP (ApiError, convenciones §3).
  const sesionVencida = error instanceof ApiError && error.codigo === 'NO_AUTENTICADO'

  useEffect(() => {
    if (!sesionVencida || redirigiendo.current) {
      return
    }

    redirigiendo.current = true

    void cerrarSesionSupabase().finally(() => {
      clienteConsultas.clear()
      navegar('/login', {
        replace: true,
        state: { desde: ubicacion.pathname, sesionExpirada: true },
      })
    })
  }, [clienteConsultas, navegar, sesionVencida, ubicacion.pathname])

  if (sesionVencida) {
    return (
      <p role="status" className="p-4 text-body-md text-text-muted">
        Tu sesión venció. Redirigiendo al inicio de sesión…
      </p>
    )
  }

  if (isPending) {
    return (
      <p role="status" className="p-4 text-body-md text-text-muted">
        Cargando tu sesión…
      </p>
    )
  }

  if (error) {
    const detalle =
      error instanceof ApiError
        ? error.problema.detail
        : 'No pudimos cargar tu sesión. Intenta de nuevo.'

    return (
      <div
        role="alert"
        className="m-4 flex flex-col items-start gap-3 rounded-lg border border-error/40 bg-error/8 p-4 text-body-md"
      >
        <div className="flex items-start gap-2">
          <CircleAlert
            aria-hidden="true"
            className="mt-0.5 size-5 shrink-0 text-error-strong"
          />
          <p>{detalle}</p>
        </div>
        <Button
          variante="secundario"
          icono={RefreshCw}
          onClick={() => void refetch()}
        >
          Reintentar
        </Button>
      </div>
    )
  }

  if (!yo) {
    return (
      <p role="status" className="p-4 text-body-md text-text-muted">
        Cargando tu sesión…
      </p>
    )
  }

  return (
    <ContextoSesion.Provider value={{ yo }}>{children}</ContextoSesion.Provider>
  )
}
