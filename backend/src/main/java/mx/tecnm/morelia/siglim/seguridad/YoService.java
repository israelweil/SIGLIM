package mx.tecnm.morelia.siglim.seguridad;

import java.util.List;
import java.util.UUID;
import mx.tecnm.morelia.siglim.compartido.contexto.UsuarioActual;
import mx.tecnm.morelia.siglim.seguridad.YoDto.AsignacionDto;
import mx.tecnm.morelia.siglim.seguridad.YoDto.ClubDto;
import mx.tecnm.morelia.siglim.seguridad.YoDto.RolDto;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Lo que la interfaz sabe del usuario actual: perfil, asignaciones de rol activas con su ámbito y
 * permisos efectivos.
 *
 * <p>Solo exige sesión (decisión del equipo para H-01.1): cada quien consulta lo suyo y el perfil
 * sale siempre del token, nunca de la petición. Se lee en cada petición, sin caché, para que un
 * cambio de permisos surta efecto de inmediato (ADR-0007 §2).
 *
 * <p>Refs: H-01.1, RF-094, ADR-0007
 */
@Service
public class YoService {

    private final YoRepository repositorio;

    YoService(YoRepository repositorio) {
        this.repositorio = repositorio;
    }

    @Transactional(readOnly = true)
    public YoDto consultar() {
        UUID perfilId = UsuarioActual.idRequerido();
        List<AsignacionDto> asignaciones = repositorio.listarAsignacionesActivas(perfilId).stream()
                .map(YoService::aDto)
                .toList();
        return new YoDto(repositorio.buscarPerfil(perfilId), asignaciones,
                repositorio.listarPermisosEfectivos(perfilId));
    }

    private static AsignacionDto aDto(YoRepository.FilaAsignacion fila) {
        ClubDto club = fila.clubId() == null ? null : new ClubDto(fila.clubId(), fila.clubNombre());
        return new AsignacionDto(fila.id(), new RolDto(fila.rolCodigo(), fila.rolNombre()), fila.ambito(), club);
    }
}
