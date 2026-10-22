import { TriangleAlert } from 'lucide-react'
import { Insignia } from '@/components/ui/Insignia'

/**
 * Rótulo de los valores `[DEMO]` que la Liga aún no aprueba (puntos, desempates,
 * plazos…): se muestran como configuración «no oficial» (AGENTS.md §3).
 */
export function InsigniaNoOficial() {
  return (
    <Insignia variante="advertencia" icono={TriangleAlert}>
      No oficial
    </Insignia>
  )
}
