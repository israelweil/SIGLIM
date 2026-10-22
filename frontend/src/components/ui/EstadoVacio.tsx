import type { ReactNode } from 'react'
import { Inbox, type LucideIcon } from 'lucide-react'

type Props = {
  titulo: string
  descripcion?: string
  icono?: LucideIcon
  /** Acción sugerida, p. ej. un `Button` para registrar el primer elemento. */
  accion?: ReactNode
}

/** Estado vacío de una tabla o lista (F-36). */
export function EstadoVacio({ titulo, descripcion, icono: Icono = Inbox, accion }: Props) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-lg border border-border bg-surface px-4 py-10 text-center">
      <Icono aria-hidden="true" className="size-10 text-text-muted" />
      <p className="text-headline-sm text-text-main">{titulo}</p>
      {descripcion && (
        <p className="max-w-md text-body-md text-text-muted">{descripcion}</p>
      )}
      {accion && <div className="mt-2">{accion}</div>}
    </div>
  )
}
