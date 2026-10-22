package mx.tecnm.morelia.siglim.seguridad;

import java.util.Optional;
import java.util.UUID;
import mx.tecnm.morelia.siglim.compartido.contexto.ResolutorPerfil;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Busca el perfil de SIGLIM de una cuenta de Supabase Auth al autenticar cada petición.
 *
 * <p><b>Única consulta que corre fuera del contexto de usuario.</b> Se ejecuta antes de que exista
 * un perfil que fijar en la transacción (es justo lo que averigua), con el usuario de conexión del
 * backend, que en Supabase es dueño de las tablas y tiene {@code BYPASSRLS}. Por eso la consulta
 * es fija, parametrizada y solo devuelve {@code id} y {@code activo}. Todo lo demás del backend
 * corre en transacciones con {@code siglim_app} o {@code siglim_publico} (ADR-0014).
 *
 * <p>El esquema va calificado ({@code siglim.perfiles}) porque fuera de una transacción no se fija
 * {@code search_path}.
 *
 * <p>Refs: T-02.3, ADR-0003 punto 6, ADR-0014
 */
@Repository
class ResolutorPerfilJdbc implements ResolutorPerfil {

    private final JdbcClient jdbc;

    ResolutorPerfilJdbc(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<PerfilSesion> buscarPorUsuarioAuth(UUID usuarioAuthId) {
        return jdbc.sql("""
                        SELECT id, activo
                          FROM siglim.perfiles
                         WHERE usuario_auth_id = :usuarioAuthId
                        """)
                .param("usuarioAuthId", usuarioAuthId)
                .query(PerfilSesion.class)
                .optional();
    }
}
