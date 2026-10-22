import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { AlertaBloqueo } from '@/components/ui/AlertaBloqueo'

describe('AlertaBloqueo', () => {
  it('VAL-004: explica la causa, el dato que choca y qué hacer', () => {
    render(
      <AlertaBloqueo
        causa="No se puede programar: cancha ocupada"
        codigo="VAL-004"
        conflicto="Cancha 2 ya tiene el partido Halcones vs. Tigres a las 10:00."
        accion="Elige otra cancha u otro horario."
      />,
    )

    const alerta = screen.getByRole('alert')

    expect(alerta).toHaveTextContent('No se puede programar: cancha ocupada')
    expect(alerta).toHaveTextContent('(VAL-004)')
    expect(screen.getByText('Conflicto:').nextElementSibling).toHaveTextContent(
      'Cancha 2 ya tiene el partido Halcones vs. Tigres a las 10:00.',
    )
    expect(screen.getByText('Qué hacer:').nextElementSibling).toHaveTextContent(
      'Elige otra cancha u otro horario.',
    )
  })
})
