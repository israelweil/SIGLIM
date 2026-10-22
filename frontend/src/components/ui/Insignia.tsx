import type { ReactNode } from 'react'
import {
  CircleAlert,
  CircleCheck,
  CircleDot,
  Clock,
  Info,
  type LucideIcon,
} from 'lucide-react'

export type VarianteInsignia =
  | 'exito'
  | 'error'
  | 'advertencia'
  | 'informacion'
  | 'neutra'

const estilos: Record<VarianteInsignia, { clases: string; icono: LucideIcon }> = {
  exito: { clases: 'bg-success/12 text-success-strong', icono: CircleCheck },
  error: { clases: 'bg-error/12 text-error-strong', icono: CircleAlert },
  advertencia: { clases: 'bg-warning/14 text-warning-strong', icono: Clock },
  informacion: { clases: 'bg-info/12 text-info-strong', icono: Info },
  neutra: { clases: 'bg-border text-text-main', icono: CircleDot },
}

type Props = {
  variante: VarianteInsignia
  children: ReactNode
  /** Sustituye el ícono por defecto de la variante (p. ej. calendario para «Programado»). */
  icono?: LucideIcon
}

/**
 * Insignia de estado de DESIGN.md (Components, 2): ícono de 14 px más texto en
 * mayúsculas, para no depender solo del color (RNF-008). Cada módulo decide qué
 * variante corresponde a cada estado de la BD.
 */
export function Insignia({ variante, children, icono }: Props) {
  const { clases, icono: iconoPorDefecto } = estilos[variante]
  const Icono = icono ?? iconoPorDefecto

  return (
    <span
      className={`inline-flex h-6 shrink-0 items-center gap-1 rounded-[6px] px-2 text-label-sm uppercase whitespace-nowrap ${clases}`}
    >
      <Icono aria-hidden="true" className="size-3.5 shrink-0" />
      {children}
    </span>
  )
}
