import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { describe, expect, it } from 'vitest'
import { PaginaNoEncontrada } from '@/pages/PaginaNoEncontrada'

describe('PaginaNoEncontrada', () => {
  it('VAL-024: no revela si el recurso existe y ofrece volver al inicio', () => {
    render(
      <MemoryRouter>
        <PaginaNoEncontrada />
      </MemoryRouter>,
    )

    expect(
      screen.getByRole('heading', { name: 'No encontramos lo que buscas' }),
    ).toBeInTheDocument()
    expect(
      screen.getByText('Puede que no exista o que no tengas acceso.'),
    ).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Volver al inicio' })).toHaveAttribute(
      'href',
      '/',
    )
  })
})
