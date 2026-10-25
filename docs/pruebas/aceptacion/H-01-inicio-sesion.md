# Prueba de aceptación · H-01 Iniciar sesión y ver el panel con mis módulos permitidos

| Campo | Valor |
| --- | --- |
| Historia | H-01 (SCRUM-177) · subtarea H-01.4 (SCRUM-255) |
| Requisitos | RF-094, RNF-013, RNF-014, UI-001, UI-002, VAL-015 |
| Pantallas | F-05 (inicio de sesión), F-07 y F-08 (panel interno) |
| Versión probada | `main` en `6b38aa8` |
| Fecha | 2026-10-25 |
| Ejecutó | López Meza Leonardo (Scrum Master y responsable de calidad) |
| Resultado global | **Aprobado** (5 de 5 criterios) |

## 1. Entorno

| Componente | Configuración |
| --- | --- |
| Base de datos y autenticación | Proyecto de Supabase **SIGLIM**, migraciones `20261020090000` y `20261022143000` aplicadas |
| Backend | `./mvnw spring-boot:run` en `http://localhost:8080` con `backend/.env` |
| Frontend | `npm run dev` en `http://localhost:5173` (proxy de Vite hacia el backend) |
| Navegador | Google Chrome 155 en Windows 10/11 (x64) |

## 2. Cuentas de prueba

Las cuentas se identifican por su rol; sus correos no se publican en el repositorio.

| Cuenta | Rol y ámbito | Permisos efectivos (`GET /api/v1/yo`) | Barra lateral esperada |
| --- | --- | --- | --- |
| **Administrador** | Administrador general · Liga | 21 permisos: M-01, M-02, M-03, M-06, M-09, M-12 y avisos (M-14) | Inicio, Organización, Programación, Disciplina, Administración |
| **Capturista** | Capturista · Liga | `partidos.partido:CONSULTAR`, `partidos.cedula:CONSULTAR`, `partidos.cedula:CAPTURAR` (M-08) y `notificaciones.aviso:CONSULTAR` (M-14) | Inicio, Partidos |

La correspondencia entre secciones y módulos es la **[PROPUESTA]** de `frontend/src/layouts/navegacion.ts`
(PEN-014). Los avisos (M-14) no crean una sección: se consultan desde la campana (F-09).

## 3. Escenarios

### CA-1 · Inicio de sesión correcto

> Dado un usuario invitado y activo, cuando ingresa correo y contraseña correctos, entonces llega a
> `/app` y ve su nombre, rol y ámbito en la barra superior.

**Pasos**

1. Abrir `http://localhost:5173/login` sin sesión iniciada.
2. Escribir el correo y la contraseña de la cuenta **Capturista** y pulsar «Iniciar sesión».
3. Observar la URL y la barra superior.
4. Cerrar sesión y repetir los pasos 1 a 3 con la cuenta **Administrador**.

**Resultado esperado**

| Cuenta | URL | Barra superior |
| --- | --- | --- |
| Capturista | `/app` | «Capturista de prueba» · «Capturista · Liga» |
| Administrador | `/app` | «López Meza Leonardo» · «Administrador general · Liga» |

**Resultado obtenido:** **Aprobado.** Con ambas cuentas se llegó a `/app`; la barra superior mostró el
nombre, el rol y el ámbito esperados para cada una.

**Evidencia:** [`CA1-capturista.png`](evidencias/H-01/CA1-capturista.png),
[`CA1-administrador.png`](evidencias/H-01/CA1-administrador.png)

**Pruebas automáticas relacionadas**

- `InicioSesion.test.tsx` · «H-01.2: inicia sesión con Supabase y llega a /app»
- `InternalLayout.test.tsx` · «muestra el Menú Ejecutivo de F-07 y la identidad de la barra superior»
- `sesion.test.ts` · «H-01: muestra el rol y el ámbito de liga» y «muestra el nombre del club cuando el ámbito es de club»
- `YoControllerTest` · «RF-094: con token válido responde 200 con perfil, asignaciones y permisos, sin caché»

### CA-2 · Credenciales incorrectas sin revelar cuál falló

> Dado un correo o contraseña incorrectos, cuando intenta entrar, entonces ve «Correo o contraseña
> incorrectos» sin revelar cuál falló.

**Pasos**

1. En `/login`, escribir el correo de la cuenta **Capturista** con una contraseña incorrecta.
2. Escribir un correo **que no existe** (por ejemplo, `no-existe@ejemplo.mx`) con cualquier contraseña.
3. Comparar los dos mensajes.

**Resultado esperado:** en ambos casos aparece exactamente «Correo o contraseña incorrectos.», se
permanece en `/login` y el mensaje no indica si el correo existe.

**Resultado obtenido:** **Aprobado.** En los dos casos apareció «Correo o contraseña incorrectos.» y
se permaneció en `/login`; los mensajes fueron idénticos.

**Evidencia:** [`CA2-contrasena-incorrecta.png`](evidencias/H-01/CA2-contrasena-incorrecta.png),
[`CA2-correo-inexistente.png`](evidencias/H-01/CA2-correo-inexistente.png)

**Pruebas automáticas relacionadas**

- `InicioSesion.test.tsx` · «H-01.2: no revela si falló el correo o la contraseña»
- `autenticacion.test.ts` · «H-01.2: no revela si falló el correo o la contraseña»

### CA-3 · El Capturista solo ve los módulos de sus permisos

> Dado un usuario con rol Capturista, cuando abre el panel, entonces la barra lateral solo muestra
> los módulos de sus permisos según `GET /api/v1/yo`.

**Pasos**

1. Iniciar sesión como **Capturista** y observar la barra lateral (también en vista móvil, con el
   botón del menú).
2. Abrir las herramientas de desarrollador → **Red**, recargar `/app` y revisar la respuesta de
   `yo`.
3. Cerrar sesión, iniciar como **Administrador** y observar la barra lateral.

**Resultado esperado**

- Capturista: solo **Inicio** y **Partidos**; no aparece una sección de notificaciones.
- La respuesta de `/api/v1/yo` trae los 4 permisos de la tabla de cuentas y la cabecera
  `Cache-Control: no-store`.
- Administrador: **Inicio, Organización, Programación, Disciplina y Administración** (sin Partidos).

**Resultado obtenido:** **Aprobado.** El Capturista vio solo Inicio y Partidos, sin sección de
notificaciones. `GET /api/v1/yo` respondió `200 OK` con `Cache-Control: no-store`. El Administrador vio
Inicio, Organización, Programación, Disciplina y Administración, sin Partidos.

**Evidencia:** [`CA3-menu-capturista.png`](evidencias/H-01/CA3-menu-capturista.png),
[`CA3-respuesta-yo.png`](evidencias/H-01/CA3-respuesta-yo.png),
[`CA3-menu-administrador.png`](evidencias/H-01/CA3-menu-administrador.png)

**Pruebas automáticas relacionadas**

- `navegacion.test.ts` · «H-01.3: el Capturista solo ve Inicio y Partidos» y «un segundo rol ve las secciones de sus módulos»
- `navegacion.test.ts` · «H-01.3: las notificaciones no crean una sección aunque el módulo esté mapeado»
- `InternalLayout.test.tsx` · «H-01.3: el Capturista solo ve Inicio y Partidos, sin notificaciones»
- `YoRepositoryIT` · cuatro escenarios contra PostgreSQL real (asignaciones LIGA y CLUB, revocadas, otro perfil, permisos sin duplicados)

### CA-4 · Cerrar sesión elimina el token y protege `/app`

> Dada una sesión iniciada, cuando cierra sesión, entonces el token se elimina y `/app` redirige al
> inicio de sesión.

**Pasos**

1. Con sesión de **Capturista**, abrir las herramientas de desarrollador → **Aplicación** →
   **Almacenamiento local** → `http://localhost:5173` y comprobar que existe la clave
   `sb-…-auth-token`. **No capturar su valor.**
2. Pulsar «Cerrar sesión» en la barra superior.
3. Volver a revisar el almacenamiento local.
4. Escribir `http://localhost:5173/app` en la barra de direcciones.
5. Usar el botón «Atrás» del navegador.

**Resultado esperado**

- Tras el paso 2 se llega a `/login`.
- La clave `sb-…-auth-token` ya no existe.
- `/app` redirige a `/login`, también desde «Atrás».

**Resultado obtenido:** **Aprobado.** «Cerrar sesión» llevó a `/login`, la clave `sb-…-auth-token`
desapareció del almacenamiento local y `/app` redirigió a `/login`, también con «Atrás».

**Evidencia:** [`CA4-almacenamiento-sin-token.png`](evidencias/H-01/CA4-almacenamiento-sin-token.png),
[`CA4-redireccion-login.png`](evidencias/H-01/CA4-redireccion-login.png)

**Pruebas automáticas relacionadas**

- `InternalLayout.test.tsx` · «H-01.3: cierra la sesión y vuelve al inicio de sesión»
- `RutaProtegida.test.tsx` · «redirige al inicio de sesión cuando no hay sesión»
- `router.test.tsx` · «envía /app al inicio de sesión cuando no hay sesión»

### CA-5 · Sin registro libre, folio, proveedores externos ni 2FA

> La pantalla no ofrece registro libre, folio, proveedores externos ni 2FA.

**Pasos**

1. Abrir `/login` en vista de escritorio y en vista móvil (herramientas de desarrollador → modo
   dispositivo).
2. Revisar todos los controles, enlaces y textos; abrir «¿Olvidaste tu contraseña?».

**Resultado esperado:** solo hay correo, contraseña (con mostrar u ocultar), «¿Olvidaste tu
contraseña?», «Iniciar sesión», el aviso de cuentas por invitación y los enlaces al portal y al
aviso de privacidad. No hay registro, «Folio federativo», botones de Google u otros proveedores,
2FA ni «Mantener sesión activa» (DEC-48, Q-UI-01).

**Resultado obtenido:** **Aprobado.** En escritorio y en móvil la pantalla solo ofrece correo,
contraseña con mostrar u ocultar, «¿Olvidaste tu contraseña?», «Iniciar sesión», el aviso de cuentas
por invitación y los enlaces al portal y al aviso de privacidad.

**Evidencia:** [`CA5-inicio-sesion-escritorio.png`](evidencias/H-01/CA5-inicio-sesion-escritorio.png),
[`CA5-inicio-sesion-movil.png`](evidencias/H-01/CA5-inicio-sesion-movil.png)

**Pruebas automáticas relacionadas**

- `InicioSesion.test.tsx` · «H-01.2: muestra el formulario de F-05 sin folio, 2FA ni registro libre»

## 4. Resumen

| Criterio | Resultado |
| --- | --- |
| CA-1 Inicio de sesión correcto | Aprobado |
| CA-2 Credenciales incorrectas | Aprobado |
| CA-3 Barra lateral por permisos | Aprobado |
| CA-4 Cierre de sesión | Aprobado |
| CA-5 Sin registro, folio ni 2FA | Aprobado |

Pruebas automáticas de la versión probada: backend `./mvnw verify` con surefire 79/79 y failsafe
20/20; frontend `npm test` con 88/88.

## 5. Defectos encontrados

| ID | Defecto | Severidad | Afecta un criterio | Seguimiento |
| --- | --- | --- | --- | --- |
| D-01 | El inicio de sesión muestra «Correo o contraseña incorrectos» ante errores que no son de credenciales (404, 5xx). `mensajeDeErrorDeAcceso()` trata cualquier estado distinto de 429 y 0 como credenciales incorrectas | Baja | No: Supabase responde 400 ante credenciales incorrectas y el CA-2 se cumple | DEF-01 (SCRUM-364), Sprint 2 |

**Cómo se detectó (D-01).** Durante la preparación de la prueba, `VITE_SUPABASE_URL` del
`frontend/.env.local` local terminaba en `/rest/v1/`. Las peticiones a Supabase Auth iban a
`…/rest/v1/auth/v1/token` y `…/rest/v1/auth/v1/recover` y recibían **404** (registros *edge* del
proyecto). El inicio de sesión respondió «Correo o contraseña incorrectos» con la contraseña correcta
y la recuperación respondió «No pudimos enviar el enlace». Se corrigió la variable a
`https://<ref>.supabase.co` y la prueba se ejecutó después de la corrección.

## 6. Observaciones para siguientes sprints

Comportamientos fuera de los criterios de H-01, detectados en la revisión de código:

1. **El menú no es barrera de acceso.** Un usuario puede abrir a mano una sección que no ve en el
   menú (por ejemplo, `/app/administracion` como Capturista). Hoy solo muestra «En construcción» y
   el backend vuelve a autorizar cada operación (VAL-015), pero conviene proteger también las rutas.
2. **Cierre de sesión en otra pestaña.** `RutaProtegida` no escucha el evento `SIGNED_OUT`: otra
   pestaña abierta se entera en su siguiente petición, cuando `/yo` responde 401 y redirige.

## 7. Conclusión

La historia **H-01 cumple sus cinco criterios de aceptación** sobre `main` en `6b38aa8`, con frontend,
backend y base de datos reales y dos roles distintos. Las pruebas automáticas de la misma versión
pasan en su totalidad. El único defecto encontrado (D-01) es de severidad baja, no afecta ningún
criterio y queda registrado para el Sprint 2 (SCRUM-364). La H-01 puede pasar a «Finalizado».
