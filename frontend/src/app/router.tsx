import { createBrowserRouter, type RouteObject } from 'react-router'
import { RutaProtegida } from '@/app/RutaProtegida'
import { EnConstruccion } from '@/pages/EnConstruccion'

export const rutas: RouteObject[] = [
  {
    path: '/',
    element: (
      <EnConstruccion
        titulo="SIGLIM"
        descripcion="Portal público en construcción."
      />
    ),
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
        path: '/app',
        element: (
          <EnConstruccion
            titulo="Panel de inicio"
            descripcion="Aplicación interna en construcción."
          />
        ),
      },
    ],
  },
]

export const router = createBrowserRouter(rutas)
