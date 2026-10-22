import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Save } from 'lucide-react'
import { describe, expect, it, vi } from 'vitest'
import { Button } from '@/components/ui/Button'

describe('Button', () => {
  it('ejecuta la acción al hacer clic y es de tipo button por defecto', async () => {
    const alHacerClic = vi.fn()
    render(
      <Button icono={Save} onClick={alHacerClic}>
        Guardar
      </Button>,
    )

    const boton = screen.getByRole('button', { name: 'Guardar' })
    await userEvent.click(boton)

    expect(alHacerClic).toHaveBeenCalledTimes(1)
    expect(boton).toHaveAttribute('type', 'button')
  })

  it('RNF-008: tiene altura mínima de 44 px y el ícono es decorativo', () => {
    render(<Button icono={Save}>Guardar</Button>)

    const boton = screen.getByRole('button', { name: 'Guardar' })

    expect(boton).toHaveClass('min-h-11')
    expect(boton.querySelector('svg')).toHaveAttribute('aria-hidden', 'true')
  })

  it('aplica la variante destructiva', () => {
    render(<Button variante="destructivo">Cancelar partido</Button>)

    expect(screen.getByRole('button', { name: 'Cancelar partido' })).toHaveClass('bg-error')
  })

  it('no ejecuta la acción si está deshabilitado', async () => {
    const alHacerClic = vi.fn()
    render(
      <Button disabled onClick={alHacerClic}>
        Guardar
      </Button>,
    )

    await userEvent.click(screen.getByRole('button', { name: 'Guardar' }))

    expect(alHacerClic).not.toHaveBeenCalled()
  })

  it('se deshabilita y se marca ocupado mientras carga', () => {
    render(<Button cargando>Guardar</Button>)

    const boton = screen.getByRole('button', { name: 'Guardar' })

    expect(boton).toBeDisabled()
    expect(boton).toHaveAttribute('aria-busy', 'true')
  })
})
