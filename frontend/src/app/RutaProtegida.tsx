import { useEffect, useState } from 'react'
import { Navigate, Outlet, useLocation } from 'react-router'
import { supabase } from '@/lib/supabase'

type EstadoSesion = 'comprobando' | 'autenticada' | 'anonima'

/**
 * Protege las rutas de `/app` (AGENTS.md, rutas). La pantalla de inicio de sesión
 * se construye en H-01.2; el backend vuelve a validar el token en cada petición.
 */
export function RutaProtegida() {
  const [estado, setEstado] = useState<EstadoSesion>('comprobando')
  const ubicacion = useLocation()

  useEffect(() => {
    let vigente = true

    supabase.auth
      .getSession()
      .then(({ data }) => {
        if (vigente) {
          setEstado(data.session ? 'autenticada' : 'anonima')
        }
      })
      .catch(() => {
        if (vigente) {
          setEstado('anonima')
        }
      })

    return () => {
      vigente = false
    }
  }, [])

  if (estado === 'comprobando') {
    return (
      <p role="status" className="p-4 text-body-md text-text-muted">
        Comprobando sesión…
      </p>
    )
  }

  if (estado === 'anonima') {
    return <Navigate to="/login" replace state={{ desde: ubicacion.pathname }} />
  }

  return <Outlet />
}
