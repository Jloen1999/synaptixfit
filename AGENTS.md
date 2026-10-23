# AGENTS.md — SynaptixFit

Las instrucciones para agentes de código están en [`CLAUDE.md`](CLAUDE.md) (raíz) y en los `CLAUDE.md` de `backend/`, `frontend/` y de cada capa. Este archivo solo existe para las herramientas que buscan `AGENTS.md`.

Resumen:

- **Arquitectura limpia** (`docs/01-architecture/core.md`): backend Spring Boot hexagonal en `backend/` y cliente Flutter + BLoC en `frontend/`. Ya no se usa Supabase (ADR 0004).
- **Antes de terminar:** `cd backend && ./mvnw test -Pintegration` y `cd frontend && flutter analyze && flutter test`.
- **Errores:** RFC 9457 con `code`; catálogo en `docs/03-api/errors.md`.
- **Git:** nunca hacer commit ni push sin que el usuario lo pida tras probar; mensajes en español con Conventional Commits (`feat: [Módulo] Descripción`); rama `master`.
- **Idioma:** código en inglés; comentarios y documentación en español.
