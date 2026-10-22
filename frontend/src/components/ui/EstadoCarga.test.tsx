import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { EstadoCarga } from '@/components/ui/EstadoCarga'

describe('EstadoCarga', () => {
  it('RNF-008: anuncia la carga a los lectores de pantalla', () => {
    render(<EstadoCarga etiqueta="Cargando partidos…" />)

    expect(screen.getByRole('status')).toHaveTextContent('Cargando partidos…')
  })

  it('dibuja el esqueleto con el número de filas indicado', () => {
    const { container } = render(<EstadoCarga filas={3} />)

    expect(container.querySelectorAll('.h-12')).toHaveLength(3)
  })
})
