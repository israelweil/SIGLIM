import type { ButtonHTMLAttributes } from 'react'
import { LoaderCircle, type LucideIcon } from 'lucide-react'
import { clasesBoton, type VarianteBoton } from '@/components/ui/estilosBoton'

type Props = ButtonHTMLAttributes<HTMLButtonElement> & {
  variante?: VarianteBoton
  /** Ícono decorativo a la izquierda del texto. */
  icono?: LucideIcon
  /** Deshabilita el botón y muestra un indicador mientras termina la acción. */
  cargando?: boolean
}

/** Botón primario, secundario o destructivo de DESIGN.md con altura mínima de 44 px (RNF-008). */
export function Button({
  variante = 'primario',
  icono: Icono,
  cargando = false,
  disabled,
  type = 'button',
  className,
  children,
  ...resto
}: Props) {
  return (
    <button
      type={type}
      disabled={disabled || cargando}
      aria-busy={cargando || undefined}
      className={[clasesBoton(variante), className].filter(Boolean).join(' ')}
      {...resto}
    >
      {cargando ? (
        <LoaderCircle
          aria-hidden="true"
          className="size-4 shrink-0 animate-spin motion-reduce:animate-none"
        />
      ) : (
        Icono && <Icono aria-hidden="true" className="size-4 shrink-0" />
      )}
      {children}
    </button>
  )
}
