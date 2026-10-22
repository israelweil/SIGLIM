import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { Button } from '@/components/ui/Button'
import { EstadoVacio } from '@/components/ui/EstadoVacio'

describe('EstadoVacio', () => {
  it('muestra el mensaje y la acción sugerida', () => {
    render(
      <EstadoVacio
        titulo="Aún no hay canchas registradas"
        descripcion="Registra la primera cancha para programar partidos."
        accion={<Button>Registrar cancha</Button>}
      />,
    )

    expect(screen.getByText('Aún no hay canchas registradas')).toBeInTheDocument()
    expect(
      screen.getByText('Registra la primera cancha para programar partidos.'),
    ).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Registrar cancha' })).toBeInTheDocument()
  })
})
