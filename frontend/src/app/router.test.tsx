import { render, screen } from '@testing-library/react'
import { createMemoryRouter, RouterProvider } from 'react-router'
import { describe, expect, it, vi } from 'vitest'
import { rutas } from '@/app/router'

vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: vi.fn().mockResolvedValue({ data: { session: null }, error: null }),
    },
  },
}))

describe('router', () => {
  it('muestra el portal público en /', () => {
    const enrutador = createMemoryRouter(rutas, { initialEntries: ['/'] })

    render(<RouterProvider router={enrutador} />)

    expect(screen.getByRole('heading', { name: 'SIGLIM' })).toBeInTheDocument()
  })

  it('envía /app al inicio de sesión cuando no hay sesión', async () => {
    const enrutador = createMemoryRouter(rutas, { initialEntries: ['/app'] })

    render(<RouterProvider router={enrutador} />)

    expect(await screen.findByRole('heading', { name: 'Iniciar sesión' })).toBeInTheDocument()
  })
})
