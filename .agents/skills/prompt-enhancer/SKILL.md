---
name: prompt-enhancer
description: Refina y estructura prompts, ideas o instrucciones difusas para convertirlos en prompts claros, accionables y bien formados. Úsalo cuando el usuario tenga una idea vaga, un prompt mal definido, o necesite estructurar mejor una instrucción para un modelo de IA o cualquier tarea. También responde a frases como "mejora este prompt", "dame ideas de cómo pedir esto", "estructura esta idea", "no sé cómo preguntar esto", "dame un template para...".
---

# Prompt Enhancer — Refinamiento y Estructuración de Prompts e Ideas

Este skill toma ideas, instrucciones o prompts difusos y los transforma en prompts claros, estructurados y accionables. Aplica principios de prompt engineering, contextualización y formato para maximizar la calidad del resultado esperado.

## Flujo de Trabajo

### 1. Recibir la idea o prompt original

El usuario comparte una idea, instrucción o prompt en su estado actual. Puede ser:
- Una frase suelta ("quiero una app de recetas")
- Un prompt mal definido ("dime cosas sobre ejercicio")
- Una necesidad sin formular ("necesito organizar mi semana")
- Un template que quiere mejorar

### 2. Integrar Documentación del Proyecto

Si el proyecto tiene una carpeta `/docs` en la raíz, **revisa su contenido antes de mejorar el prompt**. La documentación del proyecto puede proporcionar contexto clave que transforme un prompt genérico en uno específico y alineado con la realidad del sistema.

#### Cuándo y cómo usar la documentación

1. **Siempre verifica** si existe la carpeta `docs/`. Lee su listado de archivos.
2. **Determina relevancia**: No toda la documentación aplica a todo prompt. Selecciona solo los archivos pertinentes según el dominio del prompt que el usuario quiere mejorar.

   | Categoría del prompt | Documentos relevantes en `docs/` |
   | -------------------- | -------------------------------- |
   | Sobre el proyecto en general | `01-introduction.md` (visión, problema, alcance) |
   | Sobre funcionalidades y features | `02-requirements.md` (requisitos funcionales y no funcionales) |
   | Sobre estructura y componentes | `03-architecture.md` (stack, capas, servicios, patrones) |
   | Sobre datos, tablas, entidades | `04-data-model.md` (esquema, relaciones, nomenclatura) |
   | Sobre APIs y consultas | `05-api.md` (endpoints, RLS, políticas de acceso) |
   | Sobre interfaz y navegación | `06-frontend.md` (rutas, pantallas, widgets, estado) |
   | Sobre lógica de servidor/backend | `07-backend.md` (edge functions, workers) |
   | Sobre instalación y entorno | `08-installation.md` |
   | Sobre testing | `09-testing.md` |
   | Sobre despliegue | `10-deployment.md` |
   | Sobre seguridad | `11-security.md` |
   | Sobre el usuario final | `12-user-guide.md` (flujos de uso, funcionalidades visibles) |
   | Sobre mantenimiento | `13-maintenance.md` |
   | Sobre cambios y versiones | `14-changelog.md` |

3. **Extrae contexto útil** de los documentos relevantes:
   - Terminología del dominio (nombres de entidades, módulos, flujos)
   - Stack tecnológico y restricciones técnicas
   - Patrones de arquitectura y convenciones de código
   - Nomenclatura específica (tablas, rutas, providers, modelos)
   - Limitaciones conocidas y decisiones de diseño

4. **Incorpora el contexto al prompt mejorado**:
   - Usa la misma terminología del proyecto para que el resultado sea directamente aplicable.
   - Añade restricciones técnicas reales (ej. "usa Riverpod como gestor de estado", "la BD es Supabase PostgreSQL con RLS").
   - Referencia entidades y relaciones existentes para evitar que el modelo invente esquemas inexistentes.
   - Sitúa el prompt en el flujo real de la aplicación (ej. "esto va en la pantalla de Dashboard dentro del Tab 2 de la bottom nav").

5. **Sé selectivo**: No vuelques documentación completa en el prompt mejorado. Extrae solo citas, términos, entidades, restricciones y patrones que realmente enriquezcan el prompt para que el output generado sea compatible y coherente con el proyecto.

#### Ejemplo de enriquecimiento con docs

**Prompt original** (sin contexto de proyecto):
> "Crea un servicio de notificaciones"

**Con documentación del proyecto** (se detecta `docs/`, se lee `03-architecture.md` y `04-data-model.md`):

```
Prompt mejorado:

Eres un desarrollador Flutter con experiencia en Supabase.

Contexto del proyecto SynaptixFit (extraído de docs/):
- Stack: Flutter 3.x + Riverpod + GoRouter + Supabase PostgreSQL + Realtime
- La tabla `notificaciones` tiene campos: id, usuario_id, tipo, titulo, mensaje, leida, created_at
- Las notificaciones envían recordatorios de check-in, hitos de reto, recordatorio de rutina
- Existe la tabla `preferencias_notificacion` que controla canales habilitados por usuario
- Patrón de arquitectura: Feature-first en app/lib/features/

Tarea: Implementa un NotificationService en Dart que:
1. Consulte notificaciones no leídas desde Supabase para el usuario autenticado.
2. Se conecte al canal Realtime `notificaciones:usuario_id=eq.{id}` para recibir nuevas notificaciones en vivo.
3. Exponga un StreamProvider de Riverpod para que los widgets reaccionen a nuevas notificaciones.
4. Permita marcar como leída desde el cliente.

Formato: Responde con el código completo de la clase NotificationService y el provider de Riverpod.
Restricciones: Usa el cliente Supabase ya inicializado, no reinventes el sistema de auth.
```

Este enriquecimiento asegura que el output del modelo:
- Use los nombres reales de tablas y campos (`notificaciones`, `preferencias_notificacion`, `leida`)
- Siga los patrones del proyecto (`Riverpod`, `GoRouter`, Supabase Realtime)
- Sea código que se puede copiar y pegar directamente sin adaptaciones mayores

### 3. Diagnosticar el prompt

Identifica las carencias del prompt actual según estas dimensiones:

| Dimensión       | Pregunta guía                                     |
| --------------- | ------------------------------------------------- |
| **Objetivo**    | ¿Qué quiere lograr exactamente el usuario?         |
| **Contexto**    | ¿Hay suficiente información de trasfondo?          |
| **Formato**     | ¿Está definido cómo debe entregarse la respuesta?  |
| **Rol**         | ¿Se asignó un rol o perspectiva al modelo?         |
| **Restricciones**| ¿Hay límites, tono, extensión o exclusiones?      |
| **Ejemplos**    | ¿Se proporcionaron ejemplos del output deseado?    |
| **Audiencia**   | ¿Se definió para quién es el resultado?            |

### 4. Aplicar la estructura de prompt mejorado

Para cada prompt, aplica esta estructura base:

```
[Rol/Persona asignada al modelo]
[Contexto y situación]
[Tarea específica y objetivo claro]
[Formato de salida esperado]
[Restricciones y parámetros]
[Ejemplos de output deseado (opcional)]
```

### 5. Entregar la versión mejorada

Genera el prompt refinado en un bloque de código, precedido de un breve análisis de:
- Qué le faltaba al prompt original (las 2-3 carencias principales)
- Qué se mejoró y por qué
- Sugerencias adicionales si aplican

## Técnicas Avanzadas de Prompt Engineering

Aplica estas técnicas cuando el caso lo amerite:

- **Chain of Thought (CoT)**: Incluir "Piensa paso a paso" o "Razona antes de responder" para tareas que requieren razonamiento lógico.
- **Few-shot prompting**: Proporcionar 2-3 ejemplos de input→output esperado para guiar el formato y estilo.
- **Role prompting**: Asignar un rol experto ("Eres un nutricionista deportivo con 15 años de experiencia...").
- **Delimitadores**: Usar `###`, `---` o XML tags para separar secciones del prompt.
- **Auto-consistencia**: Pedir múltiples enfoques o iteraciones: "Genera 3 versiones distintas y elige la mejor".
- **Prompt encadenado**: Dividir tareas complejas en pasos secuenciales con prompts independientes.
- **Zero-shot classification con formato**: Forzar estructura: "Responde ÚNICAMENTE en JSON con los campos: titulo, descripcion, tags".
- **Metaprompting**: Pedir al modelo que primero analice el prompt y sugiera mejoras antes de responder.

## Antipatrones a Evitar

- Prompts demasiado cortos que asumen contexto que el modelo no tiene.
- Instrucciones ambiguas con múltiples interpretaciones posibles.
- Mezclar múltiples tareas no relacionadas en un solo prompt.
- Usar negaciones débiles ("no seas breve") en vez de afirmativas ("sé extenso y detallado, mínimo 500 palabras").
- Falta de formato de salida cuando se necesita un formato específico.

## Ejemplo de Transformación

**Prompt original (difuso):**
> "Dame una rutina de ejercicio"

**Prompt mejorado:**
```
Eres un entrenador personal certificado con experiencia en calistenia y entrenamiento funcional.

Contexto:
- Tengo 28 años, nivel intermedio de fitness.
- Entreno en casa, tengo banda elástica y barra de dominadas.
- Dispongo de 45 minutos, 3 días por semana.
- Mi objetivo es ganar fuerza funcional y definición muscular.

Tarea: Diseña una rutina semanal de 3 días (push/pull/legs) adaptada a mis condiciones.

Formato de salida:
### Día 1: Push
| Ejercicio | Series × Reps | Descanso | Notas |
|-----------|--------------|----------|-------|
| ...       | ...          | ...      | ...   |

Restricciones:
- Sin ejercicios que requieran máquinas de gimnasio.
- Incluir calentamiento de 5 min y enfriamiento de 5 min.
- Progresiones para cada ejercicio (versión fácil y difícil).
```

## Variantes de Uso

### Mejora incremental
Si el usuario ya tiene un prompt decente, sugiere micro-mejoras específicas sin reescribirlo completo.

### Generación desde cero
Si el usuario solo tiene una necesidad difusa, haz preguntas de clarificación breves (máximo 3) antes de generar el prompt.

### Template reutilizable
Si el usuario necesita un template para uso recurrente, genera un prompt con placeholders (`[NOMBRE]`, `[OBJETIVO]`) que pueda rellenar después.

### Iteración de prompts
Si el usuario tiene un prompt para generación de imágenes (Midjourney, DALL-E, Stable Diffusion), aplica principios específicos:
- Descripción del sujeto → detalles → estilo artístico → parámetros técnicos
- Incluir referencias a artistas, técnicas, iluminación, composición
- Usar pesos y negativos cuando la plataforma lo soporte
