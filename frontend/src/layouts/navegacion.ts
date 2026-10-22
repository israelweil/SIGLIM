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
}

/** Navegación del portal público según F-01. */
export const enlacesPortal: EnlacePortal[] = [
  { nombre: 'Programación', ruta: '/' },
  { nombre: 'Resultados', ruta: '/resultados' },
  { nombre: 'Tablas de posiciones', ruta: '/tabla' },
]

/**
 * Menú Ejecutivo según F-07. Es una navegación provisional: H-01.3 la armará
 * desde los permisos de `GET /api/v1/yo` (PEN-014 sigue abierto con la Liga).
 */
export const seccionesApp: SeccionApp[] = [
  { nombre: 'Inicio', ruta: '/app', icono: LayoutDashboard },
  { nombre: 'Organización', ruta: '/app/organizacion', icono: Building2 },
  { nombre: 'Programación', ruta: '/app/programacion', icono: CalendarDays },
  { nombre: 'Partidos', ruta: '/app/partidos', icono: Goal },
  { nombre: 'Disciplina', ruta: '/app/disciplina', icono: Gavel },
  { nombre: 'Administración', ruta: '/app/administracion', icono: Settings },
]
