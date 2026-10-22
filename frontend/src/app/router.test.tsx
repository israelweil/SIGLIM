import { render, screen } from '@testing-library/react'
import { createMemoryRouter, RouterProvider } from 'react-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { rutas } from '@/app/router'

const { obtenerSesion } = vi.hoisted(() => ({ obtenerSesion: vi.fn() }))

vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: obtenerSesion,
    },
  },
}))

function montar(ruta: string) {
  const enrutador = createMemoryRouter(rutas, { initialEntries: [ruta] })

  render(<RouterProvider router={enrutador} />)
}

describe('router', () => {
  beforeEach(() => {
    obtenerSesion.mockReset()
    obtenerSesion.mockResolvedValue({ data: { session: null }, error: null })
  })

  it('muestra el portal público en /', () => {
    montar('/')

    expect(
      screen.getByRole('heading', { name: 'Programación' }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('link', { name: 'SIGLIM, portal público' }),
    ).toBeInTheDocument()
  })

  it('muestra los resultados del portal en /resultados', () => {
    montar('/resultados')

    expect(
      screen.getByRole('heading', { name: 'Resultados' }),
    ).toBeInTheDocument()
  })

  it('envía /app al inicio de sesión cuando no hay sesión', async () => {
    montar('/app')

    expect(
      await screen.findByRole('heading', { name: 'Iniciar sesión' }),
    ).toBeInTheDocument()
  })

  it('muestra la aplicación interna en /app cuando hay sesión', async () => {
    obtenerSesion.mockResolvedValue({
      data: { session: { access_token: 'token-de-prueba' } },
      error: null,
    })

    montar('/app')

    expect(
      await screen.findByRole('heading', { name: 'Inicio' }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('navigation', { name: 'Menú Ejecutivo' }),
    ).toBeInTheDocument()
  })
})
