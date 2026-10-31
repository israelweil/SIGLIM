import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import type {
  ActualizarCanchaPeticion,
  Cancha,
  CrearCanchaPeticion,
  FiltrosCanchas,
  Intervalo,
  Ocupacion,
  PartidoEnCancha,
  RegistrarDisponibilidadPeticion,
  RegistroDisponibilidad,
} from '@/features/canchas/tipos'
import { ApiError } from '@/lib/api/ApiError'
import { api } from '@/lib/api/cliente'
import type { Pagina } from '@/lib/api/tipos'

export const clavesCanchas = {
  todas: ['canchas'] as const,
  lista: (filtros: FiltrosCanchas) => ['canchas', 'lista', filtros] as const,
  detalle: (id: string) => ['canchas', 'detalle', id] as const,
  ocupacion: (id: string, desde: string, hasta: string) =>
    ['canchas', 'ocupacion', id, desde, hasta] as const,
}

function consultaDeFiltros({ q, ubicacion, activa, pagina, tamano }: FiltrosCanchas): string {
  const parametros = new URLSearchParams()

  if (q) {
    parametros.set('q', q)
  }
  if (ubicacion) {
    parametros.set('ubicacion', ubicacion)
  }
  if (activa !== undefined) {
    parametros.set('activa', String(activa))
  }
  parametros.set('pagina', String(pagina))
  parametros.set('tamano', String(tamano))
  parametros.set('orden', 'nombre,asc')

  return parametros.toString()
}

export function useCanchas(filtros: FiltrosCanchas) {
  return useQuery({
    queryKey: clavesCanchas.lista(filtros),
    queryFn: () => api.get<Pagina<Cancha>>(`canchas?${consultaDeFiltros(filtros)}`),
    placeholderData: keepPreviousData,
  })
}

export function useCancha(id?: string) {
  return useQuery({
    queryKey: clavesCanchas.detalle(id ?? ''),
    queryFn: () => api.get<Cancha>(`canchas/${id}`),
    enabled: Boolean(id),
  })
}

export function useOcupacion(id: string | undefined, rango: Intervalo) {
  return useQuery({
    queryKey: clavesCanchas.ocupacion(id ?? '', rango.desde, rango.hasta),
    queryFn: () =>
      api.get<Ocupacion>(
        `canchas/${id}/ocupacion?desde=${encodeURIComponent(rango.desde)}&hasta=${encodeURIComponent(rango.hasta)}`,
      ),
    enabled: Boolean(id),
  })
}

export function useCrearCancha() {
  const clienteConsultas = useQueryClient()

  return useMutation({
    mutationFn: (peticion: CrearCanchaPeticion) => api.post<Cancha>('canchas', peticion),
    onSuccess: () => clienteConsultas.invalidateQueries({ queryKey: ['canchas', 'lista'] }),
  })
}

export function useActualizarCancha(id: string) {
  const clienteConsultas = useQueryClient()

  return useMutation({
    mutationFn: (peticion: ActualizarCanchaPeticion) => api.patch<Cancha>(`canchas/${id}`, peticion),
    onSuccess: (cancha) => {
      clienteConsultas.setQueryData(clavesCanchas.detalle(id), cancha)
      void clienteConsultas.invalidateQueries({ queryKey: ['canchas', 'lista'] })
      void clienteConsultas.invalidateQueries({ queryKey: ['canchas', 'ocupacion', id] })
    },
  })
}

export function useRegistrarDisponibilidad(id: string) {
  const clienteConsultas = useQueryClient()

  return useMutation({
    mutationFn: (peticion: RegistrarDisponibilidadPeticion) =>
      api.post<RegistroDisponibilidad>(`canchas/${id}/disponibilidad`, peticion),
    onSuccess: () => clienteConsultas.invalidateQueries({ queryKey: ['canchas', 'ocupacion', id] }),
  })
}

/** El 409 `RF-030` se puede aceptar reenviando con `confirmarPartidosAfectados` (PEN-007). */
export function esBloqueoAceptable(error: unknown): boolean {
  return (
    error instanceof ApiError &&
    error.problema.status === 409 &&
    error.problema.codigo === 'RF-030' &&
    error.problema.aceptable === true
  )
}

function esPartidoEnCancha(valor: unknown): valor is PartidoEnCancha {
  const partido = valor as Partial<PartidoEnCancha> | null

  return (
    typeof partido?.id === 'string' &&
    typeof partido.estado === 'string' &&
    typeof partido.periodo?.desde === 'string' &&
    typeof partido.periodo.hasta === 'string' &&
    typeof partido.equipoLocal?.nombre === 'string' &&
    typeof partido.equipoVisitante?.nombre === 'string'
  )
}

/** Partidos de la extensión `partidosAfectados` de un error; `[]` si no aplica. */
export function partidosAfectadosDe(error: unknown): PartidoEnCancha[] {
  const partidos =
    error instanceof ApiError ? error.problema.extensiones?.partidosAfectados : undefined

  return Array.isArray(partidos) ? partidos.filter(esPartidoEnCancha) : []
}
