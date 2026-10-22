export type VarianteBoton = 'primario' | 'secundario' | 'destructivo'

const clasesBase =
  'inline-flex min-h-11 items-center justify-center gap-2 rounded-md px-4 text-label-md transition-colors disabled:cursor-not-allowed disabled:opacity-50'

const clasesVariante: Record<VarianteBoton, string> = {
  primario:
    'bg-primary text-on-primary hover:bg-primary-hover active:bg-primary-active disabled:hover:bg-primary',
  secundario:
    'border border-border bg-surface text-text-main hover:bg-background disabled:hover:bg-surface',
  destructivo:
    'bg-error text-on-primary hover:bg-error-hover disabled:hover:bg-error',
}

/**
 * Clases de los botones de DESIGN.md (Components, 1). Se exportan aparte para
 * que los enlaces que se ven como botón (p. ej. «Volver al inicio») usen el mismo estilo.
 */
export function clasesBoton(variante: VarianteBoton = 'primario') {
  return `${clasesBase} ${clasesVariante[variante]}`
}
