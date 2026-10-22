import { Link } from 'react-router'
import { House, SearchX } from 'lucide-react'
import { clasesBoton } from '@/components/ui/estilosBoton'

/**
 * Página 404 (F-36). No distingue «no existe» de «no tienes acceso» para no
 * revelar si el recurso existe (VAL-024).
 */
export function PaginaNoEncontrada() {
  return (
    <section className="mx-auto flex max-w-xl flex-col items-center gap-4 px-4 py-16 text-center">
      <SearchX aria-hidden="true" className="size-12 text-text-muted" />
      <p className="font-mono text-mono-data text-text-muted">Error 404</p>
      <h1 className="text-display-lg-mobile text-text-main sm:text-display-lg">
        No encontramos lo que buscas
      </h1>
      <p className="text-body-lg text-text-muted">
        Puede que no exista o que no tengas acceso.
      </p>
      <Link to="/" className={`${clasesBoton('primario')} mt-2`}>
        <House aria-hidden="true" className="size-4 shrink-0" />
        Volver al inicio
      </Link>
    </section>
  )
}
