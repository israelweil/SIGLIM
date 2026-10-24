import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen } from '@testing-library/react'
import { createMemoryRouter, RouterProvider } from 'react-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { rutas } from '@/app/router'

const { obtenerSesion, obtenerYo } = vi.hoisted(() => ({
  obtenerSesion: vi.fn(),
  obtenerYo: vi.fn(),
}))

vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: obtenerSesion,
    },
  },
}))

vi.mock('@/lib/api/cliente', () => ({
  api: { get: obtenerYo },
}))

function montar(ruta: string) {
  const clienteConsultas = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })
  const enrutador = createMemoryRouter(rutas, { initialEntries: [ruta] })

  render(
    <QueryClientProvider client={clienteConsultas}>
      <RouterProvider router={enrutador} />
    </QueryClientProvider>,
  )
}

describe('router', () => {
  beforeEach(() => {
    obtenerSesion.mockReset()
    obtenerYo.mockReset()
    obtenerSesion.mockResolvedValue({ data: { session: null }, error: null })
    obtenerYo.mockResolvedValue({
      perfil: {
        id: 'perfil-1',
        nombreMostrado: 'Ana Pérez',
        correo: null,
      },
      asignaciones: [],
      permisos: [],
    })
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

  it('muestra la página 404 en una ruta inexistente', () => {
    montar('/ruta-que-no-existe')

    expect(
      screen.getByRole('heading', { name: 'No encontramos lo que buscas' }),
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

  it('con sesión, /app/inexistente muestra la 404 dentro de la aplicación interna', async () => {
    obtenerSesion.mockResolvedValue({
      data: { session: { access_token: 'token-de-prueba' } },
      error: null,
    })

    montar('/app/inexistente')

    expect(
      await screen.findByRole('heading', { name: 'No encontramos lo que buscas' }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('navigation', { name: 'Menú Ejecutivo' }),
    ).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Volver al inicio' })).toHaveAttribute(
      'href',
      '/app',
    )
  })
})
