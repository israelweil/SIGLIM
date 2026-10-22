import { render, screen } from '@testing-library/react'
import { createMemoryRouter, RouterProvider } from 'react-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { RutaProtegida } from '@/app/RutaProtegida'

const { obtenerSesion } = vi.hoisted(() => ({ obtenerSesion: vi.fn() }))

vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: obtenerSesion,
    },
  },
}))

function montarRutaProtegida() {
  const enrutador = createMemoryRouter(
    [
      { path: '/login', element: <h1>Iniciar sesión</h1> },
      {
        element: <RutaProtegida />,
        children: [{ path: '/app', element: <h1>Panel de inicio</h1> }],
      },
    ],
    { initialEntries: ['/app'] },
  )

  render(<RouterProvider router={enrutador} />)
}

describe('RutaProtegida', () => {
  beforeEach(() => {
    obtenerSesion.mockReset()
  })

  it('redirige al inicio de sesión cuando no hay sesión', async () => {
    obtenerSesion.mockResolvedValue({ data: { session: null }, error: null })

    montarRutaProtegida()

    expect(await screen.findByRole('heading', { name: 'Iniciar sesión' })).toBeInTheDocument()
  })

  it('muestra la ruta hija cuando hay sesión', async () => {
    obtenerSesion.mockResolvedValue({
      data: { session: { access_token: 'token-de-prueba' } },
      error: null,
    })

    montarRutaProtegida()

    expect(await screen.findByRole('heading', { name: 'Panel de inicio' })).toBeInTheDocument()
  })
})
