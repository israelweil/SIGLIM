import {
  Building2,
  CalendarDays,
  Gavel,
  Goal,
  LayoutDashboard,
  Settings,
  type LucideIcon,
} from 'lucide-react'

export type EnlacePortal = {
  nombre: string
  ruta: string
}

export type SeccionApp = EnlacePortal & {
  icono: LucideIcon
  /** Módulos del ERS que dan acceso a la sección. Vacío = siempre visible. */
  modulos: readonly string[]
}

/** Navegación del portal público según F-01. */
export const enlacesPortal: EnlacePortal[] = [
  { nombre: 'Programación', ruta: '/' },
  { nombre: 'Resultados', ruta: '/resultados' },
  { nombre: 'Tablas de posiciones', ruta: '/tabla' },
]

/**
 * Menú Ejecutivo de F-07 y correspondencia con los módulos del ERS.
 *
 * **[PROPUESTA]** La navegación final sigue abierta (PEN-014): esta tabla es una
 * hipótesis de trabajo, no una regla de negocio. Inicio se muestra siempre.
 *
 * M-14 (notificaciones) no tiene sección: los avisos se consultan desde la
 * campana (F-09, RF-142), no desde el menú lateral.
 */
export const seccionesApp: SeccionApp[] = [
  { nombre: 'Inicio', ruta: '/app', icono: LayoutDashboard, modulos: [] },
  {
    nombre: 'Organización',
    ruta: '/app/organizacion',
    icono: Building2,
    modulos: ['M-03', 'M-04'],
  },
  {
    nombre: 'Programación',
    ruta: '/app/programacion',
    icono: CalendarDays,
    modulos: ['M-05', 'M-06', 'M-07', 'M-10'],
  },
  { nombre: 'Partidos', ruta: '/app/partidos', icono: Goal, modulos: ['M-08'] },
  { nombre: 'Disciplina', ruta: '/app/disciplina', icono: Gavel, modulos: ['M-09'] },
  {
    nombre: 'Administración',
    ruta: '/app/administracion',
    icono: Settings,
    modulos: ['M-01', 'M-02', 'M-11', 'M-12', 'M-13'],
  },
]

/**
 * Secciones que puede ver el usuario según los permisos de `GET /api/v1/yo`.
 * Inicio siempre está presente. `notificaciones.*` se ignora para que la campana
 * de F-09 no cree una sección del menú (H-01.3).
 */
export function seccionesPermitidas(
  permisos: readonly { codigo: string; modulo: string }[],
): SeccionApp[] {
  const modulos = new Set(
    permisos
      .filter((permiso) => !permiso.codigo.startsWith('notificaciones.'))
      .map((permiso) => permiso.modulo),
  )

  return seccionesApp.filter(
    (seccion) =>
      seccion.modulos.length === 0 ||
      seccion.modulos.some((modulo) => modulos.has(modulo)),
  )
}
