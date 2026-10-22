import type { ReactNode } from 'react'
import { Ban } from 'lucide-react'

type Props = {
  /** Qué se bloqueó y por qué, p. ej. «No se puede programar: cancha ocupada». */
  causa: string
  /** El dato que choca, p. ej. el partido que ya ocupa la cancha. */
  conflicto: ReactNode
  /** Qué puede hacer el usuario para resolverlo. */
  accion: ReactNode
  /** Código del ERS que devuelve el backend (`VAL-004`, `RN-021`…). */
  codigo?: string
}

/**
 * Alerta en línea de bloqueo (F-36): explica la causa, el dato que choca y qué
 * hacer, como piden las validaciones del servicio (AGENTS.md §7, VAL-003 a VAL-005).
 */
export function AlertaBloqueo({ causa, conflicto, accion, codigo }: Props) {
  return (
    <div
      role="alert"
      className="flex gap-3 rounded-lg border border-error/40 bg-error/8 p-4 text-text-main"
    >
      <Ban aria-hidden="true" className="mt-0.5 size-5 shrink-0 text-error-strong" />
      <div className="flex min-w-0 flex-col gap-2">
        <p className="text-headline-sm text-error-strong">
          {causa}
          {codigo && <span className="ml-2 font-mono text-mono-data">({codigo})</span>}
        </p>
        <dl className="grid gap-1 text-body-md sm:grid-cols-[auto_1fr] sm:gap-x-3">
          <dt className="text-label-md">Conflicto:</dt>
          <dd>{conflicto}</dd>
          <dt className="text-label-md">Qué hacer:</dt>
          <dd>{accion}</dd>
        </dl>
      </div>
    </div>
  )
}
