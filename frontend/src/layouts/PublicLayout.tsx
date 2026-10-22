import { useEffect, useState } from 'react'
import { Link, NavLink, Outlet, useLocation } from 'react-router'
import { LogIn, Menu, X } from 'lucide-react'
import { enlacesPortal } from '@/layouts/navegacion'

const clasesEnlace = ({ isActive }: { isActive: boolean }) =>
  [
    'block rounded-md px-3 py-2 text-label-md transition-colors',
    isActive
      ? 'bg-primary text-on-primary'
      : 'text-text-main hover:bg-background',
  ].join(' ')

const clasesSalto =
  'sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[60] focus:rounded-md focus:bg-primary focus:px-4 focus:py-2 focus:text-label-md focus:text-on-primary'

/** Encabezado y pie del portal público (F-01). */
export function PublicLayout() {
  const [menuAbierto, setMenuAbierto] = useState(false)
  const { pathname } = useLocation()

  useEffect(() => {
    setMenuAbierto(false)
  }, [pathname])

  useEffect(() => {
    if (!menuAbierto) {
      return
    }

    const alPresionar = (evento: KeyboardEvent) => {
      if (evento.key === 'Escape') {
        setMenuAbierto(false)
      }
    }

    window.addEventListener('keydown', alPresionar)

    return () => window.removeEventListener('keydown', alPresionar)
  }, [menuAbierto])

  return (
    <div className="flex min-h-dvh flex-col bg-background">
      <a href="#contenido-publico" className={clasesSalto}>
        Saltar al contenido
      </a>

      <header className="fixed inset-x-0 top-0 z-50 border-b border-border bg-surface">
        <div className="mx-auto flex h-16 max-w-7xl items-center gap-2 px-4 sm:px-6 lg:px-8">
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

          <nav
            aria-label="Navegación del portal"
            className="ml-auto hidden items-center gap-1 lg:flex"
          >
            {enlacesPortal.map((enlace) => (
              <NavLink
                key={enlace.ruta}
                to={enlace.ruta}
                end={enlace.ruta === '/'}
                className={clasesEnlace}
              >
                {enlace.nombre}
              </NavLink>
            ))}
          </nav>

          <div className="ml-auto flex items-center gap-2 lg:ml-3">
            <Link
              to="/login"
              className="inline-flex min-h-11 items-center gap-2 rounded-md bg-primary px-3 text-label-md text-on-primary transition-colors hover:bg-primary-hover active:bg-primary-active"
            >
              <LogIn aria-hidden="true" className="size-4" />
              Iniciar sesión
            </Link>
            <button
              type="button"
              aria-label={menuAbierto ? 'Cerrar menú' : 'Abrir menú'}
              aria-expanded={menuAbierto}
              aria-controls="menu-portal"
              onClick={() => setMenuAbierto((abierto) => !abierto)}
              className="inline-flex size-11 items-center justify-center rounded-md border border-border text-text-main transition-colors hover:bg-background lg:hidden"
            >
              {menuAbierto ? (
                <X aria-hidden="true" className="size-5" />
              ) : (
                <Menu aria-hidden="true" className="size-5" />
              )}
            </button>
          </div>
        </div>

        <nav
          id="menu-portal"
          aria-label="Navegación del portal"
          className="border-t border-border px-4 py-3 sm:px-6 lg:hidden"
          hidden={!menuAbierto}
        >
          <ul className="flex flex-col gap-1">
            {enlacesPortal.map((enlace) => (
              <li key={enlace.ruta}>
                <NavLink
                  to={enlace.ruta}
                  end={enlace.ruta === '/'}
                  className={clasesEnlace}
                >
                  {enlace.nombre}
                </NavLink>
              </li>
            ))}
          </ul>
        </nav>
      </header>

      <main id="contenido-publico" className="flex-1 pt-16">
        <Outlet />
      </main>

      <footer className="border-t border-border bg-surface">
        <div className="mx-auto flex max-w-7xl flex-col gap-2 px-4 py-6 text-body-sm text-text-muted sm:flex-row sm:items-center sm:justify-between sm:px-6 lg:px-8">
          <p>Liga Municipal de Futbol Amateur Morelia</p>
          <Link
            to="/aviso-de-privacidad"
            className="underline underline-offset-2 hover:text-text-main"
          >
            Aviso de privacidad
          </Link>
        </div>
      </footer>
    </div>
  )
}
