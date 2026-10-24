import { act, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createMemoryRouter, RouterProvider } from 'react-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { InicioSesion } from '@/features/seguridad/InicioSesion'
import { RestablecerContrasena } from '@/features/seguridad/RestablecerContrasena'

const {
  obtenerSesion,
  actualizarUsuario,
  cerrarSesion,
  alCambiarSesion,
  iniciarSesionConContrasena,
  solicitarRestablecimiento,
} = vi.hoisted(() => ({
  obtenerSesion: vi.fn(),
  actualizarUsuario: vi.fn(),
  cerrarSesion: vi.fn(),
  alCambiarSesion: vi.fn(),
  iniciarSesionConContrasena: vi.fn(),
  solicitarRestablecimiento: vi.fn(),
}))

vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: obtenerSesion,
      updateUser: actualizarUsuario,
      signOut: cerrarSesion,
      onAuthStateChange: alCambiarSesion,
      signInWithPassword: iniciarSesionConContrasena,
      resetPasswordForEmail: solicitarRestablecimiento,
    },
  },
}))

function montar(entrada = '/restablecer-contrasena') {
  const enrutador = createMemoryRouter(
    [
      { path: '/login', element: <InicioSesion /> },
      { path: '/restablecer-contrasena', element: <RestablecerContrasena /> },
      { path: '/app', element: <h1>Panel de inicio</h1> },
    ],
    { initialEntries: [entrada] },
  )

  render(<RouterProvider router={enrutador} />)
}

describe('RestablecerContrasena', () => {
  beforeEach(() => {
    obtenerSesion.mockReset()
    actualizarUsuario.mockReset()
    cerrarSesion.mockReset()
    alCambiarSesion.mockReset()
    iniciarSesionConContrasena.mockReset()
    solicitarRestablecimiento.mockReset()

    obtenerSesion.mockResolvedValue({ data: { session: null }, error: null })
    actualizarUsuario.mockResolvedValue({
      data: { user: {} },
      error: null,
    })
    cerrarSesion.mockResolvedValue({ error: null })
    alCambiarSesion.mockReturnValue({
      data: { subscription: { unsubscribe: vi.fn() } },
    })
    iniciarSesionConContrasena.mockResolvedValue({
      data: { user: null, session: { access_token: 'token' } },
      error: null,
    })
    solicitarRestablecimiento.mockResolvedValue({ data: {}, error: null })
  })

  it('H-01.2: avisa si el enlace no tiene una sesión válida', async () => {
    montar()

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'El enlace no es válido o ya venció.',
    )
    expect(
      screen.getByRole('link', { name: 'Solicitar un enlace nuevo' }),
    ).toHaveAttribute('href', '/login?recuperar=1')
  })

  it('H-01.2: guarda la contraseña nueva y vuelve al inicio de sesión', async () => {
    const usuario = userEvent.setup()
    obtenerSesion
      .mockResolvedValueOnce({
        data: { session: { access_token: 'sesion-recuperacion' } },
        error: null,
      })
      .mockResolvedValue({ data: { session: null }, error: null })

    montar()

    await usuario.type(
      await screen.findByLabelText(/nueva contraseña/i),
      'frase secreta larga',
    )
    await usuario.type(
      screen.getByLabelText(/confirmar contraseña/i),
      'frase secreta larga',
    )
    await usuario.click(
      screen.getByRole('button', { name: 'Guardar contraseña' }),
    )

    expect(actualizarUsuario).toHaveBeenCalledWith({
      password: 'frase secreta larga',
    })
    expect(cerrarSesion).toHaveBeenCalledTimes(1)
    expect(
      await screen.findByRole('heading', { name: 'Iniciar sesión' }),
    ).toBeInTheDocument()
    expect(
      await screen.findByText(
        'Contraseña actualizada. Inicia sesión con tu nueva contraseña.',
      ),
    ).toBeInTheDocument()
  })

  it('H-01.2: rechaza contraseñas que no coinciden', async () => {
    const usuario = userEvent.setup()
    obtenerSesion.mockResolvedValue({
      data: { session: { access_token: 'sesion-recuperacion' } },
      error: null,
    })

    montar()

    await usuario.type(
      await screen.findByLabelText(/nueva contraseña/i),
      'frase secreta larga',
    )
    await usuario.type(
      screen.getByLabelText(/confirmar contraseña/i),
      'otra frase distinta',
    )
    await usuario.click(
      screen.getByRole('button', { name: 'Guardar contraseña' }),
    )

    expect(
      await screen.findByText('Las contraseñas no coinciden.'),
    ).toBeInTheDocument()
    expect(actualizarUsuario).not.toHaveBeenCalled()
  })

  it('H-01.2: aplica la longitud mínima de la política de contraseñas', async () => {
    const usuario = userEvent.setup()
    obtenerSesion.mockResolvedValue({
      data: { session: { access_token: 'sesion-recuperacion' } },
      error: null,
    })

    montar()

    await usuario.type(
      await screen.findByLabelText(/nueva contraseña/i),
      'corta',
    )
    await usuario.type(screen.getByLabelText(/confirmar contraseña/i), 'corta')
    await usuario.click(
      screen.getByRole('button', { name: 'Guardar contraseña' }),
    )

    expect(
      await screen.findByText(/al menos 15 caracteres/),
    ).toBeInTheDocument()
    expect(actualizarUsuario).not.toHaveBeenCalled()
  })

  it('H-01.2: explica cuando Supabase rechaza la contraseña por débil', async () => {
    const usuario = userEvent.setup()
    obtenerSesion.mockResolvedValue({
      data: { session: { access_token: 'sesion-recuperacion' } },
      error: null,
    })
    actualizarUsuario.mockResolvedValue({
      data: { user: null },
      error: { status: 422, code: 'weak_password' },
    })

    montar()

    await usuario.type(
      await screen.findByLabelText(/nueva contraseña/i),
      'frase secreta larga',
    )
    await usuario.type(
      screen.getByLabelText(/confirmar contraseña/i),
      'frase secreta larga',
    )
    await usuario.click(
      screen.getByRole('button', { name: 'Guardar contraseña' }),
    )

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'política de seguridad',
    )
  })

  it('H-01.2: habilita el formulario al recibir PASSWORD_RECOVERY', async () => {
    let alRecibirEvento:
      | ((evento: string, sesion: unknown) => void)
      | undefined

    alCambiarSesion.mockImplementation(
      (callback: (evento: string, sesion: unknown) => void) => {
        alRecibirEvento = callback
        return { data: { subscription: { unsubscribe: vi.fn() } } }
      },
    )
    obtenerSesion.mockResolvedValue({ data: { session: null }, error: null })

    montar()

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'El enlace no es válido',
    )

    act(() => {
      alRecibirEvento?.('PASSWORD_RECOVERY', { access_token: 'token' })
    })

    expect(await screen.findByLabelText(/nueva contraseña/i)).toBeInTheDocument()
  })
})
