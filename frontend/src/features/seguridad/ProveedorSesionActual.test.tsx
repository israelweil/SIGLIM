import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createMemoryRouter, RouterProvider } from 'react-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { ProveedorSesionActual } from '@/features/seguridad/ProveedorSesionActual'
import { ApiError } from '@/lib/api/ApiError'

const { obtenerYo, cerrarSesion } = vi.hoisted(() => ({
  obtenerYo: vi.fn(),
  cerrarSesion: vi.fn(),
}))

vi.mock('@/lib/api/cliente', () => ({
  api: { get: obtenerYo },
}))

vi.mock('@/lib/supabase', () => ({
  supabase: { auth: { signOut: cerrarSesion } },
}))

function montar() {
  const clienteConsultas = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })
  const enrutador = createMemoryRouter(
    [
      { path: '/login', element: <h1>Iniciar sesión</h1> },
      {
        path: '/app',
        element: (
          <ProveedorSesionActual>
            <h1>Panel de inicio</h1>
          </ProveedorSesionActual>
        ),
      },
    ],
    { initialEntries: ['/app'] },
  )

  render(
    <QueryClientProvider client={clienteConsultas}>
      <RouterProvider router={enrutador} />
    </QueryClientProvider>,
  )
}

describe('ProveedorSesionActual', () => {
  beforeEach(() => {
    obtenerYo.mockReset()
    cerrarSesion.mockReset()
    cerrarSesion.mockResolvedValue({ error: null })
  })

  it('H-01.3: ante un 401 de /yo cierra la sesión y vuelve al inicio de sesión', async () => {
    obtenerYo.mockRejectedValue(
      new ApiError({
        title: 'Sesión no válida',
        status: 401,
        detail: 'Tu sesión venció. Inicia sesión de nuevo.',
        codigo: 'NO_AUTENTICADO',
      }),
    )

    montar()

    expect(
      await screen.findByRole('heading', { name: 'Iniciar sesión' }),
    ).toBeInTheDocument()
    expect(cerrarSesion).toHaveBeenCalledTimes(1)
  })

  it('muestra el detalle de un error distinto de 401 y permite reintentar', async () => {
    const usuario = userEvent.setup()
    obtenerYo.mockRejectedValueOnce(
      new ApiError({
        title: 'Error inesperado',
        status: 500,
        detail: 'El servicio no pudo cargar tu perfil.',
        codigo: 'ERROR_INTERNO',
      }),
    )
    obtenerYo.mockResolvedValueOnce({
      perfil: {
        id: 'perfil-1',
        nombreMostrado: 'Ana Pérez',
        correo: null,
      },
      asignaciones: [],
      permisos: [],
    })

    montar()

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'El servicio no pudo cargar tu perfil.',
    )

    await usuario.click(screen.getByRole('button', { name: 'Reintentar' }))

    expect(
      await screen.findByRole('heading', { name: 'Panel de inicio' }),
    ).toBeInTheDocument()
  })
})
