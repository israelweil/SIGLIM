import { describe, expect, it, vi } from 'vitest'
import { descripcionDeAcceso } from '@/features/seguridad/sesion'
import type { Asignacion } from '@/features/seguridad/tipos'

vi.mock('@/lib/supabase', () => ({
  supabase: { auth: { signOut: vi.fn() } },
}))

function asignacion(parcial: Partial<Asignacion> = {}): Asignacion {
  return {
    id: 'asignacion-1',
    rol: { codigo: 'CAPTURISTA', nombre: 'Capturista' },
    ambito: 'LIGA',
    club: null,
    ...parcial,
  }
}

describe('descripcionDeAcceso', () => {
  it('H-01: muestra el rol y el ámbito de liga', () => {
    expect(descripcionDeAcceso([asignacion()])).toBe('Capturista · Liga')
  })

  it('H-01: muestra el nombre del club cuando el ámbito es de club', () => {
    expect(
      descripcionDeAcceso([
        asignacion({
          rol: { codigo: 'DIRECTIVA_CLUB', nombre: 'Directiva de club' },
          ambito: 'CLUB',
          club: { id: 'club-1', nombre: 'Halcones FC' },
        }),
      ]),
    ).toBe('Directiva de club · Halcones FC')
  })

  it('H-01: informa cuando no hay una asignación activa', () => {
    expect(descripcionDeAcceso([])).toBe('Sin rol asignado')
  })

  it('H-01: indica cuántas asignaciones adicionales hay', () => {
    expect(
      descripcionDeAcceso([
        asignacion(),
        asignacion({
          id: 'asignacion-2',
          rol: { codigo: 'ARBITRO', nombre: 'Árbitro' },
          ambito: 'PROPIO',
        }),
      ]),
    ).toBe('Capturista · Liga (+1)')
  })
})
