package mx.tecnm.morelia.siglim.seguridad;

import java.util.Collection;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

/**
 * A quién pertenece el recurso sobre el que se evalúa un permiso: los clubes involucrados y, para
 * el ámbito propio, las personas titulares (ADR-0007 §2).
 *
 * <p>Lo construye el módulo dueño del recurso y lo entrega a {@link Autorizacion#exigir}. Un
 * partido lleva los dos clubes; el registro de un jugador, su club y su persona; la consulta de un
 * jugador o de su tutor, la persona del jugador o la del menor; una designación, la persona del
 * árbitro.
 *
 * <p>Un objetivo sin clubes ni personas ({@link #deLiga()}) solo lo autoriza el ámbito
 * {@code LIGA}: al no pertenecer a ningún club, el ámbito de club no lo alcanza.
 *
 * <p>Las colecciones no admiten {@code null} y descartan los elementos repetidos.
 *
 * <p>Refs: H-02.1, RF-094, RN-054, VAL-015, VAL-024, ADR-0007
 */
public record ObjetivoAutorizacion(Set<UUID> clubes, Set<UUID> personas) {

    public ObjetivoAutorizacion {
        clubes = Set.copyOf(Objects.requireNonNull(clubes, "clubes"));
        personas = Set.copyOf(Objects.requireNonNull(personas, "personas"));
    }

    /** Recurso de toda la liga: temporadas, categorías, grupos y catálogos. */
    public static ObjetivoAutorizacion deLiga() {
        return new ObjetivoAutorizacion(Set.of(), Set.of());
    }

    /** Recurso de uno o varios clubes: un partido pertenece al club local y al visitante. */
    public static ObjetivoAutorizacion deClubes(UUID... clubes) {
        return new ObjetivoAutorizacion(sinRepetidos(clubes), Set.of());
    }

    /** Recurso de una o varias personas: el jugador, el menor bajo tutela o el árbitro. */
    public static ObjetivoAutorizacion dePersonas(UUID... personas) {
        return new ObjetivoAutorizacion(Set.of(), sinRepetidos(personas));
    }

    /** Recurso que pertenece a clubes y a personas a la vez, como un registro de jugador. */
    public static ObjetivoAutorizacion deClubesYPersonas(Collection<UUID> clubes, Collection<UUID> personas) {
        return new ObjetivoAutorizacion(Set.copyOf(clubes), Set.copyOf(personas));
    }

    private static Set<UUID> sinRepetidos(UUID... ids) {
        return Set.copyOf(List.of(ids));
    }
}
