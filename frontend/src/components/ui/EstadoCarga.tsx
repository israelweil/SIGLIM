type Props = {
  /** Texto que oyen los lectores de pantalla mientras carga. */
  etiqueta?: string
  filas?: number
  columnas?: number
}

/** Esqueleto de carga de una tabla (F-36); se anuncia como estado para lectores de pantalla. */
export function EstadoCarga({ etiqueta = 'Cargando…', filas = 5, columnas = 4 }: Props) {
  const celdas = Array.from({ length: columnas }, (_, indice) => indice)

  return (
    <div
      role="status"
      className="overflow-hidden rounded-lg border border-border bg-surface"
    >
      <span className="sr-only">{etiqueta}</span>
      <div aria-hidden="true" className="animate-pulse motion-reduce:animate-none">
        <div className="flex gap-4 border-b-2 border-border bg-background px-4 py-3">
          {celdas.map((celda) => (
            <div key={celda} className="h-3 flex-1 rounded-sm bg-border" />
          ))}
        </div>
        {Array.from({ length: filas }, (_, fila) => (
          <div key={fila} className="flex h-12 items-center gap-4 border-b border-border px-4 last:border-b-0">
            {celdas.map((celda) => (
              <div key={celda} className="h-3 flex-1 rounded-sm bg-border/60" />
            ))}
          </div>
        ))}
      </div>
    </div>
  )
}
