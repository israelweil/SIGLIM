import { useEffect, useState, type FormEvent } from 'react'
import { Link, useLocation, useNavigate, useSearchParams } from 'react-router'
import {
  ArrowLeft,
  CircleAlert,
  CircleCheck,
  Eye,
  EyeOff,
  LogIn,
  Mail,
} from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { CampoTexto } from '@/components/ui/CampoTexto'
import {
  correoValido,
  destinoSeguro,
  mensajeDeErrorDeAcceso,
  mensajeDeErrorDeRecuperacion,
} from '@/features/seguridad/autenticacion'
import { MarcoAutenticacion } from '@/features/seguridad/MarcoAutenticacion'
import { supabase } from '@/lib/supabase'

type Modo = 'acceso' | 'recuperacion'

type EstadoUbicacion = {
  desde?: unknown
  restablecida?: boolean
} | null

/**
 * Inicio de sesión con Supabase Auth (F-05, UI-001). Solo correo y contraseña:
 * sin folio, sin 2FA, sin «mantener sesión activa» y sin registro libre
 * (Q-UI-01, Q-UI-02, DEC-48). El backend vuelve a validar el token y los
 * permisos en cada petición (ADR-0003, VAL-015).
 */
export function InicioSesion() {
  const navegar = useNavigate()
  const ubicacion = useLocation()
  const [parametros] = useSearchParams()
  const estadoUbicacion = (ubicacion.state ?? null) as EstadoUbicacion
  const destino = destinoSeguro(estadoUbicacion?.desde)

  const [modo, setModo] = useState<Modo>(
    parametros.get('recuperar') === '1' ? 'recuperacion' : 'acceso',
  )
  const [correo, setCorreo] = useState('')
  const [contrasena, setContrasena] = useState('')
  const [mostrarContrasena, setMostrarContrasena] = useState(false)
  const [comprobandoSesion, setComprobandoSesion] = useState(true)
  const [enviando, setEnviando] = useState(false)
  const [errorCorreo, setErrorCorreo] = useState<string | null>(null)
  const [errorContrasena, setErrorContrasena] = useState<string | null>(null)
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null)
  const [aviso, setAviso] = useState<string | null>(null)

  useEffect(() => {
    let vigente = true

    supabase.auth
      .getSession()
      .then(({ data }) => {
        if (!vigente) {
          return
        }

        if (data.session) {
          navegar(destino, { replace: true })
          return
        }

        setComprobandoSesion(false)
      })
      .catch(() => {
        if (vigente) {
          setComprobandoSesion(false)
        }
      })

    return () => {
      vigente = false
    }
  }, [destino, navegar])

  const cambiarModo = (nuevoModo: Modo) => {
    setModo(nuevoModo)
    setErrorCorreo(null)
    setErrorContrasena(null)
    setErrorGeneral(null)
    setAviso(null)
    setContrasena('')
    setMostrarContrasena(false)
  }

  const iniciarSesion = async (evento: FormEvent<HTMLFormElement>) => {
    evento.preventDefault()
    setErrorCorreo(null)
    setErrorContrasena(null)
    setErrorGeneral(null)
    setAviso(null)

    if (!correoValido(correo)) {
      setErrorCorreo('Escribe un correo electrónico válido.')
      return
    }

    if (!contrasena) {
      setErrorContrasena('Escribe tu contraseña.')
      return
    }

    setEnviando(true)

    try {
      const { error } = await supabase.auth.signInWithPassword({
        email: correo.trim(),
        password: contrasena,
      })

      if (error) {
        setErrorGeneral(mensajeDeErrorDeAcceso(error))
        return
      }

      navegar(destino, { replace: true })
    } catch {
      setErrorGeneral(
        'No se pudo conectar con el servicio. Revisa tu conexión e intenta de nuevo.',
      )
    } finally {
      setEnviando(false)
    }
  }

  const solicitarRecuperacion = async (evento: FormEvent<HTMLFormElement>) => {
    evento.preventDefault()
    setErrorCorreo(null)
    setErrorGeneral(null)
    setAviso(null)

    if (!correoValido(correo)) {
      setErrorCorreo('Escribe un correo electrónico válido.')
      return
    }

    setEnviando(true)

    try {
      const { error } = await supabase.auth.resetPasswordForEmail(correo.trim(), {
        // La URL debe estar en la lista de redirects permitidos de Supabase Auth.
        redirectTo: `${window.location.origin}/restablecer-contrasena`,
      })

      if (error) {
        setErrorGeneral(mensajeDeErrorDeRecuperacion(error))
        return
      }

      setAviso(
        'Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.',
      )
    } catch {
      setErrorGeneral(
        'No se pudo conectar con el servicio. Revisa tu conexión e intenta de nuevo.',
      )
    } finally {
      setEnviando(false)
    }
  }

  if (comprobandoSesion) {
    return (
      <MarcoAutenticacion>
        <p role="status" className="text-body-md text-text-muted">
          Comprobando sesión…
        </p>
      </MarcoAutenticacion>
    )
  }

  return (
    <MarcoAutenticacion>
      <div className="flex flex-col gap-5">
        <div className="flex flex-col gap-1">
          <p className="text-label-sm uppercase text-primary">Acceso interno</p>
          <h1 className="text-display-lg-mobile text-text-main sm:text-display-lg">
            {modo === 'acceso' ? 'Iniciar sesión' : 'Recuperar acceso'}
          </h1>
          <p className="text-body-md text-text-muted">
            {modo === 'acceso'
              ? 'Acceso restringido a usuarios autorizados de la Liga.'
              : 'Escribe el correo de tu cuenta y te enviaremos un enlace para restablecer la contraseña.'}
          </p>
        </div>

        {estadoUbicacion?.restablecida && modo === 'acceso' && (
          <div
            role="status"
            className="flex items-start gap-2 rounded-lg border border-success/40 bg-success/8 p-3 text-body-md"
          >
            <CircleCheck
              aria-hidden="true"
              className="mt-0.5 size-5 shrink-0 text-success-strong"
            />
            <p>Contraseña actualizada. Inicia sesión con tu nueva contraseña.</p>
          </div>
        )}

        {aviso && (
          <div
            role="status"
            className="flex items-start gap-2 rounded-lg border border-success/40 bg-success/8 p-3 text-body-md"
          >
            <CircleCheck
              aria-hidden="true"
              className="mt-0.5 size-5 shrink-0 text-success-strong"
            />
            <p>{aviso}</p>
          </div>
        )}

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
          onSubmit={modo === 'acceso' ? iniciarSesion : solicitarRecuperacion}
          noValidate
        >
          <CampoTexto
            id="correo"
            name="email"
            etiqueta="Correo electrónico"
            type="email"
            autoComplete="email"
            inputMode="email"
            required
            value={correo}
            error={errorCorreo ?? undefined}
            onChange={(evento) => {
              setCorreo(evento.target.value)
              if (errorCorreo) {
                setErrorCorreo(null)
              }
            }}
            placeholder="nombre@ligamorelia.org.mx"
          />

          {modo === 'acceso' && (
            <>
              <CampoTexto
                id="contrasena"
                name="password"
                etiqueta="Contraseña"
                type={mostrarContrasena ? 'text' : 'password'}
                autoComplete="current-password"
                required
                value={contrasena}
                error={errorContrasena ?? undefined}
                onChange={(evento) => {
                  setContrasena(evento.target.value)
                  if (errorContrasena) {
                    setErrorContrasena(null)
                  }
                }}
                accion={
                  <button
                    type="button"
                    aria-label={
                      mostrarContrasena ? 'Ocultar contraseña' : 'Mostrar contraseña'
                    }
                    aria-pressed={mostrarContrasena}
                    aria-controls="contrasena"
                    onClick={() => setMostrarContrasena((visible) => !visible)}
                    className="inline-flex size-9 items-center justify-center rounded-md text-text-muted transition-colors hover:bg-background hover:text-text-main"
                  >
                    {mostrarContrasena ? (
                      <EyeOff aria-hidden="true" className="size-4" />
                    ) : (
                      <Eye aria-hidden="true" className="size-4" />
                    )}
                  </button>
                }
              />

              <div className="flex justify-end">
                <button
                  type="button"
                  disabled={enviando}
                  onClick={() => cambiarModo('recuperacion')}
                  className="inline-flex min-h-11 items-center rounded-md text-label-md text-primary underline-offset-2 hover:underline disabled:cursor-not-allowed disabled:opacity-50"
                >
                  ¿Olvidaste tu contraseña?
                </button>
              </div>
            </>
          )}

          <Button
            type="submit"
            cargando={enviando}
            icono={modo === 'acceso' ? LogIn : Mail}
            className="w-full"
          >
            {modo === 'acceso' ? 'Iniciar sesión' : 'Enviar enlace'}
          </Button>

          {modo === 'recuperacion' && (
            <Button
              type="button"
              variante="secundario"
              disabled={enviando}
              onClick={() => cambiarModo('acceso')}
              className="w-full"
            >
              Volver al inicio de sesión
            </Button>
          )}
        </form>

        <div className="flex flex-col gap-2 border-t border-border pt-4 text-body-sm text-text-muted">
          <p>Las cuentas se crean por invitación de la Liga. No hay registro libre.</p>
          <p>
            ¿Eres tutor de un jugador menor o directiva de nuevo ingreso? Consulta con
            la Liga la guía de trámites y consentimientos.
          </p>
        </div>

        <div className="flex flex-col gap-2 border-t border-border pt-4 text-body-sm sm:flex-row sm:items-center sm:justify-between">
          <Link
            to="/"
            className="inline-flex min-h-11 items-center gap-1.5 rounded-md text-label-md text-primary hover:underline"
          >
            <ArrowLeft aria-hidden="true" className="size-4" />
            Volver al portal público
          </Link>
          <Link
            to="/aviso-de-privacidad"
            className="inline-flex min-h-11 items-center rounded-md text-label-md text-text-muted hover:text-text-main hover:underline"
          >
            Aviso de privacidad
          </Link>
        </div>
      </div>
    </MarcoAutenticacion>
  )
}
