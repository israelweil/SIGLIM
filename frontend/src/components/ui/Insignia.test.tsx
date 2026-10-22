import { render, screen } from '@testing-library/react'
import { CalendarDays } from 'lucide-react'
import { describe, expect, it } from 'vitest'
import { Insignia } from '@/components/ui/Insignia'

describe('Insignia', () => {
  it('RNF-008: muestra ícono y texto, no solo color', () => {
    render(<Insignia variante="exito">Activo</Insignia>)

    const insignia = screen.getByText('Activo')

    expect(insignia).toHaveClass('uppercase', 'h-6', 'text-success-strong')
    expect(insignia.querySelector('svg')).toHaveAttribute('aria-hidden', 'true')
  })

  it.each([
    ['error', 'text-error-strong'],
    ['advertencia', 'text-warning-strong'],
    ['informacion', 'text-info-strong'],
    ['neutra', 'text-text-main'],
  ] as const)('aplica la variante %s', (variante, clase) => {
    render(<Insignia variante={variante}>Estado</Insignia>)

    expect(screen.getByText('Estado')).toHaveClass(clase)
  })

  it('permite sustituir el ícono de la variante', () => {
    render(
      <Insignia variante="informacion" icono={CalendarDays}>
        Programado
      </Insignia>,
    )

    expect(
      screen.getByText('Programado').querySelector('svg.lucide-calendar-days'),
    ).toBeInTheDocument()
  })
})
