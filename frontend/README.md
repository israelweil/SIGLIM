# SIGLIM · Frontend

Aplicación web de SIGLIM: **portal público** de solo lectura y **aplicación interna** autenticada.
React 19, TypeScript, Vite, Tailwind CSS 4, React Router y TanStack Query.
Reglas para agentes de IA: [`AGENTS.md`](AGENTS.md).

## Requisitos

- Node.js 22 LTS o superior (`node -v`).
- Backend corriendo en `http://localhost:8080` para ver datos reales.

## Configuración

```bash
cp .env.example .env.local    # Windows: copy .env.example .env.local
```

| Variable | Descripción |
| --- | --- |
| `VITE_SUPABASE_URL` | URL del proyecto de Supabase |
| `VITE_SUPABASE_PUBLISHABLE_KEY` | Clave pública (*publishable* o *anon*). Nunca la `service_role` |
| `VITE_API_URL` | Base del API; por defecto `/api/v1` (proxy de Vite al backend) |

Para la recuperación de contraseña, agrega `<origen>/restablecer-contrasena` a las **Redirect URLs**
permitidas en Supabase Auth (por ejemplo, `http://localhost:5173/restablecer-contrasena` en
desarrollo).

## Scripts

| Comando | Qué hace |
| --- | --- |
| `npm run dev` | Servidor de desarrollo en <http://localhost:5173> |
| `npm run build` | Verificación de tipos y compilación de producción en `dist/` |
| `npm run lint` | Análisis estático con oxlint |
| `npm test` | Pruebas con Vitest |
| `npm run preview` | Sirve la compilación de producción |

## Rutas

| Ruta | Pantalla | Acceso |
| --- | --- | --- |
| `/`, `/resultados`, `/tabla` | Portal público (UI-020) | Público |
| `/aviso-de-privacidad` | Aviso de privacidad (UI-033) | Público |
| `/login` | Inicio de sesión (UI-001) | Público |
| `/restablecer-contrasena` | Restablecer contraseña con el enlace de Supabase Auth | Público con enlace válido |
| `/app/**` | Aplicación interna por módulo | Sesión iniciada |
