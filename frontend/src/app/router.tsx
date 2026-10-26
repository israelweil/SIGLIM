import { createBrowserRouter, type RouteObject } from 'react-router'
import { RutaProtegida } from '@/app/RutaProtegida'
import { PortalAvisoPrivacidad } from '@/features/portal/PortalAvisoPrivacidad'
import { PortalProgramacion } from '@/features/portal/PortalProgramacion'
import { PortalResultados } from '@/features/portal/PortalResultados'
import { PortalTabla } from '@/features/portal/PortalTabla'
import { InicioSesion } from '@/features/seguridad/InicioSesion'
import { ProveedorSesionActual } from '@/features/seguridad/ProveedorSesionActual'
import { RestablecerContrasena } from '@/features/seguridad/RestablecerContrasena'
import { InternalLayout } from '@/layouts/InternalLayout'
import { PublicLayout } from '@/layouts/PublicLayout'
import { seccionesApp } from '@/layouts/navegacion'
import { EnConstruccion } from '@/pages/EnConstruccion'
import { PaginaNoEncontrada } from '@/pages/PaginaNoEncontrada'

const paginasApp = seccionesApp.map(({ nombre, ruta }) => ({
  path: ruta,
  element: (
    <EnConstruccion
      titulo={nombre}
      descripcion="Módulo de la aplicación interna en construcción."
    />
  ),
}))

export const rutas: RouteObject[] = [
  {
    element: <PublicLayout />,
    children: [
      { path: '/', element: <PortalProgramacion /> },
      { path: '/resultados', element: <PortalResultados /> },
      { path: '/tabla', element: <PortalTabla /> },
      { path: '/aviso-de-privacidad', element: <PortalAvisoPrivacidad /> },
      { path: '*', element: <PaginaNoEncontrada /> },
    ],
  },
  {
    path: '/login',
    element: <InicioSesion />,
  },
  {
    path: '/restablecer-contrasena',
    element: <RestablecerContrasena />,
  },
  {
    element: <RutaProtegida />,
    children: [
      {
        element: (
          <ProveedorSesionActual>
            <InternalLayout />
          </ProveedorSesionActual>
        ),
        children: [
          ...paginasApp,
          { path: '/app/*', element: <PaginaNoEncontrada rutaInicio="/app" /> },
        ],
      },
    ],
  },
]

export const router = createBrowserRouter(rutas)
