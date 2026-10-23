import type { ErrorCampo, Problema } from '@/lib/api/tipos'

/**
 * Error HTTP de la API con el problema RFC 9457 completo (convenciones §3).
 * El tratamiento se decide por `problema.codigo`, nunca por el texto.
 */
export class ApiError extends Error {
  readonly problema: Problema

  constructor(problema: Problema) {
    super(problema.detail || problema.title)
    this.name = 'ApiError'
    this.problema = problema
  }

  get codigo(): string {
    return this.problema.codigo
  }

  get estado(): number {
    return this.problema.status
  }

  get errores(): ErrorCampo[] {
    return this.problema.errores ?? []
  }

  /** Mensaje del campo señalado, para marcar los campos de un formulario. */
  mensajeDe(campo: string): string | undefined {
    return this.errores.find((error) => error.campo === campo)?.mensaje
  }
}
