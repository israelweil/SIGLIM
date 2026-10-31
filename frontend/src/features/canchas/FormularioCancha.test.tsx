import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { FormularioCancha } from '@/features/canchas/FormularioCancha'
import type { Cancha } from '@/features/canchas/tipos'
import { ApiError } from '@/lib/api/ApiError'

const { post, patch } = vi.hoisted(() => ({ post: vi.fn(), patch: vi.fn() }))

vi.mock('@/lib/api/cliente', () => ({ api: { post, patch } }))

const CANCHA: Cancha = {
  id: 'c1',
  nombre: 'Cancha 1',
  ubicacion: 'UNIDAD_DEPORTIVA',
  direccion: 'Calle Reforma 1',
  propietario: 'LIGA',
  caracteristicas: 'Pasto natural',
  activa: true,
  creadoEn: '2030-01-01T10:00:00-06:00',
}

function montar(cancha?: Cancha) {
  const onGuardada = vi.fn()
  const onCerrar = vi.fn()

  render(
    <QueryClientProvider client={new QueryClient()}>
      <FormularioCancha cancha={cancha} onCerrar={onCerrar} onGuardada={onGuardada} />
    </QueryClientProvider>,
  )

  return { onGuardada, onCerrar }
}

const guardar = () => userEvent.click(screen.getByRole('button', { name: 'Guardar' }))

describe('FormularioCancha', () => {
  beforeEach(() => {
    post.mockReset()
    patch.mockReset()
  })

  it('RF-027: crear con propietario externo envía solo lo que corresponde', async () => {
    post.mockResolvedValue(CANCHA)
    const { onGuardada } = montar()

    await userEvent.type(screen.getByLabelText(/Nombre/), '  Cancha Norte ')
    await userEvent.selectOptions(screen.getByLabelText(/Ubicación/), 'EXTERNA')
    await userEvent.selectOptions(screen.getByLabelText(/^Propietario/), 'EXTERNO')
    await userEvent.type(screen.getByLabelText(/Propietario externo/), 'Sr. Pérez')
    await guardar()

    expect(post).toHaveBeenCalledWith('canchas', {
      nombre: 'Cancha Norte',
      ubicacion: 'EXTERNA',
      propietario: 'EXTERNO',
      propietarioExterno: 'Sr. Pérez',
    })
    expect(onGuardada.mock.calls[0][0]).toEqual(CANCHA)
  })

  it('RF-027: al crear no ofrece Club y explica por qué', () => {
    montar()

    expect(screen.queryByRole('option', { name: /Club/ })).not.toBeInTheDocument()
    expect(screen.getByText(/Las canchas de club se registran/)).toBeInTheDocument()
  })

  it('RF-027: exige nombre, ubicación, propietario y propietario externo', async () => {
    montar()

    await userEvent.selectOptions(screen.getByLabelText(/^Propietario/), 'EXTERNO')
    await guardar()

    expect(post).not.toHaveBeenCalled()
    expect(screen.getByText('Escribe el nombre de la cancha.')).toBeInTheDocument()
    expect(screen.getByText('Elige la ubicación.')).toBeInTheDocument()
    expect(screen.getByText('Escribe quién es el propietario externo.')).toBeInTheDocument()
  })

  it('RF-027: PATCH envía solo los campos cambiados', async () => {
    patch.mockResolvedValue(CANCHA)
    montar(CANCHA)

    await userEvent.clear(screen.getByLabelText(/Nombre/))
    await userEvent.type(screen.getByLabelText(/Nombre/), 'Cancha Sur')
    await guardar()

    expect(patch).toHaveBeenCalledWith('canchas/c1', { nombre: 'Cancha Sur' })
  })

  it('RF-027: vaciar la dirección la borra y nunca envía activa', async () => {
    patch.mockResolvedValue(CANCHA)
    montar(CANCHA)

    expect(screen.getAllByText('Déjalo vacío para borrarlo.').length).toBeGreaterThan(0)
    await userEvent.clear(screen.getByLabelText(/Dirección/))
    await guardar()

    expect(patch).toHaveBeenCalledWith('canchas/c1', { direccion: '' })
  })

  it('RF-027: sin cambios no envía y cierra', async () => {
    const { onCerrar } = montar(CANCHA)

    await guardar()

    expect(patch).not.toHaveBeenCalled()
    expect(onCerrar).toHaveBeenCalledOnce()
  })

  it('RF-027: al cambiar de propietario envía también el propietario externo, sin clubId', async () => {
    patch.mockResolvedValue(CANCHA)
    montar(CANCHA)

    await userEvent.selectOptions(screen.getByLabelText(/^Propietario/), 'EXTERNO')
    await userEvent.type(screen.getByLabelText(/Propietario externo/), 'Sr. Pérez')
    await guardar()

    expect(patch).toHaveBeenCalledWith('canchas/c1', {
      propietario: 'EXTERNO',
      propietarioExterno: 'Sr. Pérez',
    })
  })

  it('RF-027: una cancha de club muestra su club y no ofrece otro', () => {
    montar({ ...CANCHA, propietario: 'CLUB', club: { id: 'club-1', nombre: 'Halcones' } })

    expect(screen.getByLabelText(/^Propietario/)).toHaveValue('CLUB')
    expect(screen.getAllByRole('option', { name: /Club/ })).toHaveLength(1)
    expect(screen.getByRole('option', { name: 'Club: Halcones' })).toBeInTheDocument()
  })

  it('RF-027: un 409 DUPLICADO se marca en el nombre', async () => {
    patch.mockRejectedValue(
      new ApiError({ title: 'Conflicto', status: 409, detail: 'Ya existe esa cancha.', codigo: 'DUPLICADO' }),
    )
    montar(CANCHA)

    await userEvent.type(screen.getByLabelText(/Nombre/), ' B')
    await guardar()

    expect(await screen.findByText('Ya existe esa cancha.')).toBeInTheDocument()
    expect(screen.getByLabelText(/Nombre/)).toHaveAttribute('aria-invalid', 'true')
  })

  it('RF-027: un 400 marca los campos de errores y muestra su detalle', async () => {
    post.mockRejectedValue(
      new ApiError({
        title: 'Inválida',
        status: 400,
        detail: 'Revisa los campos marcados.',
        codigo: 'VALIDACION',
        errores: [{ campo: 'nombre', mensaje: 'El nombre admite hasta 120 caracteres' }],
      }),
    )
    montar()

    await userEvent.type(screen.getByLabelText(/Nombre/), 'Cancha')
    await userEvent.selectOptions(screen.getByLabelText(/Ubicación/), 'EXTERNA')
    await userEvent.selectOptions(screen.getByLabelText(/^Propietario/), 'LIGA')
    await guardar()

    expect(await screen.findByText('El nombre admite hasta 120 caracteres')).toBeInTheDocument()
    expect(screen.getByText('Revisa los campos marcados.')).toBeInTheDocument()
  })
})
