import type { InputHTMLAttributes, ReactNode } from 'react'

type Props = Omit<InputHTMLAttributes<HTMLInputElement>, 'id' | 'className'> & {
  id: string
  etiqueta: string
  /** Texto de apoyo bajo el campo; se oculta si hay un error. */
  ayuda?: string
  /** Error del campo; lo marca como inválido y lo enlaza con aria-describedby. */
  error?: string
  /** Acción dentro del campo, p. ej. el botón para mostrar u ocultar la contraseña. */
  accion?: ReactNode
}

/**
 * Campo de texto del sistema de diseño (DESIGN.md, Formularios): etiqueta
 * asociada, altura mínima de 44 px, foco visible y mensajes enlazados con
 * `aria-describedby` (RNF-008).
 */
export function CampoTexto({
  id,
  etiqueta,
  ayuda,
  error,
  accion,
  required,
  ...resto
}: Props) {
  const idAyuda = ayuda && !error ? `${id}-ayuda` : undefined
  const idError = error ? `${id}-error` : undefined
  const descrito = [idAyuda, idError].filter(Boolean).join(' ') || undefined

  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={id} className="text-label-md text-text-main">
        {etiqueta}
        {required && (
          <span aria-hidden="true" className="ml-0.5 text-error">
            *
          </span>
        )}
      </label>

      <div className="relative flex items-center">
        <input
          id={id}
          required={required}
          aria-invalid={error ? true : undefined}
          aria-describedby={descrito}
          className={[
            'min-h-11 w-full rounded-md border border-border bg-surface px-3 text-body-md text-text-main placeholder:text-text-muted/70',
            accion ? 'pr-12' : '',
            error ? 'border-error' : '',
          ]
            .filter(Boolean)
            .join(' ')}
          {...resto}
        />
        {accion && (
          <span className="absolute right-1.5 flex items-center">{accion}</span>
        )}
      </div>

      {error ? (
        <p id={idError} role="alert" className="text-body-sm text-error-strong">
          {error}
        </p>
      ) : (
        ayuda && (
          <p id={idAyuda} className="text-body-sm text-text-muted">
            {ayuda}
          </p>
        )
      )}
    </div>
  )
}
