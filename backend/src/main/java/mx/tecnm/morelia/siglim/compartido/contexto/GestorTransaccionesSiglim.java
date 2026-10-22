package mx.tecnm.morelia.siglim.compartido.contexto;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Optional;
import javax.sql.DataSource;
import org.springframework.jdbc.support.JdbcTransactionManager;
import org.springframework.transaction.TransactionDefinition;

/**
 * Administrador de transacciones que fija el contexto de usuario en PostgreSQL al iniciar cada
 * transacción (ADR-0005, ADR-0014). Es el único lugar donde se hace: ningún repositorio lo repite.
 *
 * <p>Con sesión autenticada ({@link AutenticacionSiglim}):
 * <pre>{@code
 * SELECT set_config('request.jwt.claims', '{"sub":"<auth uuid>","perfil_id":"<perfil uuid>"}', true);
 * SET LOCAL search_path TO siglim;
 * SET LOCAL ROLE siglim_app;          -- sujeto a RLS por ámbito
 * }</pre>
 * Sin sesión (portal público, o cualquier transacción sin usuario) se adopta
 * {@code siglim_publico}, que solo lee las vistas {@code v_publica_*}: si un código olvida exigir
 * sesión, la base de datos niega en lugar de exponer datos.
 *
 * <p><b>Por qué {@code SET LOCAL} y {@code set_config(..., true)}:</b> duran solo la transacción.
 * El pooler de Supabase en modo transacción reparte la misma conexión física entre peticiones de
 * distintos usuarios; un {@code SET} de sesión se filtraría al siguiente. Por la misma razón el
 * {@code search_path} se fija aquí y no con {@code currentSchema} en la URL.
 *
 * <p>Las transacciones de solo lectura ({@code readOnly = true}) también se fuerzan en la base de
 * datos con {@code SET TRANSACTION READ ONLY}.
 *
 * <p>Refs: T-02.3, RNF-003, RN-021, ADR-0005, ADR-0014
 */
public class GestorTransaccionesSiglim extends JdbcTransactionManager {

    static final String ROL_APLICACION = "siglim_app";
    static final String ROL_PUBLICO = "siglim_publico";

    public GestorTransaccionesSiglim(DataSource fuenteDatos) {
        super(fuenteDatos);
        setEnforceReadOnly(true);
    }

    @Override
    protected void prepareTransactionalConnection(Connection conexion, TransactionDefinition definicion)
            throws SQLException {
        // Primero SET TRANSACTION READ ONLY, que debe ir antes de cualquier consulta.
        super.prepareTransactionalConnection(conexion, definicion);

        Optional<AutenticacionSiglim> sesion = UsuarioActual.autenticacion();
        fijarClaims(conexion, sesion.map(GestorTransaccionesSiglim::claims).orElse(""));
        try (Statement sentencia = conexion.createStatement()) {
            sentencia.execute("SET LOCAL search_path TO siglim");
            // Los nombres de rol son constantes: SET ROLE no admite parámetros.
            sentencia.execute("SET LOCAL ROLE " + (sesion.isPresent() ? ROL_APLICACION : ROL_PUBLICO));
        }
    }

    /**
     * Claims que leen {@code siglim.usuario_actual()} y las políticas RLS. Solo contienen UUID ya
     * validados, así que el JSON se arma sin riesgo de inyección.
     */
    static String claims(AutenticacionSiglim sesion) {
        return "{\"sub\":\"" + sesion.usuarioAuthId() + "\",\"perfil_id\":\"" + sesion.perfilId() + "\"}";
    }

    private static void fijarClaims(Connection conexion, String claims) throws SQLException {
        try (PreparedStatement sentencia =
                     conexion.prepareStatement("SELECT set_config('request.jwt.claims', ?, true)")) {
            sentencia.setString(1, claims);
            sentencia.execute();
        }
    }
}
