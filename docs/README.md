# Documentación de SIGLIM

Índice de la documentación técnica del proyecto. Si eres una persona nueva en el equipo o un
agente de IA, léela en el orden de la tabla.

## Mapa de documentos

| # | Documento | Para qué sirve | Cuándo consultarlo |
| --- | --- | --- | --- |
| 1 | [`requisitos/ERS.md`](requisitos/ERS.md) | Especificación de requisitos (IEEE 830): RF, RNF, reglas de negocio (RN), casos de uso (CU), validaciones (VAL), alcance y pendientes. | Antes de implementar cualquier funcionalidad. Es la **fuente de verdad** de *qué* hace el sistema. |
| 2 | [`arquitectura/arquitectura-y-diseno-jerarquico.md`](arquitectura/arquitectura-y-diseno-jerarquico.md) | Diagrama HIPO de módulos M-xx, tabla módulo → RF, diagramas IPO y arquitectura en capas con decisiones justificadas. | Para saber en qué módulo y capa vive un cambio. |
| 3 | [`arquitectura/convenciones-api.md`](arquitectura/convenciones-api.md) | Contrato REST entre frontend y backend: rutas, DTO, errores, paginación, seguridad. | Al crear o consumir un endpoint. |
| 4 | [`arquitectura/adr/`](arquitectura/adr/) | Registros de decisiones de arquitectura (ADR): qué se decidió, por qué y qué sigue abierto. | Antes de cambiar una decisión técnica. |
| 5 | [`base-de-datos/diccionario-de-datos.md`](base-de-datos/diccionario-de-datos.md) | Tablas, columnas, restricciones, índices, RLS, triggers, funciones y trazabilidad ERS → BD. | Al escribir SQL, repositorios o DTO. |
| 6 | [`../supabase/migrations/`](../supabase/migrations/) | Script SQL ejecutable del esquema (PostgreSQL / Supabase). | Para crear o modificar la base de datos. |
| 7 | [`diseno-ui/README.md`](diseno-ui/README.md) | Sistema de diseño: tipografía, colores y tokens, componentes, layouts, responsive, accesibilidad y decisiones abiertas. | Al construir pantallas en React. |
| 8 | [`requisitos/bpmn/`](requisitos/bpmn/) | Diagramas BPMN de los procesos del sistema (P-xx), en DOCX y PDF. | Para entender el flujo de un proceso antes de implementarlo. |
| 9 | [`arquitectura/figuras/`](arquitectura/figuras/) | Figuras 1 a 8 de la arquitectura (HIPO, IPO, componentes), enlazadas desde el documento de arquitectura. | Junto con el documento 2. |
| — | [`requisitos/historico/`](requisitos/historico/) y [`base-de-datos/historico/`](base-de-datos/historico/) | Versiones anteriores **reemplazadas** (ERS Rev. 0.1, revisión del Equipo 3, extracción del PDF, diccionario original). Solo como referencia histórica. | Nunca para implementar. |
| 10 | [`requisitos/decisiones/registro-de-decisiones.md`](requisitos/decisiones/registro-de-decisiones.md) | Decisiones posteriores al ERS Rev. 0.3 (DEC-xx), con origen y estado. Prevalecen sobre el ERS hasta la Rev. 0.4. | Antes de usar el ERS Rev. 0.3. |
| — | [`requisitos/fuentes/`](requisitos/fuentes/) y [`arquitectura/originales/`](arquitectura/originales/) | Documentación técnica base, transcripción del levantamiento (R2), formatos de carta del cliente y DOCX original de arquitectura. | Para rastrear de dónde salió un requisito o una figura. |

## Jerarquía de fuentes de verdad

Cuando dos documentos se contradicen, manda el de mayor nivel:

```text
1. ERS (requisitos/ERS.md)                     ← qué debe hacer el sistema y qué NO
2. ADR aceptados + arquitectura                ← cómo se organiza
3. Migraciones SQL + diccionario de datos      ← cómo se guardan los datos
4. Convenciones de API                         ← cómo se comunican front y back
5. Diseño UI                                   ← cómo se ve
```

Ejemplo: el diseño UI menciona un *buscador global*, pero el ERS (RF-089) dice explícitamente
"sin buscador general". **Gana el ERS**: no se implementa el buscador. Los conflictos conocidos
están listados en [`diseno-ui/open-design-decisions.md`](diseno-ui/open-design-decisions.md).

## Identificadores que verás en todos los documentos

| Prefijo | Significado | Definido en |
| --- | --- | --- |
| `RF-xxx` / `RNF-xxx` | Requisito funcional / no funcional | ERS §3.2 / §3.3 |
| `RN-xxx` | Regla de negocio | ERS §3.4.1 |
| `CU-xxx` | Caso de uso | ERS §4.1 |
| `VAL-xxx` | Validación y comportamiento ante fallo | ERS §3.2.10 |
| `UI-xxx` | Pantalla propuesta | ERS §3.1.1 |
| `P-xx` | Proceso BPMN | ERS §4.2 |
| `M-xx` / `M-xx.n` | Módulo / submódulo | ERS §2.2 y arquitectura §1 |
| `DD-xxx` / `DP-xxx` | Decisión / propuesta de diseño | ERS §2.4 |
| `PEN-xxx` / `Q-xx` | Pendiente / pregunta abierta | ERS Apéndices A y C |
| `ADR-xxxx` | Decisión de arquitectura del equipo | `arquitectura/adr/` |

Úsalos en ramas, commits, PR, comentarios de código y pruebas para mantener la trazabilidad.

## Cómo mantener la documentación

- Un cambio de requisito se hace **primero en el ERS** y después en código.
- Un cambio de esquema se hace con **una nueva migración** en `supabase/migrations/` y se refleja
  en el diccionario de datos en el mismo PR.
- Una decisión técnica nueva o revertida se registra como ADR.
- No dupliques contenido: enlaza al documento que ya lo define.
