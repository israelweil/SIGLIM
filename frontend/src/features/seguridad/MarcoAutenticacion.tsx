import type { ReactNode } from 'react'
import { Link } from 'react-router'
import { ArrowLeft, ShieldCheck } from 'lucide-react'
import imagenAcceso from '@/assets/inicio-sesion.jpg'

type Props = {
  children: ReactNode
}

const clasesSalto =
  'sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[60] focus:rounded-md focus:bg-primary focus:px-4 focus:py-2 focus:text-label-md focus:text-on-primary'

/**
 * Marco visual de las pantallas de acceso (F-05): encabezado mínimo, panel
 * institucional con la fotografía aprobada por el equipo (Q-UI-04) y tarjeta
 * del formulario. No incluye datos inventados del prototipo (D-11).
 */
export function MarcoAutenticacion({ children }: Props) {
  return (
    <div className="flex min-h-dvh flex-col bg-background">
      <a href="#contenido-acceso" className={clasesSalto}>
        Saltar al contenido
      </a>

      <header className="border-b border-border bg-surface">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between gap-4 px-4 sm:px-6 lg:px-8">
          <Link
            to="/"
            className="flex min-h-11 items-center gap-2 rounded-md"
            aria-label="SIGLIM, portal público"
          >
            <span
              aria-hidden="true"
              className="grid size-9 place-items-center rounded-md bg-primary text-headline-sm text-on-primary"
            >
              S
            </span>
            <span className="flex flex-col leading-tight">
              <span className="text-headline-sm text-text-main">SIGLIM</span>
              <span className="hidden text-body-sm text-text-muted sm:block">
                Liga Municipal de Futbol Amateur Morelia
              </span>
            </span>
          </Link>

          <Link
            to="/"
            className="inline-flex min-h-11 items-center gap-2 rounded-md px-3 text-label-md text-primary transition-colors hover:bg-background"
          >
            <ArrowLeft aria-hidden="true" className="size-4" />
            Portal público
          </Link>
        </div>
      </header>

      <main
        id="contenido-acceso"
        className="flex flex-1 items-center justify-center px-4 py-8 sm:px-6 lg:px-8"
      >
        <div className="grid w-full max-w-6xl overflow-hidden rounded-lg border border-border bg-surface lg:grid-cols-12">
          <aside className="hidden flex-col justify-between gap-8 bg-surface-dark p-8 text-on-surface-dark lg:col-span-5 lg:flex">
            <div className="flex flex-col gap-6">
              <span className="inline-flex w-fit items-center gap-2 rounded-full border border-on-surface-dark/20 bg-on-surface-dark/10 px-3 py-1 text-label-sm uppercase">
                <ShieldCheck aria-hidden="true" className="size-4" />
                Acceso interno
              </span>

              <div className="overflow-hidden rounded-lg border border-on-surface-dark/20">
                <img
                  src={imagenAcceso}
                  alt="Cancha de futbol amateur durante un partido nocturno"
                  className="h-52 w-full object-cover"
                />
              </div>

              <div className="flex flex-col gap-2">
                <p className="text-headline-lg">SIGLIM</p>
                <p className="text-body-md text-on-surface-dark/80">
                  Afiliación, registro de jugadores, programación, cédula,
                  disciplina y tesorería con trazabilidad de cada cambio.
                </p>
              </div>
            </div>

            <p className="border-t border-on-surface-dark/20 pt-4 text-body-sm text-on-surface-dark/80">
              Liga Municipal de Futbol Amateur Morelia
            </p>
          </aside>

          <section className="p-6 sm:p-9 lg:col-span-7 lg:p-10">
            {children}
          </section>
        </div>
      </main>

      <footer className="border-t border-border bg-surface">
        <div className="mx-auto flex max-w-7xl flex-col gap-2 px-4 py-6 text-body-sm text-text-muted sm:flex-row sm:items-center sm:justify-between sm:px-6 lg:px-8">
          <p>Liga Municipal de Futbol Amateur Morelia</p>
          <Link
            to="/aviso-de-privacidad"
            className="inline-flex min-h-11 items-center underline underline-offset-2 hover:text-text-main"
          >
            Aviso de privacidad
          </Link>
        </div>
      </footer>
    </div>
  )
}
