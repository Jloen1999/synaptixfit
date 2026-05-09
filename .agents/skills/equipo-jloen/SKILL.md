---
name: equipo-jloen
description: Protocolo de coordinación del equipo multi-agente de SynaptixFit. Define cómo el agente principal orquesta a los sub-agentes (corrector, desarrollador, diseñador, documentacion, product-manager), el sistema de gatekeeping, el flujo de documentación obligatorio y el protocolo Git. Carga este skill cuando necesites coordinar múltiples agentes o gestionar el ciclo completo de una feature.
---

# Skill: Orquestación del Equipo SynaptixFit

Este skill proporciona al agente principal los protocolos para coordinar eficazmente al equipo de agentes especializados.

## Equipo de Agentes

| Agente | Rol | Cuándo invocarlo |
|--------|-----|-----------------|
| `product-manager` | PM / Estratega | Nueva funcionalidad, definición de MVP, requisitos |
| `diseñador` | Arquitecto | Diseño de BD, estructura de carpetas, contratos de API |
| `desarrollador` | Dev Flutter/Dart | Implementación de features, corrección de bugs |
| `corrector` | QA / Revisor | Lint, formato, calidad de código |
| `documentacion` | Tech Writer | Sincronización docs/ ↔ código |

## Protocolo de Coordinación (Gatekeeping)

### 1. Planificación y Aprobación
Ningún agente de implementación (`desarrollador`) debe modificar código sin un plan previo:
- Para features nuevas: `product-manager` → `diseñador` → `desarrollador`
- Para bugs/mejoras pequeñas: `desarrollador` directamente, pero siempre explicando el plan de acción al usuario antes de escribir.

### 2. Bloqueo de Archivos (Prevención de Colisiones)
- Si dos agentes pudieran tocar el mismo archivo, coordínalos secuencialmente.
- No invoques dos agentes en paralelo si ambos van a modificar el mismo archivo.
- Si un agente está trabajando en `app/lib/`, espera a que termine antes de lanzar otro agente sobre la misma carpeta.

### 3. Protocolo Obligatorio de Documentación (`doc-sync`)
**Regla de Cero Código Fantasma:**
- Cuando una feature o bugfix pasa las pruebas, invoca al agente `documentacion` para verificar y actualizar `docs/`.
- Una tarea NO está completa hasta que los archivos en `docs/` relevantes han sido verificados.
- Especial atención a: `04-data-model.md` (nuevas tablas/migraciones), `05-api.md` (nuevas consultas Supabase), `06-frontend.md` (nuevas rutas/pantallas).

### 4. Protocolo Git (Manual, con Aprobación)
**NUNCA hagas commit automático.** El flujo es:
1. El agente termina su trabajo y notifica.
2. Preguntas al usuario que pruebe los cambios.
3. Solo tras "OK" / "Aprobado" / "Funciona" explícito del usuario, procedes con el commit.

Para el commit:
```bash
git add .
git commit -m "feat: [Módulo] Descripción del cambio"
git push origin master
```
- Mensajes en **español**, formato **Conventional Commits** (`feat:`, `fix:`, `docs:`, `refactor:`).
- Siempre a `master`.

## Ciclo de Vida de una Feature

```
Usuario: "Quiero añadir X"
    │
    ▼
[product-manager] → Define MVP, requisitos, escribe docs/02-requirements.md
    │
    ▼
[diseñador] → Diseña arquitectura, BD, contratos de API
    │
    ▼
[desarrollador] → Implementa el código en Flutter/Dart
    │
    ▼
[corrector] → Ejecuta flutter analyze + dart format, reporta
    │
    ▼
[documentacion] → Sincroniza docs/ con los cambios realizados
    │
    ▼
[Agente principal] → Pide aprobación al usuario → git commit/push
```

## Regla de Sincronización de AGENTS.md

Cada vez que un agente modifica aspectos fundamentales del proyecto (stack, arquitectura, estructura, dependencias, rutas, comandos), el agente principal debe asegurarse de que `AGENTS.md` se actualice. Si el agente no lo hizo, hazlo tú antes del commit.

## Reglas Estrictas

- **Idioma:** Toda comunicación entre agentes y con el usuario en español.
- **Un agente a la vez por zona de código.** No paralelices agentes que toquen los mismos archivos.
- **Siempre preguntar antes del commit.** Nunca subir a Git sin aprobación explícita.
- **Docs sync obligatorio.** Ninguna feature se considera completa sin verificación de documentación.
