---
name: git-commit
description: 'Ejecuta git commit con mensajes en español siguiendo Conventional Commits, y hace push automático a master. Uso cuando el usuario pide commit, /commit, o guardar cambios.'
license: MIT
allowed-tools: Bash
---

# Git Commit con Conventional Commits en Español

## Overview

Crea commits semánticos y estandarizados usando la especificación Conventional Commits. Analiza el diff real para determinar tipo, alcance y mensaje apropiados. **Todos los mensajes se generan en español**. Tras el commit exitoso, hace push automático a `master`.

## Formato del Commit (Español)

```
<tipo>[opcional ámbito]: <descripción en español>

[cuerpo opcional en español]

[footer opcional]
```

## Tipos de Commit

| Tipo       | Propósito                        |
| ---------- | -------------------------------- |
| `feat`     | Nueva funcionalidad              |
| `fix`      | Corrección de bug                |
| `docs`     | Documentación solamente          |
| `style`    | Formato/estilo (sin lógica)      |
| `refactor` | Refactorización (ni feature ni fix) |
| `perf`     | Mejora de rendimiento            |
| `test`     | Agregar/actualizar tests         |
| `build`    | Sistema de build/dependencias    |
| `ci`       | Cambios en CI/config             |
| `chore`    | Mantenimiento/varios             |
| `revert`   | Revertir commit                  |

## Breaking Changes

```
feat!: eliminar endpoint obsoleto

BREAKING CHANGE: el comportamiento de `extends` cambió
```

## Flujo de Trabajo

### 1. Analizar Diff

```bash
# Si hay archivos staged, usar diff staged
git diff --staged

# Si no hay nada staged, usar working tree diff
git diff

# También verificar estado
git status --porcelain
```

### 2. Stage Files (si es necesario)

Si no hay nada staged o quieres agrupar cambios:

```bash
# Stage archivos específicos
git add ruta/al/archivo1 ruta/al/archivo2

# Stage por patrón
git add *.test.*
git add src/components/*

# Staging interactivo
git add -p
```

**Nunca hacer commit de secretos** (.env, credentials.json, claves privadas).

### 3. Generar Mensaje de Commit (EN ESPAÑOL)

Analiza el diff para determinar:

- **Tipo**: ¿Qué tipo de cambio es? (usar tabla de tipos arriba)
- **Ámbito**: ¿Qué área/módulo afecta? (opcional)
- **Descripción**: Resumen de una línea en español (imperativo, < 72 caracteres)

> **IMPORTANTE**: La descripción, el cuerpo y los footers deben escribirse SIEMPRE en español.

### 4. Ejecutar Commit

```bash
git commit -m "<tipo>[ámbito]: <descripción en español>"
```

Para multi-línea con cuerpo:

```bash
git commit -m "$(cat <<'EOF'
<tipo>[ámbito]: <descripción en español>

<cuerpo opcional en español>

<footer opcional>
EOF
)"
```

### 5. Push a master (AUTOMÁTICO)

**Después de cada commit exitoso**, ejecutar push:

```bash
git push origin master
```

Verificar que el push fue exitoso. Si falla (ej. por protecciones de rama), informar al usuario.

## Buenas Prácticas

- Un cambio lógico por commit
- Tiempo presente, modo imperativo en español: "corregir bug" no "corrige bug" ni "corregido bug"
- Referenciar issues en español si aplica: `Cierra #123`, `Refs #456`
- Descripción menor a 72 caracteres
- **Cuerpo del mensaje en español**
- **Push automático a master tras el commit**

## Protocolo de Seguridad Git

- NO actualizar git config
- NO ejecutar comandos destructivos (--force, hard reset) sin autorización explícita
- NO saltar hooks (--no-verify) a menos que el usuario lo pida
- NO hacer force push a master (advertir al usuario si lo solicita)
- Si el commit falla por hooks, corregir y crear NUEVO commit (no hacer amend)
