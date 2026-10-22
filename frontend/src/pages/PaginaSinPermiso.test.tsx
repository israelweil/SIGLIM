import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { describe, expect, it } from 'vitest'
import { PaginaSinPermiso } from '@/pages/PaginaSinPermiso'

describe('PaginaSinPermiso', () => {
  it('VAL-015: informa la denegación y ofrece volver al inicio', () => {
    render(
      <MemoryRouter>
        <PaginaSinPermiso rutaInicio="/app" />
      </MemoryRouter>,
    )

    expect(
      screen.getByRole('heading', { name: 'No tienes permiso para esta acción' }),
    ).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Volver al inicio' })).toHaveAttribute(
      'href',
      '/app',
    )
  })
})
