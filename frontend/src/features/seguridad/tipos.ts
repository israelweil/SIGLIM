/** Ámbitos de una asignación de rol (ADR-0007). */
export type Ambito = 'LIGA' | 'CLUB' | 'PROPIO'

export type Rol = {
  codigo: string
  nombre: string
}

export type Club = {
  id: string
  nombre: string
}

export type Asignacion = {
  id: string
  rol: Rol
  ambito: Ambito
  club: Club | null
}

export type Permiso = {
  codigo: string
  modulo: string
  ambito: Ambito
  clubId: string | null
}

export type Perfil = {
  id: string
  nombreMostrado: string
  correo: string | null
}

/** Respuesta de `GET /api/v1/yo` (H-01.1). */
export type Yo = {
  perfil: Perfil
  asignaciones: Asignacion[]
  permisos: Permiso[]
}
