package mx.tecnm.morelia.siglim.compartido.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import mx.tecnm.morelia.siglim.compartido.error.ProblemaHttp;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

/**
 * Responde {@code 401} con {@code codigo: "NO_AUTENTICADO"} en formato RFC 9457 cuando una
 * petición a una ruta protegida llega sin token o con un token vencido o inválido (convenciones de
 * API §3.1).
 *
 * <p>Siempre responde 401, incluso con una cabecera {@code Authorization} mal formada (Spring
 * respondería 400): para el frontend, cualquiera de estos casos significa «vuelve a iniciar
 * sesión». La cabecera {@code WWW-Authenticate} sigue RFC 6750 sin describir la causa, para no
 * dar pistas a quien prueba tokens falsificados; la causa solo va a la bitácora en nivel DEBUG y
 * nunca incluye el token (RNF-011).
 *
 * <p>También responde 401 cuando el token es válido pero la cuenta no tiene un perfil activo en
 * SIGLIM (ADR-0003 punto 6; decisión del equipo del 22 de octubre de 2026), para que el frontend
 * cierre la sesión. El mensaje no distingue «sin perfil» de «perfil desactivado», para no revelar
 * qué cuentas existen.
 *
 * <p>Refs: T-02.2, T-02.3, RNF-003, VAL-015
 */
@Component
public class PuntoEntradaNoAutenticado implements AuthenticationEntryPoint {

    private static final Logger log = LoggerFactory.getLogger(PuntoEntradaNoAutenticado.class);

    static final String CODIGO = "NO_AUTENTICADO";
    static final String DETALLE_SIN_TOKEN = "Inicia sesión para continuar.";
    static final String DETALLE_TOKEN_INVALIDO =
            "Tu sesión expiró o no es válida. Vuelve a iniciar sesión.";
    static final String DETALLE_CUENTA_NO_ACTIVA =
            "Tu cuenta no está activa en SIGLIM. Si crees que es un error, contacta al administrador de la liga.";

    private final JsonMapper json;

    public PuntoEntradaNoAutenticado(JsonMapper json) {
        this.json = json;
    }

    @Override
    public void commence(HttpServletRequest peticion, HttpServletResponse respuesta,
            AuthenticationException causa) throws IOException {
        boolean cuentaNoActiva = causa instanceof DisabledException;
        boolean conToken = cuentaNoActiva || causa instanceof OAuth2AuthenticationException;
        if (conToken) {
            log.debug("Token rechazado en {} {}: {}", peticion.getMethod(), peticion.getRequestURI(),
                    causa.getMessage());
        }

        String detalle = cuentaNoActiva ? DETALLE_CUENTA_NO_ACTIVA
                : conToken ? DETALLE_TOKEN_INVALIDO : DETALLE_SIN_TOKEN;
        ProblemDetail problema = ProblemaHttp.crear(HttpStatus.UNAUTHORIZED, CODIGO, "No autenticado",
                detalle, peticion.getRequestURI());

        respuesta.setStatus(HttpStatus.UNAUTHORIZED.value());
        respuesta.setHeader(HttpHeaders.WWW_AUTHENTICATE, conToken ? "Bearer error=\"invalid_token\"" : "Bearer");
        respuesta.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        respuesta.setCharacterEncoding("UTF-8");
        json.writeValue(respuesta.getOutputStream(), ProblemaHttp.comoMapa(problema));
    }
}
