# SynaptixFit

Aplicación para estudiantes universitarios que equilibra la carga académica y el entrenamiento físico: planificación de estudio, repaso espaciado con IA, rutinas de entrenamiento, retos, insignias y regulación cruzada entre fatiga cognitiva y física.

## Stack de este proyecto

| Parte | Carpeta | Perfil de arquitectura |
|---|---|---|
| Frontend | `frontend/` | `docs/01-architecture/profiles/frontend-flutter-bloc.md` |
| Backend | `backend/` | `docs/01-architecture/profiles/backend-spring-hexagonal.md` |

Cada carpeta tiene su propio `CLAUDE.md` con lo específico de su stack. Base de datos: PostgreSQL 17 (`docker-compose.yml`). Servicios externos: DeepSeek (IA), Cloudflare R2 (archivos), Google Sign-In; solo el backend los llama.

## Reglas que nunca se rompen

1. El dominio no depende de nada: ni frameworks, ni BD, ni red, ni UI.
2. Las dependencias siempre apuntan hacia el dominio. Se inyecta contra contratos, nunca contra clases concretas.
3. Los errores cruzan las fronteras traducidos. Entre sistemas viajan como RFC 9457 con un campo `code` del catálogo.
4. Un caso de uso = una acción.
5. Lo generado no se edita a mano: OpenAPI, código de `build_runner`, traducciones (`app_es.arb`) y tokens de diseño (`tokens.g.dart`).
6. Las reglas de negocio viven en el backend, nunca en triggers SQL ni en el cliente.

## Dónde buscar (lee solo lo que necesites)

| Necesito… | Leer |
|---|---|
| Entender los roles y la regla de dependencia | `docs/01-architecture/core.md` |
| Saber dónde va un archivo en un stack | El perfil de la tabla de arriba |
| Quién es dueño de cada tabla | `docs/01-architecture/data_model.md` |
| Cómo se comunican los módulos del backend | `docs/01-architecture/events.md` |
| Fórmulas (carga cognitiva, ACWR, kcal, SM-2) y sus fuentes | `docs/01-architecture/formulas.md` |
| Añadir o traducir un error | `docs/03-api/errors.md` |
| Ver los endpoints | `docs/03-api/openapi.yaml` (generado) |
| Saber por qué se decidió algo | `docs/02-adr/` |
| Pasos para una feature completa | `docs/04-guides/new_feature.md` |
| Arrancar el entorno | `docs/04-guides/onboarding.md` |
| Base de datos de producción (Coolify, credenciales, copias) | `docs/06-ops/database.md` y `REQUISITOS-INFRA.md` |

## Al añadir una funcionalidad

Trabaja de dentro hacia fuera: dominio → caso de uso → adaptador de salida → adaptador de entrada → composición. Primero el backend, después el cliente.

En el mismo cambio:
- Los `code` de error nuevos van al catálogo `docs/03-api/errors.md`, con su texto en el cliente.
- Se actualiza la documentación que haya quedado desfasada.

## Comunicación, comentarios y conocimiento

- **Respuestas en español y sencillas.** Al cerrar una tarea: qué se hizo, por qué así, cómo repetirlo (pasos y comandos exactos), cómo comprobarlo y qué queda pendiente. Si algo falló, la causa real y cómo se arregló.
- **Comentarios en el código, en español y sin exagerar:** cabecera de una o dos líneas en cada clase pública (qué papel cumple y con qué se relaciona) y el porqué de reglas, fórmulas y decisiones no obvias. Nada de comentarios evidentes ni código comentado.
- **Bóveda de conocimiento (Obsidian):** `C:\Users\JLOel\Documents\Obsidian\Knowledge`. Tras una tarea relevante, registra ahí lo aprendido con sus plantillas (`Templates/`): conceptos en `01 - Conceptos/`, procedimientos en `02 - Procedimientos/`, errores en `04 - Errores/` y el avance en la nota del proyecto (`03 - Proyectos/`). Enlaza con `[[...]]` y con los mapas de `06 - Mapas/`. Nunca escribas secretos: solo dónde están.

## Antes de dar algo por terminado

- `cd backend && ./mvnw test` (incluye el test de arquitectura); `./mvnw test -Pintegration` si tocaste persistencia o REST.
- `cd frontend && flutter analyze && flutter test` (incluye el test de arquitectura).
- Si cambió la API: regenerar `docs/03-api/openapi.yaml`.

## Git

- Nunca hacer commit ni push sin que el usuario lo pida tras probar el cambio.
- Mensajes en español con Conventional Commits: `feat: [Módulo] Descripción`. Rama principal: `master`.
