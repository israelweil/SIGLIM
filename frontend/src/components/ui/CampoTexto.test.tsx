import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { CampoTexto } from '@/components/ui/CampoTexto'

describe('CampoTexto', () => {
  it('asocia la etiqueta y describe el error del campo', () => {
    render(
      <CampoTexto
        id="correo"
        etiqueta="Correo"
        error="Escribe un correo válido."
        value=""
        onChange={() => {}}
      />,
    )

    const campo = screen.getByLabelText('Correo')

    expect(campo).toHaveAttribute('aria-invalid', 'true')
    expect(campo).toHaveAttribute('aria-describedby', 'correo-error')
    expect(screen.getByRole('alert')).toHaveTextContent(
      'Escribe un correo válido.',
    )
  })

  it('muestra la ayuda y permite usar una acción dentro del campo', async () => {
    const alMostrar = vi.fn()

    render(
      <CampoTexto
        id="contrasena"
        etiqueta="Contraseña"
        ayuda="Mínimo 15 caracteres."
        value=""
        onChange={() => {}}
        accion={
          <button type="button" onClick={alMostrar}>
            Mostrar
          </button>
        }
      />,
    )

    expect(screen.getByLabelText('Contraseña')).toHaveAttribute(
      'aria-describedby',
      'contrasena-ayuda',
    )

    await userEvent.click(screen.getByRole('button', { name: 'Mostrar' }))

    expect(alMostrar).toHaveBeenCalledTimes(1)
  })

  it('marca los campos obligatorios', () => {
    render(
      <CampoTexto
        id="obligatorio"
        etiqueta="Obligatorio"
        required
        value=""
        onChange={() => {}}
      />,
    )

    expect(screen.getByLabelText(/Obligatorio/)).toBeRequired()
  })
})
