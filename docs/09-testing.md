# 09 - Estrategia de Testing

**Proyecto:** SynaptixFit  
**Versión:** 1.0  
**Fecha:** 19-04-2026  
**Referencia:** [02-requirements.md](02-requirements.md) (RNF-CAL-01/02/03)

---

## 1. Objetivos de Calidad

| Métrica | Objetivo MVP | Justificación |
|---------|-------------|--------------|
| Cobertura de lógica crítica | ≥ 70% | RNF-CAL-02 |
| Cobertura general | ≥ 50% | Base mínima para TFG |
| Tests e2e de flujos críticos | 100% cubiertos | Criterios de aceptación global (sección 13 del SRS) |

---

## 2. Tipos de Test

### 2.1 Tests Unitarios

**Alcance:** Lógica de dominio pura (entidades, value objects, reglas de negocio).

| Módulo | Casos prioritarios |
|--------|-------------------|
| `retos` | Cálculo de progreso ponderado, validación de dependencias cíclicas, estados permitidos |
| `bienestar` | Recomendación semanal de sesiones, detección de sobrecarga, ajuste de carga |
| `academico` | Detección de conflictos horarios, validación de evaluaciones |
| `auth` | Validación de email, reglas de contraseña |

**Ejemplo de test:**
```dart
test('El progreso de reto complejo se calcula ponderando por orden de hitos', () {
  final reto = RetoComplejo(
    hitos: [
      Hito(orden: 1, progreso: 100), // completado
      Hito(orden: 2, progreso: 50),  // parcial
      Hito(orden: 3, progreso: 0),   // sin empezar
    ],
  );
  // Pesos automáticos: 3/6=50%, 2/6=33%, 1/6=17%
  expect(reto.progresoGlobal, closeTo(66.5, 0.5));
});
```

### 2.2 Tests de Integración

**Alcance:** Interacción entre capas (repositorio → datasource → Supabase).

| Flujo | Descripción |
|-------|------------|
| Login completo | Registro → Auth → Token → Redirect a Home |
| Crear rutina | Seleccionar ejercicios → Guardar → Verificar en BD |
| Registrar sesión | Completar rutina → RPE → XP → Publicación social |
| Clonar reto público | Visualizar → Clonar → Verificar copia en perfil |
| Sincronización offline | Crear recurso offline → Reconectar → Verificar sync |

### 2.3 Tests de UI (Golden Tests)

**Alcance:** Capturas de pantalla de componentes y pantallas clave.

| Pantalla | Variantes a capturar |
|----------|---------------------|
| Dashboard | Estado normal, sin retos, fatiga crítica |
| Explorador de Ejercicios | Con resultados, sin resultados, cargando |
| Detalle de Ejercicio | Con video R2, con fallback texto |
| Constructor de Rutina | Vacío, <3 ejercicios, completo |
| Crear Reto Complejo | Suma = 100%, suma < 100% |

### 2.4 Tests de Rendimiento

| Pantalla | Métrica objetivo |
|----------|-----------------|
| Dashboard | < 2s carga inicial (RNF-REN-01) |
| Explorador de Ejercicios | < 3s lista con filtros |
| Detalle de Ejercicio | < 1.5s carga multimedia R2 |
| Constructor de Rutina | Sin latencia perceptible en reorder |
| Interacciones generales | < 300ms (RNF-REN-02) |

---

## 3. Criterios de Aceptación por Flujo (del SRS)

Estos criterios definen cuándo un flujo e2e se considera completo:

1. El usuario puede completar: registro → crear plan → completar reto/rutina → visualizar logro.
2. La visibilidad de recursos se respeta en lectura y escritura.
3. El feed muestra solo contenido autorizado.
4. Las notificaciones se pueden activar/desactivar correctamente.
5. El catalogo de ejercicios (ExerciseDB ya ingerido en Supabase) funciona aunque Kaggle/AscendAPI no este disponible temporalmente.
6. El usuario puede buscar y seleccionar ejercicios con filtros y visualizar multimedia desde R2.

---

## 4. Herramientas

| Herramienta | Propósito |
|-------------|----------|
| `flutter test` | Tests unitarios y de widgets |
| `flutter test --golden` | Golden tests |
| `integration_test` | Tests de integración |
| `coverage` | Reporte de cobertura |
| `very_good_analysis` / `flutter_lints` | Lint estricto (RNF-CAL-03) |

---

## 5. Pipeline de Calidad

```
git push →
  ├── Lint + Formateo (obligatorio)
  ├── Tests unitarios
  ├── Tests de integración
  ├── Golden tests (comparación visual)
  └── Reporte de cobertura
```

> Los tests deben pasar antes de hacer merge a `master`. Ver [protocolo de despliegue](../PROYECTO_DOCS.md) y regla `actualizacion-git.md`.

---

**Documento compilado:** 19-04-2026  
**Última revisión:** v1.0
