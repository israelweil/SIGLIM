package mx.tecnm.morelia.siglim.seguridad;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import mx.tecnm.morelia.siglim.compartido.contexto.AutenticacionSiglim;
import mx.tecnm.morelia.siglim.seguridad.YoDto.AsignacionDto;
import mx.tecnm.morelia.siglim.seguridad.YoDto.ClubDto;
import mx.tecnm.morelia.siglim.seguridad.YoDto.PerfilDto;
import mx.tecnm.morelia.siglim.seguridad.YoDto.PermisoDto;
import mx.tecnm.morelia.siglim.seguridad.YoDto.RolDto;
import mx.tecnm.morelia.siglim.seguridad.YoRepository.FilaAsignacion;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;

/** Armado de la respuesta de {@code GET /api/v1/yo}. Sin Spring ni BD. */
class YoServiceTest {

    private static final UUID PERFIL = UUID.fromString("0b7c3e1a-2d4f-4a6b-9c8d-7e6f5a4b3c2d");
    private static final UUID ASIGNACION_LIGA = UUID.fromString("11111111-1111-4111-8111-111111111111");
    private static final UUID ASIGNACION_CLUB = UUID.fromString("22222222-2222-4222-8222-222222222222");
    private static final UUID CLUB = UUID.fromString("33333333-3333-4333-8333-333333333333");

    private final YoRepository repositorio = mock(YoRepository.class);
    private final YoService servicio = new YoService(repositorio);

    @AfterEach
    void cerrarSesion() {
        SecurityContextHolder.clearContext();
    }

    private static void iniciarSesion(UUID perfil) {
        Jwt token = Jwt.withTokenValue("token-de-prueba")
                .header("alg", "ES256")
                .subject(UUID.randomUUID().toString())
                .issuedAt(Instant.now())
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();
        SecurityContextHolder.getContext().setAuthentication(new AutenticacionSiglim(token, perfil));
    }

    @Test
    @DisplayName("RF-094: arma perfil, asignaciones con rol y club, y permisos del perfil de la sesión")
    void armaLaRespuesta() {
        iniciarSesion(PERFIL);
        PerfilDto perfil = new PerfilDto(PERFIL, "Ana López", "ana@prueba.mx");
        List<PermisoDto> permisos = List.of(
                new PermisoDto("partidos.partido:CONSULTAR", "M-08", "LIGA", null),
                new PermisoDto("registros.registro:EDITAR", "M-04", "CLUB", CLUB));
        given(repositorio.buscarPerfil(PERFIL)).willReturn(perfil);
        given(repositorio.listarAsignacionesActivas(PERFIL)).willReturn(List.of(
                new FilaAsignacion(ASIGNACION_LIGA, "PROGRAMADOR", "Programador de partidos", "LIGA", null, null),
                new FilaAsignacion(ASIGNACION_CLUB, "DIRECTIVA_CLUB", "Directiva de club", "CLUB", CLUB,
                        "Club Halcones")));
        given(repositorio.listarPermisosEfectivos(PERFIL)).willReturn(permisos);

        YoDto yo = servicio.consultar();

        assertThat(yo.perfil()).isEqualTo(perfil);
        assertThat(yo.asignaciones()).containsExactly(
                new AsignacionDto(ASIGNACION_LIGA, new RolDto("PROGRAMADOR", "Programador de partidos"), "LIGA", null),
                new AsignacionDto(ASIGNACION_CLUB, new RolDto("DIRECTIVA_CLUB", "Directiva de club"), "CLUB",
                        new ClubDto(CLUB, "Club Halcones")));
        assertThat(yo.permisos()).isEqualTo(permisos);
    }

    @Test
    @DisplayName("H-01.1: sin asignaciones activas responde listas vacías")
    void sinAsignaciones() {
        iniciarSesion(PERFIL);
        given(repositorio.buscarPerfil(PERFIL)).willReturn(new PerfilDto(PERFIL, "Ana López", null));
        given(repositorio.listarAsignacionesActivas(PERFIL)).willReturn(List.of());
        given(repositorio.listarPermisosEfectivos(PERFIL)).willReturn(List.of());

        YoDto yo = servicio.consultar();

        assertThat(yo.asignaciones()).isEmpty();
        assertThat(yo.permisos()).isEmpty();
    }

    @Test
    @DisplayName("H-01.1: sin sesión es un error de programación y no consulta la base de datos")
    void sinSesion() {
        assertThatThrownBy(servicio::consultar).isInstanceOf(IllegalStateException.class);
        verifyNoInteractions(repositorio);
    }
}
