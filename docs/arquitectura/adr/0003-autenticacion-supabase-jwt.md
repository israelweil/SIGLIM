# ADR-0003: Autenticar con Supabase Auth y validar el JWT en el backend

- **Estado:** Propuesta — depende de PEN-030 (política de sesión y contraseñas)
- **Fecha:** 2026-10-13
- **Responsables:** Equipo SIGLIM
- **Trazabilidad:** RNF-003, RNF-013, RNF-014, UI-001, DD-009, VAL-015

## Contexto
La arquitectura delega credenciales a Supabase Auth (`auth.users`) para no almacenar
contraseñas propias (RNF-013). El backend debe aplicar denegación por defecto por rol y acción.

## Decisión
1. El **frontend** inicia sesión con `@supabase/supabase-js` y obtiene el `access_token` (JWT).
   Es el **único** uso del cliente de Supabase en el frontend: los datos siempre se piden al
   backend.
2. El **backend** es un *OAuth2 Resource Server* (`spring-boot-starter-security-oauth2-resource-server`)
   que valida firma, expiración y emisor del JWT con el JWKS del proyecto:
   - `jwk-set-uri`: `https://<proyecto>.supabase.co/auth/v1/.well-known/jwks.json`
   - `issuer-uri` esperado: `https://<proyecto>.supabase.co/auth/v1`
   - Requiere que el proyecto use **claves de firma asimétricas** (*JWT Signing Keys*). Con la
     clave secreta heredada HS256 el JWKS viene vacío y Supabase desaconseja validarla localmente.
3. Los **roles no se leen del JWT**: el backend obtiene los roles de `perfil_roles` a partir del
   `sub` del token, para que un cambio de rol surta efecto sin esperar a que expire la sesión.
4. Rutas `/api/v1/publico/**` sin autenticación; todo lo demás autenticado y autorizado por
   permiso (`modulo:accion`).

## Alternativas consideradas
- **Autenticación propia en Spring (usuarios + BCrypt):** más control, pero duplica lo que
  Supabase ya ofrece y añade riesgos de seguridad.
- **Validar llamando a `/auth/v1/user` en cada petición:** funciona con HS256 pero agrega
  latencia y dependencia de red en cada solicitud.

## Consecuencias
- El frontend nunca envía contraseñas al backend.
- Pendiente: duración de sesión, recuperación de acceso y límite de intentos (PEN-030, PEN-029).
