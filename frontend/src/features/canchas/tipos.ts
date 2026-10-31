/** DTO de canchas: los mismos nombres del contrato (convenciones de API §6.6). */

export type UbicacionCancha = 'UNIDAD_DEPORTIVA' | 'EXTERNA'
export type PropietarioCancha = 'LIGA' | 'CLUB' | 'EXTERNO'
export type TipoDisponibilidad = 'DISPONIBLE' | 'BLOQUEO' | 'MANTENIMIENTO'
export type TipoBloqueOcupacion = TipoDisponibilidad | 'PARTIDO'

/** `hasta` es exclusivo; las fechas son ISO 8601 con desplazamiento. */
export type Intervalo = {
  desde: string
  hasta: string
}

export type Cancha = {
  id: string
  nombre: string
  ubicacion: UbicacionCancha
  direccion?: string
  propietario: PropietarioCancha
  club?: { id: string; nombre: string }
  propietarioExterno?: string
  caracteristicas?: string
  activa: boolean
  creadoEn: string
}

export type Disponibilidad = {
  id: string
  tipo: TipoDisponibilidad
  periodo: Intervalo
  motivo?: string
  creadoEn: string
}

export type PartidoEnCancha = {
  id: string
  estado: string
  periodo: Intervalo
  equipoLocal: { id: string; nombre: string }
  equipoVisitante: { id: string; nombre: string }
}

export type RegistroDisponibilidad = {
  disponibilidad: Disponibilidad
  partidosAfectados: PartidoEnCancha[]
}

export type BloqueOcupacion = {
  tipo: TipoBloqueOcupacion
  periodo: Intervalo
  motivo?: string
  partido?: PartidoEnCancha
}

export type Ocupacion = {
  cancha: { id: string; nombre: string }
  activa: boolean
  periodo: Intervalo
  bloques: BloqueOcupacion[]
}

export type FiltrosCanchas = {
  q?: string
  ubicacion?: UbicacionCancha
  activa?: boolean
  pagina: number
  tamano: number
}

export type CrearCanchaPeticion = {
  nombre: string
  ubicacion: UbicacionCancha
  direccion?: string
  propietario: PropietarioCancha
  propietarioExterno?: string
  caracteristicas?: string
}

/** Un campo ausente conserva su valor; `direccion` y `caracteristicas` en blanco se vacían. */
export type ActualizarCanchaPeticion = Partial<CrearCanchaPeticion> & {
  activa?: boolean
  motivo?: string
  confirmarPartidosAfectados?: boolean
}

export type RegistrarDisponibilidadPeticion = {
  tipo: 'DISPONIBLE' | 'BLOQUEO'
  periodo: Intervalo
  motivo?: string
  confirmarPartidosAfectados?: boolean
}
