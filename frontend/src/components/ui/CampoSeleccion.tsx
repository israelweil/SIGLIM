import type { ReactNode, SelectHTMLAttributes } from 'react'

type Props = Omit<SelectHTMLAttributes<HTMLSelectElement>, 'id' | 'className'> & {
  id: string
  etiqueta: string
  error?: string
  children: ReactNode
}

/** Lista de opciones con el mismo aspecto y etiqueta asociada de `CampoTexto` (RNF-008). */
export function CampoSeleccion({ id, etiqueta, error, required, children, ...resto }: Props) {
  const idError = error ? `${id}-error` : undefined

  return (
    <div className="flex min-w-0 flex-col gap-1.5">
      <label htmlFor={id} className="text-label-md text-text-main">
        {etiqueta}
        {required && (
          <span aria-hidden="true" className="ml-0.5 text-error">
            *
          </span>
        )}
      </label>
      <select
        id={id}
        required={required}
        aria-invalid={error ? true : undefined}
        aria-describedby={idError}
        className={[
          'min-h-11 w-full rounded-md border border-border bg-surface px-3 text-body-md text-text-main',
          error ? 'border-error' : '',
        ].join(' ')}
        {...resto}
      >
        {children}
      </select>
      {error && (
        <p id={idError} role="alert" className="text-body-sm text-error-strong">
          {error}
        </p>
      )}
    </div>
  )
}
