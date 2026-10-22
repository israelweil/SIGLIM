import { render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router'
import { describe, expect, it } from 'vitest'
import { InternalLayout } from '@/layouts/InternalLayout'

function montar() {
  render(
    <MemoryRouter initialEntries={['/app']}>
      <Routes>
        <Route element={<InternalLayout />}>
          <Route path="/app" element={<p>Panel de inicio</p>} />
        </Route>
      </Routes>
    </MemoryRouter>,
  )
}

describe('InternalLayout', () => {
  it('muestra el Menú Ejecutivo de F-07 y la barra superior', () => {
    montar()

    const menu = screen.getByRole('navigation', { name: 'Menú Ejecutivo' })

    expect(
      within(menu).getByRole('link', { name: 'Inicio' }),
    ).toHaveAttribute('href', '/app')
    expect(
      within(menu).getByRole('link', { name: 'Organización' }),
    ).toHaveAttribute('href', '/app/organizacion')
    expect(
      within(menu).getByRole('link', { name: 'Programación' }),
    ).toHaveAttribute('href', '/app/programacion')
    expect(
      within(menu).getByRole('link', { name: 'Partidos' }),
    ).toHaveAttribute('href', '/app/partidos')
    expect(
      within(menu).getByRole('link', { name: 'Disciplina' }),
    ).toHaveAttribute('href', '/app/disciplina')
    expect(
      within(menu).getByRole('link', { name: 'Administración' }),
    ).toHaveAttribute('href', '/app/administracion')

    expect(
      screen.getByRole('link', { name: 'SIGLIM, aplicación interna' }),
    ).toHaveAttribute('href', '/app')
    expect(screen.getByText('Sesión activa')).toBeInTheDocument()
  })

  it('colapsa y expande la barra lateral', async () => {
    const usuario = userEvent.setup()
    montar()

    const boton = screen.getByRole('button', { name: 'Colapsar menú' })
    expect(boton).toHaveAttribute('aria-expanded', 'true')

    await usuario.click(boton)

    expect(boton).toHaveAttribute('aria-expanded', 'false')
    expect(boton).toHaveAccessibleName('Expandir menú')
    expect(
      screen.getByRole('navigation', { name: 'Menú Ejecutivo' }),
    ).toBeInTheDocument()

    await usuario.click(boton)

    expect(boton).toHaveAttribute('aria-expanded', 'true')
    expect(boton).toHaveAccessibleName('Colapsar menú')
  })

  it('abre el menú móvil, navega y devuelve el foco', async () => {
    const usuario = userEvent.setup()
    montar()

    const abrir = screen.getByRole('button', { name: 'Abrir menú' })

    await usuario.click(abrir)

    const dialogo = screen.getByRole('dialog', { name: 'Menú Ejecutivo' })
    expect(
      within(dialogo).getByRole('link', { name: 'Administración' }),
    ).toHaveAttribute('href', '/app/administracion')

    await usuario.keyboard('{Escape}')

    expect(
      screen.queryByRole('dialog', { name: 'Menú Ejecutivo' }),
    ).not.toBeInTheDocument()
    expect(abrir).toHaveFocus()
  })

  it('cierra el menú móvil con su botón', async () => {
    const usuario = userEvent.setup()
    montar()

    await usuario.click(screen.getByRole('button', { name: 'Abrir menú' }))

    const dialogo = screen.getByRole('dialog', { name: 'Menú Ejecutivo' })
    await usuario.click(
      within(dialogo).getByRole('button', { name: 'Cerrar menú' }),
    )

    expect(
      screen.queryByRole('dialog', { name: 'Menú Ejecutivo' }),
    ).not.toBeInTheDocument()
  })
})
