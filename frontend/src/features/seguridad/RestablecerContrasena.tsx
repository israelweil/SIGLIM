import { useEffect, useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router'
import { CircleAlert, KeyRound } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { CampoTexto } from '@/components/ui/CampoTexto'
import {
  LONGITUD_MAXIMA_CONTRASENA,
  LONGITUD_MINIMA_CONTRASENA,
  mensajeDeErrorDeContrasena,
} from '@/features/seguridad/autenticacion'
import { MarcoAutenticacion } from '@/features/seguridad/MarcoAutenticacion'
import { supabase } from '@/lib/supabase'

type Estado = 'comprobando' | 'lista' | 'sin-sesion'

/**
 * Restablecimiento de contraseña con el enlace que envía Supabase Auth
 * (ADR-0003, recuperación de acceso). Supabase detecta la sesión de recuperación
 * en la URL y aquí solo se pide la contraseña nueva; SIGLIM nunca la almacena
 * (RNF-013).
 */
export function RestablecerContrasena() {
  const navegar = useNavigate()
  const [estado, setEstado] = useState<Estado>('comprobando')
  const [contrasena, setContrasena] = useState('')
  const [confirmacion, setConfirmacion] = useState('')
  const [enviando, setEnviando] = useState(false)
  const [errorContrasena, setErrorContrasena] = useState<string | null>(null)
  const [errorConfirmacion, setErrorConfirmacion] = useState<string | null>(null)
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null)

  useEffect(() => {
    let vigente = true

    const { data } = supabase.auth.onAuthStateChange((evento, sesion) => {
      if (
        vigente &&
        sesion &&
        (evento === 'PASSWORD_RECOVERY' || evento === 'SIGNED_IN')
      ) {
        setEstado('lista')
      }
    })

    supabase.auth
      .getSession()
      .then(({ data: datos }) => {
        if (!vigente) {
          return
        }

        setEstado(datos.session ? 'lista' : 'sin-sesion')
      })
      .catch(() => {
        if (vigente) {
          setEstado('sin-sesion')
        }
      })

    return () => {
      vigente = false
      data.subscription.unsubscribe()
    }
  }, [])

  const actualizarContrasena = async (evento: FormEvent<HTMLFormElement>) => {
    evento.preventDefault()
    setErrorContrasena(null)
    setErrorConfirmacion(null)
    setErrorGeneral(null)

    if (contrasena.length < LONGITUD_MINIMA_CONTRASENA) {
      setErrorContrasena(
        `La contraseña debe tener al menos ${LONGITUD_MINIMA_CONTRASENA} caracteres.`,
      )
      return
    }

    if (contrasena.length > LONGITUD_MAXIMA_CONTRASENA) {
      setErrorContrasena(
        `La contraseña no puede tener más de ${LONGITUD_MAXIMA_CONTRASENA} caracteres.`,
      )
      return
    }

    if (contrasena !== confirmacion) {
      setErrorConfirmacion('Las contraseñas no coinciden.')
      return
    }

    setEnviando(true)

    try {
      const { error } = await supabase.auth.updateUser({ password: contrasena })

      if (error) {
        setErrorGeneral(mensajeDeErrorDeContrasena(error))
        return
      }

      try {
        await supabase.auth.signOut()
      } catch {
        // La contraseña ya se actualizó; si falla el cierre, se continúa al acceso.
      }
      navegar('/login', { replace: true, state: { restablecida: true } })
    } catch {
      setErrorGeneral(
        'No se pudo conectar con el servicio. Revisa tu conexión e intenta de nuevo.',
      )
    } finally {
      setEnviando(false)
    }
  }

  return (
    <MarcoAutenticacion>
      <div className="flex flex-col gap-5">
        <div className="flex flex-col gap-1">
          <p className="text-label-sm uppercase text-primary">Acceso interno</p>
          <h1 className="text-display-lg-mobile text-text-main sm:text-display-lg">
            Restablecer contraseña
          </h1>
          <p className="text-body-md text-text-muted">
            Elige una contraseña nueva para tu cuenta. La contraseña se guarda en
            Supabase Auth; SIGLIM no la almacena.
          </p>
        </div>

        {estado === 'comprobando' && (
          <p role="status" className="text-body-md text-text-muted">
            Comprobando enlace…
          </p>
        )}

        {estado === 'sin-sesion' && (
          <div
            role="alert"
            className="flex items-start gap-2 rounded-lg border border-error/40 bg-error/8 p-3 text-body-md"
          >
            <CircleAlert
              aria-hidden="true"
              className="mt-0.5 size-5 shrink-0 text-error-strong"
            />
            <div className="flex flex-col gap-2">
              <p>El enlace no es válido o ya venció.</p>
              <Link
                to="/login?recuperar=1"
                className="inline-flex min-h-11 w-fit items-center rounded-md text-label-md text-primary underline-offset-2 hover:underline"
              >
                Solicitar un enlace nuevo
              </Link>
            </div>
          </div>
        )}

        {estado === 'lista' && (
          <>
            {errorGeneral && (
              <div
                role="alert"
                className="flex items-start gap-2 rounded-lg border border-error/40 bg-error/8 p-3 text-body-md"
              >
                <CircleAlert
                  aria-hidden="true"
                  className="mt-0.5 size-5 shrink-0 text-error-strong"
                />
                <p>{errorGeneral}</p>
              </div>
            )}

            <form
              className="flex flex-col gap-4"
              onSubmit={actualizarContrasena}
              noValidate
            >
              <CampoTexto
                id="nueva-contrasena"
                name="new-password"
                etiqueta="Nueva contraseña"
                type="password"
                autoComplete="new-password"
                required
                value={contrasena}
                error={errorContrasena ?? undefined}
                ayuda={`Entre ${LONGITUD_MINIMA_CONTRASENA} y ${LONGITUD_MAXIMA_CONTRASENA} caracteres; se aceptan frases.`}
                onChange={(evento) => {
                  setContrasena(evento.target.value)
                  if (errorContrasena) {
                    setErrorContrasena(null)
                  }
                }}
              />

              <CampoTexto
                id="confirmar-contrasena"
                name="confirm-password"
                etiqueta="Confirmar contraseña"
                type="password"
                autoComplete="new-password"
                required
                value={confirmacion}
                error={errorConfirmacion ?? undefined}
                onChange={(evento) => {
                  setConfirmacion(evento.target.value)
                  if (errorConfirmacion) {
                    setErrorConfirmacion(null)
                  }
                }}
              />

              <Button
                type="submit"
                cargando={enviando}
                icono={KeyRound}
                className="w-full"
              >
                Guardar contraseña
              </Button>
            </form>

            <Link
              to="/login"
              className="inline-flex min-h-11 w-fit items-center rounded-md text-label-md text-primary underline-offset-2 hover:underline"
            >
              Volver al inicio de sesión
            </Link>
          </>
        )}
      </div>
    </MarcoAutenticacion>
  )
}
