import { createBrowserRouter, type RouteObject } from 'react-router'
import { RutaProtegida } from '@/app/RutaProtegida'
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
      {
        path: '/',
        element: (
          <EnConstruccion
            titulo="Programación"
            descripcion="Portal público en construcción: programación de la jornada."
          />
        ),
      },
      {
        path: '/resultados',
        element: (
          <EnConstruccion
            titulo="Resultados"
            descripcion="Portal público en construcción: resultados oficiales."
          />
        ),
      },
      {
        path: '/tabla',
        element: (
          <EnConstruccion
            titulo="Tablas de posiciones"
            descripcion="Portal público en construcción: tabla calculada por grupo."
          />
        ),
      },
      {
        path: '/aviso-de-privacidad',
        element: (
          <EnConstruccion
            titulo="Aviso de privacidad"
            descripcion="El texto del aviso lo define la Liga (PEN-039, DEC-40)."
          />
        ),
      },
      { path: '*', element: <PaginaNoEncontrada /> },
    ],
  },
  {
    path: '/login',
    element: (
      <EnConstruccion
        titulo="Iniciar sesión"
        descripcion="Pantalla en construcción."
      />
    ),
  },
  {
    element: <RutaProtegida />,
    children: [
      {
        element: <InternalLayout />,
        children: [
          ...paginasApp,
          { path: '/app/*', element: <PaginaNoEncontrada rutaInicio="/app" /> },
        ],
      },
    ],
  },
]

export const router = createBrowserRouter(rutas)
