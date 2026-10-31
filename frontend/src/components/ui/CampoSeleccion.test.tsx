import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { CampoSeleccion } from '@/components/ui/CampoSeleccion'

function montar(error?: string) {
  render(
    <CampoSeleccion id="ubicacion" etiqueta="Ubicación" required error={error}>
      <option value="">Selecciona…</option>
      <option value="EXTERNA">Externa</option>
    </CampoSeleccion>,
  )
}

describe('CampoSeleccion', () => {
  it('RNF-008: la etiqueta queda asociada a la lista', () => {
    montar()

    const campo = screen.getByRole('combobox', { name: /Ubicación/ })

    expect(campo).toBeRequired()
    expect(campo).not.toHaveAttribute('aria-invalid')
    expect(screen.queryByRole('alert')).not.toBeInTheDocument()
  })

  it('RNF-008: el error se anuncia con role="alert" y queda enlazado al campo', () => {
    montar('Elige la ubicación.')

    const campo = screen.getByRole('combobox', { name: /Ubicación/ })

    expect(screen.getByRole('alert')).toHaveTextContent('Elige la ubicación.')
    expect(campo).toHaveAttribute('aria-invalid', 'true')
    expect(campo).toHaveAccessibleDescription('Elige la ubicación.')
  })
})
