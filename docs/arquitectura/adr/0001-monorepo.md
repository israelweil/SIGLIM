# ADR-0001: Usar un monorepo para frontend, backend, base de datos y documentación

- **Estado:** Aceptada
- **Fecha:** 2026-10-13
- **Responsables:** Equipo SIGLIM
- **Trazabilidad:** DD-002, ERS 2.4 (10 semanas, 3 integrantes)

## Contexto
El equipo es de tres personas, con un solo producto que tiene dos caras (portal público y
aplicación interna) y un backend. Los requisitos, el esquema SQL y el código cambian juntos: un
RF nuevo suele tocar migración, endpoint y pantalla. Además, los agentes de IA necesitan ver la
documentación junto al código para respetar los requisitos.

## Decisión
Un único repositorio con cuatro raíces: `docs/` (fuente de verdad), `supabase/` (esquema),
`backend/` (Spring Boot) y `frontend/` (React). Cada proyecto se construye de forma
independiente con su propia herramienta (`mvnw`, `npm`).

## Alternativas consideradas
- **Repositorios separados por capa:** aíslan permisos y pipelines, pero obligan a coordinar
  versiones y PR entre repos; demasiado costo para tres personas en 10 semanas.
- **Frontend servido por Spring Boot (un solo artefacto):** simplifica el despliegue, pero acopla
  los ciclos de compilación y complica el trabajo en paralelo. Puede reconsiderarse al definir el
  despliegue (PEN-036, PEN-037).

## Consecuencias
- Un PR puede incluir migración + backend + frontend + documentación de una misma historia.
- Cada subproyecto tiene su propio `README.md` y `AGENTS.md` con reglas específicas.
- Si se agrega CI, debe filtrar por ruta (`frontend/**`, `backend/**`) para no compilar todo.
