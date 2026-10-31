import { useId, useState, type FormEvent } from 'react'
import { Button } from '@/components/ui/Button'
import { CampoTexto } from '@/components/ui/CampoTexto'
import { useActualizarCancha, useCrearCancha } from '@/features/canchas/api'
import { CampoSeleccion } from '@/components/ui/CampoSeleccion'
import { etiquetaPropietario, etiquetaUbicacion } from '@/features/canchas/etiquetas'
import type {
  ActualizarCanchaPeticion,
  Cancha,
  CrearCanchaPeticion,
  PropietarioCancha,
  UbicacionCancha,
} from '@/features/canchas/tipos'
import { useDialogoModal } from '@/components/ui/useDialogoModal'
import { ApiError } from '@/lib/api/ApiError'

type Props = {
  /** Cancha a editar; sin ella, el formulario crea una nueva. */
  cancha?: Cancha
  onCerrar: () => void
  onGuardada: (cancha: Cancha) => void
}

type Valores = {
  nombre: string
  ubicacion: UbicacionCancha | ''
  direccion: string
  propietario: PropietarioCancha | ''
  propietarioExterno: string
  caracteristicas: string
}

const CAMPOS_FORMULARIO = new Set<string>([
  'nombre',
  'ubicacion',
  'direccion',
  'propietario',
  'propietarioExterno',
  'caracteristicas',
])

function valoresDe(cancha?: Cancha): Valores {
  return {
    nombre: cancha?.nombre ?? '',
    ubicacion: cancha?.ubicacion ?? '',
    direccion: cancha?.direccion ?? '',
    propietario: cancha?.propietario ?? '',
    propietarioExterno: cancha?.propietarioExterno ?? '',
    caracteristicas: cancha?.caracteristicas ?? '',
  }
}

/** Solo lo que cambió (RF-027): un campo ausente conserva su valor y uno en blanco se vacía. */
function cambiosDe(cancha: Cancha, valores: Valores): ActualizarCanchaPeticion {
  const cambios: ActualizarCanchaPeticion = {}
  const nombre = valores.nombre.trim()
  const direccion = valores.direccion.trim()
  const caracteristicas = valores.caracteristicas.trim()
  const externo = valores.propietarioExterno.trim()
  const propietario = valores.propietario as PropietarioCancha

  if (nombre !== cancha.nombre) {
    cambios.nombre = nombre
  }
  if (valores.ubicacion !== cancha.ubicacion) {
    cambios.ubicacion = valores.ubicacion as UbicacionCancha
  }
  if (direccion !== (cancha.direccion ?? '')) {
    cambios.direccion = direccion
  }
  if (caracteristicas !== (cancha.caracteristicas ?? '')) {
    cambios.caracteristicas = caracteristicas
  }
  if (propietario !== cancha.propietario) {
    // El backend toma club y propietario externo de la petición cuando cambia el propietario.
    cambios.propietario = propietario
    if (propietario === 'EXTERNO') {
      cambios.propietarioExterno = externo
    }
  } else if (propietario === 'EXTERNO' && externo !== (cancha.propietarioExterno ?? '')) {
    cambios.propietarioExterno = externo
  }

  return cambios
}

/**
 * Crea y edita una cancha (RF-027). Mientras no exista el catálogo de clubes, una cancha de
 * club no se puede registrar aquí; al editarla se muestra su club sin ofrecer cambiarlo por otro.
 */
export function FormularioCancha({ cancha, onCerrar, onGuardada }: Props) {
  const dialogoRef = useDialogoModal()
  const crear = useCrearCancha()
  const actualizar = useActualizarCancha(cancha?.id ?? '')
  const [valores, setValores] = useState(() => valoresDe(cancha))
  const [errores, setErrores] = useState<Record<string, string>>({})
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null)
  const id = useId()
  const idTitulo = `${id}-titulo`
  const idCaracteristicas = `${id}-caracteristicas`
  const idAyudaCaracteristicas = `${id}-caracteristicas-ayuda`
  const guardando = crear.isPending || actualizar.isPending
  const ayudaOpcional = cancha ? 'Déjalo vacío para borrarlo.' : undefined

  const cambiar = (campo: keyof Valores, valor: string) => {
    setValores((actuales) => ({ ...actuales, [campo]: valor }))
    setErrores(({ [campo]: _quitado, ...resto }) => resto)
  }

  const alFallar = (error: unknown) => {
    if (!(error instanceof ApiError)) {
      return
    }

    const deCampos = Object.fromEntries(
      (error.problema.errores ?? [])
        .filter(({ campo }) => CAMPOS_FORMULARIO.has(campo))
        .map(({ campo, mensaje }) => [campo, mensaje]),
    )

    if (error.problema.codigo === 'DUPLICADO') {
      setErrores({ nombre: error.problema.detail })
      setErrorGeneral(null)
      return
    }

    setErrores(deCampos)
    setErrorGeneral(error.problema.detail)
  }

  const validar = (): Record<string, string> => {
    const encontrados: Record<string, string> = {}

    if (!valores.nombre.trim()) {
      encontrados.nombre = 'Escribe el nombre de la cancha.'
    }
    if (!valores.ubicacion) {
      encontrados.ubicacion = 'Elige la ubicación.'
    }
    if (!valores.propietario) {
      encontrados.propietario = 'Elige el propietario.'
    }
    if (valores.propietario === 'EXTERNO' && !valores.propietarioExterno.trim()) {
      encontrados.propietarioExterno = 'Escribe quién es el propietario externo.'
    }

    return encontrados
  }

  const alEnviar = (evento: FormEvent<HTMLFormElement>) => {
    evento.preventDefault()
    setErrorGeneral(null)

    const encontrados = validar()
    setErrores(encontrados)

    if (Object.keys(encontrados).length > 0) {
      return
    }

    if (cancha) {
      const cambios = cambiosDe(cancha, valores)

      if (Object.keys(cambios).length === 0) {
        onCerrar()
        return
      }

      actualizar.mutate(cambios, { onSuccess: onGuardada, onError: alFallar })
      return
    }

    const direccion = valores.direccion.trim()
    const caracteristicas = valores.caracteristicas.trim()
    const peticion: CrearCanchaPeticion = {
      nombre: valores.nombre.trim(),
      ubicacion: valores.ubicacion as UbicacionCancha,
      propietario: valores.propietario as PropietarioCancha,
      ...(direccion ? { direccion } : {}),
      ...(caracteristicas ? { caracteristicas } : {}),
      ...(valores.propietario === 'EXTERNO'
        ? { propietarioExterno: valores.propietarioExterno.trim() }
        : {}),
    }

    crear.mutate(peticion, { onSuccess: onGuardada, onError: alFallar })
  }

  return (
    <dialog
      ref={dialogoRef}
      aria-labelledby={idTitulo}
      onCancel={(evento) => {
        evento.preventDefault()
        if (!guardando) {
          onCerrar()
        }
      }}
      className="m-auto max-h-[calc(100dvh-2rem)] w-[calc(100%-2rem)] max-w-lg overflow-y-auto rounded-lg border border-border bg-surface p-0 text-text-main shadow-overlay backdrop:bg-surface-dark/50"
    >
      <form onSubmit={alEnviar} noValidate className="flex flex-col gap-4 p-6">
        <h2 id={idTitulo} className="text-balance text-headline-md">
          {cancha ? `Editar — ${cancha.nombre}` : 'Nueva cancha'}
        </h2>

        <CampoTexto
          id={`${id}-nombre`}
          etiqueta="Nombre"
          required
          maxLength={120}
          error={errores.nombre}
          value={valores.nombre}
          onChange={(evento) => cambiar('nombre', evento.target.value)}
        />
        <CampoSeleccion
          id={`${id}-ubicacion`}
          etiqueta="Ubicación"
          required
          error={errores.ubicacion}
          value={valores.ubicacion}
          onChange={(evento) => cambiar('ubicacion', evento.target.value)}
        >
          {!cancha && <option value="">Selecciona…</option>}
          <option value="UNIDAD_DEPORTIVA">{etiquetaUbicacion.UNIDAD_DEPORTIVA}</option>
          <option value="EXTERNA">{etiquetaUbicacion.EXTERNA}</option>
        </CampoSeleccion>
        <CampoTexto
          id={`${id}-direccion`}
          etiqueta="Dirección"
          ayuda={ayudaOpcional}
          error={errores.direccion}
          value={valores.direccion}
          onChange={(evento) => cambiar('direccion', evento.target.value)}
        />
        <CampoSeleccion
          id={`${id}-propietario`}
          etiqueta="Propietario"
          required
          error={errores.propietario}
          value={valores.propietario}
          onChange={(evento) => cambiar('propietario', evento.target.value)}
        >
          {!cancha && <option value="">Selecciona…</option>}
          <option value="LIGA">{etiquetaPropietario.LIGA}</option>
          {cancha?.propietario === 'CLUB' && (
            <option value="CLUB">
              {etiquetaPropietario.CLUB}: {cancha.club?.nombre}
            </option>
          )}
          <option value="EXTERNO">{etiquetaPropietario.EXTERNO}</option>
        </CampoSeleccion>
        {!cancha && (
          <p className="text-body-sm text-text-muted">
            Las canchas de club se registran cuando esté disponible el catálogo de clubes.
          </p>
        )}
        {valores.propietario === 'EXTERNO' && (
          <CampoTexto
            id={`${id}-externo`}
            etiqueta="Propietario externo"
            required
            maxLength={150}
            error={errores.propietarioExterno}
            value={valores.propietarioExterno}
            onChange={(evento) => cambiar('propietarioExterno', evento.target.value)}
          />
        )}
        <div className="flex flex-col gap-1.5">
          <label htmlFor={idCaracteristicas} className="text-label-md">
            Características
          </label>
          <textarea
            id={idCaracteristicas}
            rows={3}
            aria-describedby={ayudaOpcional ? idAyudaCaracteristicas : undefined}
            value={valores.caracteristicas}
            onChange={(evento) => cambiar('caracteristicas', evento.target.value)}
            className="min-h-11 rounded-md border border-border bg-surface px-3 py-2 text-body-md"
          />
          {ayudaOpcional && (
            <p id={idAyudaCaracteristicas} className="text-body-sm text-text-muted">
              {ayudaOpcional}
            </p>
          )}
        </div>

        {errorGeneral && (
          <p role="alert" className="rounded-md bg-error/8 p-3 text-body-md text-error-strong">
            {errorGeneral}
          </p>
        )}

        <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
          <Button variante="secundario" onClick={onCerrar} disabled={guardando}>
            Cancelar
          </Button>
          <Button type="submit" cargando={guardando}>
            Guardar
          </Button>
        </div>
      </form>
    </dialog>
  )
}
