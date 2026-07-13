# Plan Definitivo v7 — Integración de Fórmulas Neurofisiológicas

> Documento de diseño e implementación técnica.
> Basado en la investigación: *SynaptixFit: Equilibrio Académico y Físico*.
> Convención: código en inglés (variables, archivos), comentarios y docs en español.

---

## Índice

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Fase 1: Migraciones Supabase](#2-fase-1-migraciones-supabase)
3. [Fase 2: Nuevos Servicios Dart](#3-fase-2-nuevos-servicios-dart)
4. [Fase 3: DTOs y Providers](#4-fase-3-dtos-y-providers)
5. [Fase 4: Modificación de Servicios Existentes](#5-fase-4-modificación-de-servicios-existentes)
6. [Fase 5: UI — Flat Design + Español](#6-fase-5-ui--flat-design--español)
7. [Fase 6 (Opcional): Gamificación Unificada](#7-fase-6-opcional-gamificación-unificada)
8. [Protocolo de Reversibilidad](#8-protocolo-de-reversibilidad)
9. [Resumen de Archivos](#9-resumen-de-archivos)
10. [Principios de Diseño](#10-principios-de-diseño)

---

## 1. Resumen Ejecutivo

### 1.1. Fórmulas Implementadas

| # | Fórmula | Ecuación | Propósito |
|---|---------|----------|-----------|
| 1 | Gasto Calórico del Estudio | `(RMR/86400)·t·MET` | Cuantificar kcal del esfuerzo cognitivo |
| 2 | Carga Cognitiva Acumulada | `C_acum = Σ(1−e^(−ρ·D))·μ·e^(−λ·R)` | Modelar fatiga atencional con decaimiento exponencial |
| 3 | Regulación Cruzada | `V_mod = V_base·(1−λ_s·min(1, (C/C_max)·e^(−σ·D_exam)))` | Ajuste bidireccional académico ↔ físico |
| 4 | SM-2-Physio | `Q_adj = Q_real + η·(carga_hoy/carga_max)` | Perdón de fallos mnemotécnicos por fatiga serotoninérgica post-ejercicio |

### 1.2. Convenciones del Plan

| Convención | Detalle |
|------------|---------|
| **BD** | Español estricto (`estado_cognitivo_usuario`, `registros_carga_fisica`, `registros_repaso_srs`, `estado_regulacion_cruzada`) |
| **UI** | Flat Design (`elevation: 0`, sin sombras, fondos de baja opacidad), todo texto en español |
| **Providers** | Getter SUM en tiempo real (sin columnas acumulativas que requieran triggers de escritura) |
| **SyncHub** | Invalidación selectiva de providers para eventos de ida y vuelta |
| **Reversibilidad** | Toda operación de completar tiene su contraparte de desmarcar (triggers bidireccionales, métodoss `desmarcar*`, eventos `*Desmarcado`) |
| **Extender vs. duplicar** | Se añaden columnas a tablas existentes en lugar de crear tablas paralelas redundantes |

---

## 2. Fase 1: Migraciones Supabase

### 2.1. Migración `20260701000027_cognitive_study_cost.sql`

**Objetivo:** Extender `horarios_academicos` con coste calórico y crear el estado cognitivo por usuario (relación 1:1).

```sql
BEGIN;

-- 2.1.1 Extender horarios_academicos con columnas de coste cognitivo
ALTER TABLE public.horarios_academicos
  ADD COLUMN IF NOT EXISTS met_value               NUMERIC(4,2)  DEFAULT 1.30,
  ADD COLUMN IF NOT EXISTS calorias_quemadas       NUMERIC(6,2),
  ADD COLUMN IF NOT EXISTS carga_cognitiva_generada NUMERIC(6,4);

-- 2.1.2 Tabla de estado cognitivo (1:1 con usuarios, mutable en tiempo real)
CREATE TABLE IF NOT EXISTS public.estado_cognitivo_usuario (
  usuario_id                    UUID PRIMARY KEY REFERENCES public.usuarios(id) ON DELETE CASCADE,
  carga_cognitiva_actual        NUMERIC(6,4) NOT NULL DEFAULT 0,
  capacidad_atencion_actual     NUMERIC(4,3) NOT NULL DEFAULT 1.000
    CHECK (capacidad_atencion_actual BETWEEN 0 AND 1),
  duracion_ultimo_bloque_min    INTEGER NOT NULL DEFAULT 0,
  fecha_ultimo_descanso         TIMESTAMPTZ,
  rmr_base                      NUMERIC(6,2),
  creado_en                     TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en                TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.1.3 Trigger que inicializa el estado cognitivo al crear un usuario
CREATE OR REPLACE FUNCTION public.trg_inicializar_estado_cognitivo()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.estado_cognitivo_usuario (usuario_id) VALUES (NEW.id)
    ON CONFLICT (usuario_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_inicializar_estado_cognitivo ON public.usuarios;
CREATE TRIGGER trg_inicializar_estado_cognitivo
  AFTER INSERT ON public.usuarios
  FOR EACH ROW EXECUTE FUNCTION public.trg_inicializar_estado_cognitivo();

-- 2.1.4 RLS
ALTER TABLE public.estado_cognitivo_usuario ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner select" ON public.estado_cognitivo_usuario
  FOR SELECT USING (auth.uid() = usuario_id);
CREATE POLICY "Owner update" ON public.estado_cognitivo_usuario
  FOR UPDATE USING (auth.uid() = usuario_id);
CREATE POLICY "Admin all"   ON public.estado_cognitivo_usuario
  FOR ALL    USING (public.es_admin(auth.uid()));

CREATE INDEX IF NOT EXISTS idx_estado_cognitivo_usuario
  ON public.estado_cognitivo_usuario(usuario_id);

COMMIT;
```

### 2.2. Migración `20260701000028_physical_workload_and_srs.sql`

**Objetivo:** Crear tablas de carga física, regulación cruzada y auditoría SRS, con triggers bidireccionales y función RPC de recálculo.

```sql
BEGIN;

-- 2.2.1 Registros de carga física diaria (eventos atómicos, insert-only desde trigger)
CREATE TABLE IF NOT EXISTS public.registros_carga_fisica (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id       UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  fecha_registro   DATE NOT NULL DEFAULT CURRENT_DATE,
  rpe_sesion       SMALLINT NOT NULL CHECK (rpe_sesion BETWEEN 1 AND 10),
  duracion_minutos INTEGER NOT NULL CHECK (duracion_minutos > 0),
  carga_diaria     NUMERIC(7,2) GENERATED ALWAYS AS
    (rpe_sesion * duracion_minutos) STORED,
  sesion_id        UUID REFERENCES public.sesiones_registradas(id),
  creado_en        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.2.2 Estado de regulación cruzada (1:1 con usuarios, cache materializado)
CREATE TABLE IF NOT EXISTS public.estado_regulacion_cruzada (
  usuario_id                    UUID PRIMARY KEY REFERENCES public.usuarios(id) ON DELETE CASCADE,
  carga_aguda_7d                NUMERIC(8,2),
  carga_cronica_28d             NUMERIC(8,2),
  acwr_actual                   NUMERIC(4,2) GENERATED ALWAYS AS (
    carga_aguda_7d / NULLIF(carga_cronica_28d, 0)
  ) STORED,
  min_estudio_max_recomendado   INTEGER NOT NULL DEFAULT 90,
  dias_proximo_examen           INTEGER,
  creado_en                     TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en                TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.2.3 Auditoría inmutable de repasos SRS (q_real + q_ajustado según el paper)
CREATE TABLE IF NOT EXISTS public.registros_repaso_srs (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  material_estudio_id  UUID NOT NULL REFERENCES public.materiales_estudio(id) ON DELETE CASCADE,
  fecha_repaso         TIMESTAMPTZ NOT NULL DEFAULT now(),
  q_real               SMALLINT NOT NULL CHECK (q_real BETWEEN 0 AND 5),
  q_ajustado           NUMERIC(3,2) NOT NULL,
  coeficiente_fatiga   NUMERIC(4,3) NOT NULL DEFAULT 0,
  creado_en            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.2.4 Trigger BIDIRECCIONAL de carga física
--       IDA:  inserta carga cuando completada_en pasa de NULL a fecha
--       VUELTA: elimina carga cuando completada_en pasa de fecha a NULL
--       Usa NEW.duracion_minutos (cronómetro real del cliente), no timestamps.
CREATE OR REPLACE FUNCTION public.trg_insertar_carga_fisica()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.completada_en IS NOT NULL AND OLD.completada_en IS NULL THEN
    INSERT INTO public.registros_carga_fisica (
      usuario_id, fecha_registro, rpe_sesion, duracion_minutos, sesion_id
    ) VALUES (
      NEW.usuario_id,
      NEW.completada_en::date,
      COALESCE(NEW.rpe, 5),
      COALESCE(NEW.duracion_minutos, 1),
      NEW.id
    );
  END IF;

  IF NEW.completada_en IS NULL AND OLD.completada_en IS NOT NULL THEN
    DELETE FROM public.registros_carga_fisica WHERE sesion_id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_insertar_carga_fisica ON public.sesiones_registradas;
CREATE TRIGGER trg_insertar_carga_fisica
  AFTER UPDATE ON public.sesiones_registradas
  FOR EACH ROW EXECUTE FUNCTION public.trg_insertar_carga_fisica();

-- 2.2.5 RPC: recalcular estado de regulación cruzada
--       Carga aguda = SUM carga_diaria últimos 7 días
--       Carga crónica = AVG carga_diaria últimos 28 días
--       ACWR = aguda / crónica (generado por columna STORED)
CREATE OR REPLACE FUNCTION public.recalcular_regulacion_cruzada(p_usuario_id UUID)
RETURNS void AS $$
DECLARE
  v_aguda    NUMERIC(8,2);
  v_cronica  NUMERIC(8,2);
  v_dias     INTEGER;
BEGIN
  SELECT COALESCE(SUM(carga_diaria), 0) INTO v_aguda
  FROM public.registros_carga_fisica
  WHERE usuario_id = p_usuario_id
    AND fecha_registro >= CURRENT_DATE - INTERVAL '7 days';

  SELECT COALESCE(SUM(carga_diaria) / 28.0, 0) INTO v_cronica
  FROM public.registros_carga_fisica
  WHERE usuario_id = p_usuario_id
    AND fecha_registro >= CURRENT_DATE - INTERVAL '28 days';

  SELECT EXTRACT(DAY FROM (MIN(fecha_limite) - CURRENT_DATE))::int INTO v_dias
  FROM public.entregas_examenes
  WHERE usuario_id = p_usuario_id
    AND esta_completado = false
    AND fecha_limite >= CURRENT_DATE;

  INSERT INTO public.estado_regulacion_cruzada (
    usuario_id, carga_aguda_7d, carga_cronica_28d, dias_proximo_examen
  ) VALUES (p_usuario_id, v_aguda, v_cronica, v_dias)
  ON CONFLICT (usuario_id) DO UPDATE SET
    carga_aguda_7d     = EXCLUDED.carga_aguda_7d,
    carga_cronica_28d  = EXCLUDED.carga_cronica_28d,
    dias_proximo_examen = EXCLUDED.dias_proximo_examen,
    actualizado_en     = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2.2.6 RLS para todas las tablas nuevas
ALTER TABLE public.registros_carga_fisica ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner all" ON public.registros_carga_fisica
  FOR ALL USING (auth.uid() = usuario_id);

ALTER TABLE public.estado_regulacion_cruzada ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner select" ON public.estado_regulacion_cruzada
  FOR SELECT USING (auth.uid() = usuario_id);

ALTER TABLE public.registros_repaso_srs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner insert" ON public.registros_repaso_srs FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.materiales_estudio
          WHERE id = material_estudio_id AND usuario_id = auth.uid())
);
CREATE POLICY "Owner select" ON public.registros_repaso_srs FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.materiales_estudio
          WHERE id = material_estudio_id AND usuario_id = auth.uid())
);

-- 2.2.7 Índices para consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_carga_fisica_usuario_fecha
  ON public.registros_carga_fisica(usuario_id, fecha_registro);
CREATE INDEX IF NOT EXISTS idx_carga_fisica_sesion
  ON public.registros_carga_fisica(sesion_id);
CREATE INDEX IF NOT EXISTS idx_repaso_srs_material
  ON public.registros_repaso_srs(material_estudio_id, fecha_repaso);

COMMIT;
```

---

## 3. Fase 2: Nuevos Servicios Dart

### 3.1. `StudyCalorieService`

**Archivo:** `app/lib/features/bienestar/infrastructure/study_calorie_service.dart`
**Tipo:** Clase con métodos estáticos puros (sin estado, sin I/O).

**Fundamento matemático (Mifflin-St Jeor, 1990):**

```
RMR = 10·P + 6.25·H − 5·A + S
  donde:
    P = peso en kg
    H = altura en cm
    A = edad en años
    S = +5 (masculino), −161 (femenino)

Gasto Bloque = (RMR / 86400) · duracionSegundos · MET
```

**MET cognitivo (Compendio de Actividades Físicas para Adultos, 3ª edición 2024):**

| Actividad | Código Compendio | MET |
|-----------|-----------------|-----|
| Estudiar, leer o escribir | 09060 | 1.3 |
| Trabajo de escritorio, tipeo | 09040 | 1.3 |
| Asistir a clase con toma de apuntes | 09065 | 1.8 |

**API del servicio:**

| Método | Parámetros | Retorno | Descripción |
|--------|-----------|---------|-------------|
| `calcularRMR` | `pesoKg` (double), `alturaCm` (double), `edad` (int), `sexo` (String) | `double` | RMR en kcal/día |
| `calcularGastoEstudio` | `rmr` (double), `duracionSegundos` (int), `metValue` (double) | `double` | kcal del bloque |
| `metCognitivoParaActividad` | `tipoActividad` (String) | `double` | 1.3 para estudio/repaso, 1.8 para clase, 1.3 default |

### 3.2. `CognitiveLoadCalculatorService`

**Archivo:** `app/lib/features/bienestar/infrastructure/cognitive_load_calculator_service.dart`
**Tipo:** Clase con métodos estáticos puros.

**Fundamento matemático (modelo híbrido de desintegración exponencial y acumulación logarítmica):**

```
C_acum(n) = Σ[i=1..n] (1 − e^(−ρ·D_i)) · μ_i · e^(−λ·R_i)

  donde:
    D_i  = duración del bloque i en minutos
    μ_i  = multiplicador de dificultad de la asignatura
    R_i  = tiempo de descanso antes del bloque i en minutos
    ρ    = 0.1 (constante de disipación de fatiga, min⁻¹)
    λ    = 0.05 (resistencia sistémica a la fatiga)

A(t) = A₀ · e^(−β·t)
  donde:
    A₀  = capacidad atencional inicial
    t   = minutos transcurridos dentro del bloque
    β   = 0.02 (constante de decaimiento atencional)
```

**Constantes empíricas:** ρ = 0.1, λ = 0.05, β = 0.02

| Método | Parámetros | Retorno | Descripción |
|--------|-----------|---------|-------------|
| `calcularCargaAcumulada` | `bloques` List<({duracionMin, dificultad, descansoMin})> | `double` [0, 1] | C_acum tras n bloques |
| `capacidadAtencional` | `capacidadInicial` (double), `minutosTranscurridos` (int) | `double` [0, 1] | A(t) en tiempo real |
| `dificultadAsignatura` | `dificultad` (String?) | `double` | 1.0 baja, 1.3 media, 1.8 alta |

### 3.3. `CrossRegulationService`

**Archivo:** `app/lib/features/bienestar/infrastructure/cross_regulation_service.dart`
**Tipo:** Clase con métodos estáticos puros.

**Fundamento matemático (Teoría del Gobernador Central + Modelo ACWR de Gabbett):**

**A) Estrés académico → Reduce volumen deportivo:**

```
V_mod = V_base · (1 − λ_s · min(1, (C_acum / C_max) · e^(−σ·D_exam)))

  donde:
    λ_s   = 0.40 (severidad de descarga deportiva, entre 30% y 50%)
    σ     = 0.15 (sensibilidad de calendario)
    D_exam = días hasta el próximo examen
    C_max  = 1.0 (techo cognitivo empírico)
```

**B) Fatiga física → Acorta bloques de estudio (T_max):**

```
Si ACWR ≤ 1.3:  T_max = T_base           (sin penalización, zona óptima)
Si 1.3 < ACWR ≤ 2.0: T_max = T_base · (1 − α · ln(ACWR/1.3))  (penalización logarítmica)
Si ACWR > 2.0:  T_max = T_base · 0.5     (hard cap al 50%: zona de peligro)

  donde:
    α = 0.5 (amortiguación sistémica cognitiva)
```

**Constantes:** σ = 0.15, λ_s = 0.40, α = 0.5

| Método | Parámetros | Retorno | Descripción |
|--------|-----------|---------|-------------|
| `calcularVolumenModificado` | `volumenBase`, `cargaCognitiva`, `cargaMaxima`, `diasHastaExamen` | `double` factor [0, 1] | Factor de reducción de volumen por estrés académico |
| `calcularTmaxEstudio` | `tBaseMinutos` (int), `acwr` (double) | `int` minutos | Tope máximo de minutos por bloque de estudio |

### 3.4. `Sm2PhysioService`

**Archivo:** `app/lib/features/academico/infrastructure/sm2_physio_service.dart`
**Tipo:** Clase con un método estático.

**Fundamento matemático (Hipótesis de Fatiga Central — Meeusen, Newsholme):**

El ejercicio intenso eleva la proporción de triptófano/BCAA en sangre, aumentando la síntesis de serotonina cerebral (5-HT), lo que deteriora temporalmente la evocación mnésica. Un fallo en la tarjeta durante esta ventana no refleja una fisura real en la retención a largo plazo.

```
Q_adj = Q_real + η · (cargaFisicaHoy / cargaFisicaMaximaHistoria)

  donde:
    η = 0.5 (constante de indulgencia neuronal)
    Q_real ∈ [0, 5] (escala ampliada: 0=blackout, 5=recuerdo fotográfico)
    cargaFisicaHoy = AU del día actual (session_rpe × duración_minutos)
    cargaFisicaMaxima = máxima AU diaria registrada en el historial
```

**Importante:**
- No existe función de mapeo a escala 0-2.
- El `Sm2Calculator` se modifica para aceptar `calidad` como `double` en la fórmula EF (escala 0-5 continua).
- **Prohibido redondear `Q_adj` a entero antes de la fórmula EF.** La curva de Ebbinghaus necesita la fracción decimal precisa. Solo los condicionales lógicos (`if (calidad < 3)`) usan `.round()` para determinar fallo/éxito.
- Este recálculo opera en la sombra: el usuario nunca ve `Q_adj`, solo el intervalo resultante.

| Método | Parámetros | Retorno | Descripción |
|--------|-----------|---------|-------------|
| `calcularQAdj` | `qReal` (int 0-5), `cargaFisicaHoy` (double), `cargaFisicaMaxima` (double) | `double` [0.0, 5.0] | Calidad ajustada por indulgencia neuronal |

---

## 4. Fase 3: DTOs y Providers

### 4.1. Modificación de `Sm2Calculator` — Ampliación a escala 0-5

**Archivo:** `app/lib/features/academico/infrastructure/sm2_calculator.dart`

El `Sm2Calculator` actual opera en escala 0-2. Debe ampliarse a 0-5 para ser compatible con `Q_adj` del paper.

| Elemento | Antes (escala 0-2, `int`) | Después (escala 0-5, `double` para EF, `int` para lógica) |
|----------|---------------------------|----------------------------------------------------------|
| Tipo del parámetro `calidad` | `int` | **`double`** — recibe `Q_adj` sin redondeo para la fórmula EF |
| Validación | `calidad < 0 \|\| calidad > 2` | Eliminada — el rango continuo no requiere validación discreta |
| Umbral de fallo (reset repasos) | `if (calidad < 2)` | `if (calidad.round() < 3)` — solo aquí se redondea |
| Fórmula del EF | `EF + (0.1 − (2−q)·(0.08+(2−q)·0.02))` | `EF + (0.1 − (5−q)·(0.08+(5−q)·0.02))` — **`q` es `double` exacto** |
| Clamp inferior EF | 1.3 | 1.3 |
| Clamp superior EF | 2.5 | 3.0 (permite EF > 2.5 para Q_adj ≈ 5) |
| Progresión de intervalo | 0→1, 1→3, 2→7, 3+→ceil(I·EF) | Sin cambios — usa `repasosCompletados` (int), no `calidad` |
| Estado dominio | calidad 0→'necesita_repaso', 1→'en_progreso', 2→'dominado' | `calidad.round()` 0-1→'necesita_repaso', 2-3→'en_progreso', 4-5→'dominado' |

### 4.2. DTOs en `db_models.dart`

**Archivo:** `app/lib/shared/models/db_models.dart`

Se añaden 4 nuevas clases con `factory fromMap()` usando nombres de columna en español:

| Clase | Tabla | Campos principales |
|-------|-------|-------------------|
| `EstadoCognitivoUsuarioDb` | `estado_cognitivo_usuario` | `usuarioId`, `cargaCognitivaActual`, `capacidadAtencionActual`, `duracionUltimoBloqueMin`, `fechaUltimoDescanso`, `rmrBase`, timestamps |
| `EstadoRegulacionCruzadaDb` | `estado_regulacion_cruzada` | `usuarioId`, `cargaAguda7d`, `cargaCronica28d`, `acwrActual`, `minEstudioMaxRecomendado`, `diasProximoExamen`, timestamps |
| `RegistroRepasoSrsDb` | `registros_repaso_srs` | `id`, `materialEstudioId`, `fechaRepaso`, `qReal`, `qAjustado`, `coeficienteFatiga`, timestamps |
| `RegistroCargaFisicaDb` | `registros_carga_fisica` | `id`, `usuarioId`, `fechaRegistro`, `rpeSesion`, `duracionMinutos`, `cargaDiaria`, `sesionId`, timestamps |

### 4.3. Providers nuevos

| Provider | Tipo | Tabla/Origen | Método de consulta |
|----------|------|-------------|-------------------|
| `estadoCognitivoProvider` | `FutureProvider<EstadoCognitivoUsuarioDb?>` | `estado_cognitivo_usuario` | `.eq('usuario_id', user.id).maybeSingle()` |
| `estadoRegulacionCruzadaProvider` | `FutureProvider<EstadoRegulacionCruzadaDb?>` | `estado_regulacion_cruzada` | `.eq('usuario_id', user.id).maybeSingle()` |
| `caloriasEstudioHoyProvider` | `FutureProvider<double>` | `horarios_academicos` | SUM `calorias_quemadas` donde `completado=true` y `hora_inicio` entre inicio/fin del día local |
| `cargaFisicaHoyProvider` | `FutureProvider<double>` | `registros_carga_fisica` | `carga_diaria` donde `fecha_registro` entre inicio/fin del día local |
| `cargaFisicaMaximaProvider` | `FutureProvider<double>` | `registros_carga_fisica` | MAX `carga_diaria` histórica (`.order('carga_diaria', ascending: false).limit(1)`) |
| `tMaxEstudioProvider` | `Provider<int>` | Derivado | `calcularTmaxEstudio(90, acwrActual)` desde `estadoRegulacionCruzadaProvider` |

#### Regla de timezone para providers de fecha

Todos los providers que consultan por fecha usan el patrón de límites de día local.
**Nunca** se usa `DateTime.now().toUtc().toIso8601String().substring(0, 10)`.
El patrón correcto es:

```dart
final ahora = DateTime.now();                  // hora local del dispositivo
final inicio = DateTime(ahora.year, ahora.month, ahora.day);
final fin = inicio.add(const Duration(days: 1));
// .gte('fecha_registro', inicio.toIso8601String().substring(0, 10))
// .lt('fecha_registro', fin.toIso8601String().substring(0, 10))
```

---

## 5. Fase 4: Modificación de Servicios Existentes

### 5.1. `RecomendacionContextoService.calcularAjustes()`

**Archivo:** `app/lib/features/bienestar/infrastructure/recomendacion_contexto_service.dart`

**Cambio:** Añadir capa de ajuste asintótico por regulación cruzada **después** del cálculo FCT y **antes** de los ajustes escalonados existentes. Usa `min()` para no duplicar penalizaciones con los ajustes preexistentes.

```dart
// NUEVO: capa de regulación cruzada por proximidad de exámenes
final crossRegState = ref.read(estadoRegulacionCruzadaProvider).valueOrNull;
final diasExamen = crossRegState?.diasProximoExamen ?? 999;
final vMod = CrossRegulationService.calcularVolumenModificado(
  volumenBase: 1.0,
  cargaCognitiva: fct,
  cargaMaxima: 1.0,
  diasHastaExamen: diasExamen,
);
final ajusteAsintotico = vMod.clamp(0.4, 1.0);
if (ajusteAsintotico < factorVolumen) {
  factorVolumen = ajusteAsintotico;
  motivos.add('Regulación cruzada: examen en $diasExamen días');
}
// ... continúan los ajustes existentes (modoExamenes, FCT, energía, sueño, etc.)
```

### 5.2. `TimeBlockIaService` + `InboxConfig`

**Archivos:**
- `app/lib/features/academico/infrastructure/timeblock_ia_service.dart`
- `app/lib/features/academico/domain/calendar_dtos.dart`

**Cambios:**

1. Añadir campo `int tMaxEstudioMinutos` a `InboxConfig` (default: 90)
2. Modificar regla N3 del prompt de Gemini para que use el valor dinámico:
   ```
   N3. DURACIÓN MÁXIMA DE ESTUDIO: Ningún bloque de estudio debe superar
   ${config.tMaxEstudioMinutos} minutos.
   ```
3. En `_generarHeuristico()`: usar `config.tMaxEstudioMinutos` en lugar del `clamp(1.0, 2.0)` horas hardcodeado

### 5.3. `rutina_provider.dart` — Nuevos métodos

**Archivo:** `app/lib/features/bienestar/application/rutina_provider.dart`

#### 5.3.1. `finalizarSesion()` — Añadir post-procesamiento

Después de la línea que persiste la sesión (`duracion_minutos`, `rpe`, `calorias_quemadas`), añadir:

```dart
// Recalcular estado de regulación cruzada (el trigger ya insertó la carga)
await client.rpc('recalcular_regulacion_cruzada', params: {
  'p_usuario_id': user!.id,
});
```

#### 5.3.2. `desmarcarSesion()` — NUEVO (reversibilidad física)

```dart
/// Revierte una sesión completada: desmarca, activa trigger de eliminación
/// de carga física, recalcula ACWR y emite evento inverso al SyncHub.
Future<void> desmarcarSesion({
  required String sesionId,
  required String diaId,
  required String rutinaId,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return;

  await client.from('sesiones_registradas').update({
    'completada_en': null,
    'rpe': null,
    'duracion_minutos': 0,
    'calorias_quemadas': null,
  }).eq('id', sesionId);

  await actualizarEstadoDia(diaId, 'pendiente', ref);

  // El trigger trg_insertar_carga_fisica elimina automáticamente el registro
  await client.rpc('recalcular_regulacion_cruzada', params: {
    'p_usuario_id': user.id,
  });

  ref.invalidate(diasDeSemanaProvider);
  ref.invalidate(semanasDeRutinaProvider(rutinaId));
  ref.invalidate(perfilActividadProvider);

  ref.read(syncHubProvider).dispatch(
    DominioEvento.sesionDesmarcada,
    payload: EventoPayload(sesionId: sesionId),
  );
}
```

#### 5.3.3. `completarBloqueEstudio()` — NUEVO

```dart
/// Marca un horario_academico como completado, calcula gasto calórico
/// (Mifflin-St Jeor), carga cognitiva generada y actualiza estado_cognitivo_usuario.
Future<void> completarBloqueEstudio({
  required String horarioId,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser!;

  // 1. Obtener datos del bloque y asignatura
  final bloque = await client.from('horarios_academicos')
      .select('hora_inicio, hora_fin, tipo_actividad, asignatura_id')
      .eq('id', horarioId).single();

  final asignatura = bloque['asignatura_id'] != null
      ? await client.from('asignaturas')
            .select('dificultad').eq('id', bloque['asignatura_id']).maybeSingle()
      : null;

  // 2. RMR desde perfil_bienestar_usuario
  final perfil = await client.from('perfil_bienestar_usuario')
      .select('peso_kg, altura_cm, edad, sexo')
      .eq('usuario_id', user.id).single();

  final rmr = StudyCalorieService.calcularRMR(
    pesoKg: (perfil['peso_kg'] as num).toDouble(),
    alturaCm: (perfil['altura_cm'] as num).toDouble(),
    edad: perfil['edad'] as int,
    sexo: perfil['sexo'] as String,
  );

  // 3. Calcular duración, calorías y carga cognitiva
  final inicio = DateTime.parse(bloque['hora_inicio'] as String);
  final fin = DateTime.parse(bloque['hora_fin'] as String);
  final duracionSeg = fin.difference(inicio).inSeconds;
  final met = StudyCalorieService.metCognitivoParaActividad(
    bloque['tipo_actividad'] as String? ?? 'estudio',
  );
  final calorias = StudyCalorieService.calcularGastoEstudio(
    rmr: rmr, duracionSegundos: duracionSeg, metValue: met,
  );
  final mu = CognitiveLoadCalculatorService.dificultadAsignatura(
    asignatura?['dificultad'] as String?,
  );
  final carga = CognitiveLoadCalculatorService.calcularCargaAcumulada(bloques: [
    (duracionMin: duracionSeg / 60, dificultad: mu, descansoMin: 0),
  ]);

  // 4. Persistir en horarios_academicos
  await client.from('horarios_academicos').update({
    'completado': true,
    'calorias_quemadas': calorias,
    'carga_cognitiva_generada': carga,
    'met_value': met,
  }).eq('id', horarioId);

  // 5. Actualizar estado cognitivo del usuario
  final estadoAnterior = await client.from('estado_cognitivo_usuario')
      .select('carga_cognitiva_actual, capacidad_atencion_actual')
      .eq('usuario_id', user.id).single();

  final nuevaCarga = ((estadoAnterior['carga_cognitiva_actual'] as num)
          .toDouble() + carga).clamp(0.0, 1.0);
  final nuevaCapacidad = CognitiveLoadCalculatorService.capacidadAtencional(
    capacidadInicial: (estadoAnterior['capacidad_atencion_actual'] as num)
        .toDouble(),
    minutosTranscurridos: duracionSeg ~/ 60,
  );

  await client.from('estado_cognitivo_usuario').update({
    'carga_cognitiva_actual': nuevaCarga,
    'capacidad_atencion_actual': nuevaCapacidad,
    'duracion_ultimo_bloque_min': duracionSeg ~/ 60,
    'rmr_base': rmr,
  }).eq('usuario_id', user.id);

  ref.read(syncHubProvider).dispatch(
    DominioEvento.bloqueEstudioCompletado,
    payload: EventoPayload(horarioId: horarioId),
  );
}
```

#### 5.3.4. `desmarcarBloqueEstudio()` — NUEVO (reversibilidad académica)

```dart
/// Revierte un bloque de estudio completado: resta carga cognitiva,
/// resetea calorías y met_value, y revierte XP si se otorgó.
Future<void> desmarcarBloqueEstudio({
  required String horarioId,
  required WidgetRef ref,
}) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser!;

  // 1. Leer carga cognitiva previa y flag XP de este bloque
  final bloque = await client.from('horarios_academicos')
      .select('carga_cognitiva_generada, xp_bloque_otorgado')
      .eq('id', horarioId).single();

  final cargaPrevia =
      (bloque['carga_cognitiva_generada'] as num?)?.toDouble() ?? 0;

  // 2. Restar carga cognitiva del estado (clamp evita negativos)
  final estado = await client.from('estado_cognitivo_usuario')
      .select('carga_cognitiva_actual')
      .eq('usuario_id', user.id).single();

  await client.from('estado_cognitivo_usuario').update({
    'carga_cognitiva_actual':
        ((estado['carga_cognitiva_actual'] as num).toDouble() - cargaPrevia)
            .clamp(0.0, 1.0),
  }).eq('usuario_id', user.id);

  // 3. Resetear el bloque (calorías y carga a null)
  await client.from('horarios_academicos').update({
    'completado': false,
    'calorias_quemadas': null,
    'carga_cognitiva_generada': null,
    'met_value': null,
  }).eq('id', horarioId);

  // 4. Reversibilidad de XP si ya se otorgó por este bloque
  if (bloque['xp_bloque_otorgado'] == true) {
    await client.rpc('restar_xp', params: {
      'p_usuario_id': user.id,
      'p_cantidad': 15, // XP base por bloque completado
    });
    await client.from('horarios_academicos').update({
      'xp_bloque_otorgado': false,
    }).eq('id', horarioId);
  }

  ref.read(syncHubProvider).dispatch(
    DominioEvento.bloqueEstudioDesmarcado,
    payload: EventoPayload(horarioId: horarioId),
  );
}
```

### 5.4. Flujo SM-2-Physio en práctica

Ubicado en `practica_provider.dart` o `practica_screen.dart` (donde se orqueste la calificación del repaso):

```dart
// 1. Calcular Q_adj (sin mapeo a 0-2 — se pasa directamente a SM-2 en 0-5)
final qAdj = Sm2PhysioService.calcularQAdj(
  qReal: calificacionUsuario, // 0-5
  cargaFisicaHoy: cargaHoy,
  cargaFisicaMaxima: cargaMax,
);

// 2. Q_adj se pasa como double exacto a SM-2 (sin redondear — la fórmula EF lo necesita)
final resultado = Sm2Calculator.calcular(
  calidad: qAdj, // double continuo [0.0, 5.0], sin .round()
  intervaloActualDias: material.intervaloActualDias,
  facilidad: material.facilidad,
  repasosCompletados: material.repasosCompletados,
);

// 3. Persistir en materiales_estudio con los nuevos valores SM-2
await client.from('materiales_estudio').update({
  'facilidad': resultado.facilidad,
  'intervalo_actual_dias': resultado.intervaloDias,
  'siguiente_repaso_en': DateTime.now()
      .add(Duration(days: resultado.intervaloDias))
      .toIso8601String(),
  'estado_dominio': resultado.estadoDominio,
  'repasos_completados': resultado.repasosCompletados,
  'ultimo_repaso_en': DateTime.now().toIso8601String(),
}).eq('id', material.id);

// 4. Auditoría inmutable en registros_repaso_srs
await client.from('registros_repaso_srs').insert({
  'material_estudio_id': material.id,
  'fecha_repaso': DateTime.now().toIso8601String(),
  'q_real': calificacionUsuario,
  'q_ajustado': qAdj,
  'coeficiente_fatiga': cargaMax > 0 ? cargaHoy / cargaMax : 0,
});
```

### 5.5. `SyncHub` — Ampliación de eventos e invalidaciones

**Archivo:** `app/lib/core/sync/sync_hub.dart`

#### 5.5.1. `DominioEvento` enum — Nuevos valores

```dart
enum DominioEvento {
  // ... valores existentes sin cambios ...
  planGuardado,
  bloqueEstudioCompletado,
  bloqueEstudioDesmarcado,      // NUEVO — reversibilidad
  sesionCompletada,
  sesionDesmarcada,              // NUEVO — reversibilidad
  checkInRealizado,
  entregaCompletada,
  retoCompletado,
  pomodoroCompletado,
  xpOtorgado,
  practicaCompletada,
}
```

#### 5.5.2. Mapa de invalidaciones ampliado

Los eventos de ida y vuelta comparten las mismas invalidaciones (reversibilidad simétrica):

```dart
case DominioEvento.sesionCompletada:
case DominioEvento.sesionDesmarcada:
  invalids.addAll([
    // Nuevos providers de fatiga y regulación
    estadoRegulacionCruzadaProvider,
    estadoCognitivoProvider,
    tMaxEstudioProvider,
    cargaFisicaHoyProvider,
    cargaFisicaMaximaProvider,
    // Providers existentes
    timelineHoyProvider,
    dashboardProvider,
    progresoRetosProvider,
    retosActivosProvider,
    rachaStateProvider,
    catalogoInsigniasProvider,
  ]);
  break;

case DominioEvento.bloqueEstudioCompletado:
case DominioEvento.bloqueEstudioDesmarcado:
  invalids.addAll([
    estadoCognitivoProvider,
    caloriasEstudioHoyProvider,
    tMaxEstudioProvider,
    timelineHoyProvider,
    dashboardProvider,
    cargaAcademicaSemanalProvider,
    adherenciaAcademicaProvider,
    progresoRetosProvider,
  ]);
  break;
```

---

## 6. Fase 5: UI — Flat Design + Español

### 6.1. `CognitiveLoadBar` — Nueva fuente de datos

**Archivo:** `app/lib/features/dashboard/presentation/widgets/cognitive_load_bar.dart`

**Cambio:** Leer de `estadoCognitivoProvider` en lugar de `cargaCognitivaProvider`.

```dart
final cogState = ref.watch(estadoCognitivoProvider).valueOrNull;
final valor = (cogState?.capacidadAtencionActual ?? 1.0) * 100;
// valor mapeado de 0.000–1.000 a 0–100
```

Etiquetas: `'Baja'`, `'Moderada'`, `'Alta'`, `'Crítica'`. Umbrales de color sin cambios.
Flat Design: `elevation: 0` (ya lo es actualmente).

### 6.2. `CanvasScreen` — Chip kcal en bloques de estudio

**Archivo:** `app/lib/features/academico/presentation/canvas_screen.dart`

En `TimeBlockWidget`, si `tipo == estudio && caloriasQuemadas != null`, mostrar chip plano:

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
  decoration: BoxDecoration(
    color: Colors.orange.withOpacity(0.1),
    borderRadius: BorderRadius.circular(3),
    // Sin boxShadow — Flat Design
  ),
  child: Text(
    '${caloriasQuemadas!.round()} kcal',
    style: TextStyle(fontSize: 9, color: Colors.orange.shade300),
  ),
)
```

Toggle de completado: si `completado` pasa de false→true llama a `completarBloqueEstudio()`, si pasa de true→false llama a `desmarcarBloqueEstudio()`.

### 6.3. `CrossRegulationIndicator` — Widget de cabecera fija

**Archivo:** `app/lib/features/dashboard/presentation/widgets/cross_regulation_indicator.dart`
**Nuevo archivo.**

Widget estático con `SizedBox(height: 48)`, ubicado en la cabecera del Dashboard, **fuera** de cualquier scroll. Visible solo si `ACWR > 1.3` o `diasProximoExamen < 7`.

```dart
final cross = ref.watch(estadoRegulacionCruzadaProvider).valueOrNull;
if (cross == null) return const SizedBox.shrink();
if (cross.acwrActual <= 1.3 && (cross.diasProximoExamen ?? 999) >= 7) {
  return const SizedBox.shrink();
}

return SizedBox(
  height: 48,
  child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: cross.acwrActual > 1.5
          ? Colors.red.withOpacity(0.08)
          : Colors.amber.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(/* icono + etiquetas en español */),
  ),
);
```

Textos: `'Carga óptima'`, `'Fatiga detectada'`, `'Examen en X días'`, `'Tope de estudio: X min'`.

### 6.4. `DashboardScreen` — Chip "Tu cerebro también entrena"

**Archivo:** `app/lib/features/dashboard/presentation/dashboard_screen.dart`

```dart
final kcalEstudio = ref.watch(caloriasEstudioHoyProvider).valueOrNull ?? 0;
if (kcalEstudio > 0) {
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      '🧠 Tu cerebro también entrena: +${kcalEstudio.round()} kcal hoy estudiando',
      style: TextStyle(fontSize: 12, color: Colors.orange.shade300),
    ),
  ),
}
```

Flat Design: sin sombras, sin elevación.

### 6.5. `PracticaScreen` — Botones con Q_adj pre-calculado

**Archivo:** `app/lib/features/academico/presentation/practica_screen.dart`

Al abrir el modal de autoevaluación (escala 0-5), pre-calcular para cada botón el intervalo resultante tras aplicar `Q_adj`. Esto garantiza que el texto del botón coincida exactamente con lo que se guardará en BD:

```dart
final cargaHoy = ref.watch(cargaFisicaHoyProvider).valueOrNull ?? 0;
final cargaMax = ref.watch(cargaFisicaMaximaProvider).valueOrNull ?? 0;

const etiquetas = [
  'Olvido total',
  'Casi nada',
  'Con dificultad',
  'Con esfuerzo',
  'Casi perfecto',
  'Perfecto',
];

for (var q = 0; q <= 5; q++) {
  final qAdj = Sm2PhysioService.calcularQAdj(
    qReal: q, cargaFisicaHoy: cargaHoy, cargaFisicaMaxima: cargaMax,
  );
  final res = Sm2Calculator.calcular(
    calidad: qAdj, // double exacto, sin .round() — la fórmula EF requiere precisión decimal
    intervaloActualDias: material.intervaloActualDias,
    facilidad: material.facilidad,
    repasosCompletados: material.repasosCompletados,
  );
  // UI: "${etiquetas[q]} — ${res.intervaloDias} d"
}
```

### 6.6. `PerfilScreen` — Gasto calórico diario desglosado

**Archivo:** `app/lib/features/perfil/presentation/perfil_screen.dart`

```dart
Card(
  elevation: 0,
  child: Column(
    children: [
      Text('🔥 Gasto calórico hoy', style: ...),
      Text('${totalKcal.round()} kcal'),
      const Divider(height: 1),
      Text('🏋️ Entrenamiento: ${kcalEjercicio.round()} kcal'),
      Text('🧠 Estudio:        ${kcalEstudio.round()} kcal'),
    ],
  ),
)
```

### 6.7. Toggles de reversibilidad en UI

| Pantalla | Acción | Método llamado |
|----------|--------|---------------|
| `CanvasScreen` / Timeline | Toggle completar/desmarcar bloque | `completarBloqueEstudio()` / `desmarcarBloqueEstudio()` |
| `RutinaDetalleScreen` / Sesiones | Toggle completar/desmarcar sesión | `finalizarSesion()` / `desmarcarSesion()` |

---

## 7. Fase 6 (Opcional): Gamificación Unificada

> Esta fase es independiente de las fórmulas neurofisiológicas y puede implementarse posteriormente.

### 7.1. Migración `20260701000029_xp_unificado.sql`

- `CREATE TABLE libro_mayor_xp` (insert-only, `domain_type` CHECK IN ('ACADEMIC', 'PHYSICAL'), `base_xp`, `n_consecutive`, `neglected_bonus_days`, `net_xp_awarded`)
- `CREATE TABLE perfil_gamificacion_usuario` (1:1 cache con `total_xp` BIGINT, `current_level` INTEGER GENERATED, `last_domain_trained` VARCHAR, `current_streak_count` INTEGER)

### 7.2. Fórmula de XP Unificado

```
XP_net = BaseXP / log₂(n_consecutive + 1) · (1 + 0.10 · D_neglected)

  donde:
    n_consecutive = eventos consecutivos del mismo dominio (ACADEMIC o PHYSICAL)
    D_neglected   = días desde el último evento del dominio opuesto
    BaseXP        = XP base de la actividad (50 para sesión, 30 para bloque)
```

### 7.3. Mecánicas

- **Rendimiento decreciente logarítmico:** encadenar tareas del mismo dominio reduce el XP exponencialmente (previene grinding)
- **Bono por Músculo Olvidado:** +10% por cada día sin actividad en el dominio opuesto (incentiva alternancia estudio↔deporte)
- **Racha de dominio:** tracking en `perfil_gamificacion_usuario.current_streak_count`

---

## 8. Protocolo de Reversibilidad

### 8.1. Matriz de operaciones ida/vuelta

| Operación | IDA | VUELTA | Trigger BD | Evento SyncHub |
|---|---|---|---|---|
| Sesión física | `finalizarSesion()` | `desmarcarSesion()` | `trg_insertar_carga_fisica` (INSERT/DELETE) | `sesionCompletada` / `sesionDesmarcada` |
| Bloque estudio | `completarBloqueEstudio()` | `desmarcarBloqueEstudio()` | — (lógica en Dart) | `bloqueEstudioCompletado` / `bloqueEstudioDesmarcado` |
| XP | `otorgar_xp(p_cantidad)` RPC | `restar_xp(p_cantidad)` RPC | — | — |
| Carga cognitiva | Suma a `carga_cognitiva_actual` | Resta con `.clamp(0.0, 1.0)` | — | `estadoCognitivoProvider` |
| Calorías estudio | `calorias_quemadas` poblado | `calorias_quemadas = NULL` | — | `caloriasEstudioHoyProvider` (SUM recalculado) |
| ACWR | Recalculado al alza | Recalculado a la baja | — | `estadoRegulacionCruzadaProvider` |

### 8.2. Funciones RPC utilizadas

| RPC | Propósito | Parámetros | Origen |
|-----|----------|-----------|--------|
| `recalcular_regulacion_cruzada` | Recalcula carga aguda 7d, carga crónica 28d y ACWR | `p_usuario_id UUID` | Nueva (migración 00028) |
| `restar_xp` | Resta XP con bajada de nivel segura (inverso de `otorgar_xp`) | `p_usuario_id UUID`, `p_cantidad INTEGER` | Existente (migración `20260622000007`) |

### 8.3. Garantías del protocolo

1. **Atomicidad de reversión:** la ruta de vuelta siempre resetea exactamente los mismos campos que la ruta de ida modificó, en orden inverso
2. **No-duplicación de carga:** el trigger SQL es `AFTER UPDATE` con guarda `OLD IS DISTINCT FROM NEW`, previniendo inserciones duplicadas
3. **No-negatividad:** todos los valores restados usan `.clamp(0.0, double.infinity)` o `NULLIF` en SQL
4. **Invalidación simétrica:** los eventos `*Desmarcado` invalidan exactamente los mismos providers que sus contrapartes `*Completado`
5. **Auditoría inmutable:** `registros_repaso_srs` y `registros_carga_fisica` son insert-only (o delete por trigger). Nunca se UPDATEan.

---

## 9. Resumen de Archivos

| # | Archivo | Acción | Fase | Estado |
|---|---------|--------|------|--------|
| 1 | `supabase/migrations/20260701000027_cognitive_study_cost.sql` | Crear | 1 | ✅ |
| 2 | `supabase/migrations/20260701000028_physical_workload_and_srs.sql` | Crear | 1 | ✅ |
| 3 | `app/lib/features/bienestar/infrastructure/study_calorie_service.dart` | Crear | 2 | ✅ |
| 4 | `app/lib/features/bienestar/infrastructure/cognitive_load_calculator_service.dart` | Crear | 2 | ✅ |
| 5 | `app/lib/features/bienestar/infrastructure/cross_regulation_service.dart` | Crear | 2 | ✅ |
| 6 | `app/lib/features/academico/infrastructure/sm2_physio_service.dart` | Crear | 2 | ✅ |
| 7 | `app/lib/features/academico/infrastructure/sm2_calculator.dart` | Modificar | 3 | ✅ |
| 8 | `app/lib/shared/models/db_models.dart` | Modificar | 3 | ✅ |
| 9 | `app/lib/features/bienestar/application/neurofisiologia_provider.dart` | Crear | 3 | ✅ |
| 10 | `app/lib/core/sync/dominio_evento.dart` | Modificar | 4 | ✅ |
| 11 | `app/lib/core/sync/sync_hub.dart` | Modificar | 4 | ✅ |
| 12 | `app/lib/features/bienestar/application/rutina_provider.dart` | Modificar | 4 | ✅ |
| 13 | `app/lib/features/bienestar/infrastructure/recomendacion_contexto_service.dart` | Modificar | 4 | ✅ |
| 14 | `app/lib/features/academico/infrastructure/timeblock_ia_service.dart` | Modificar | 4 | ✅ |
| 15 | `app/lib/features/academico/domain/calendar_dtos.dart` | Modificar | 4 | ✅ |
| 16 | `app/lib/features/dashboard/presentation/widgets/cognitive_load_bar.dart` | Modificar | 5 | ✅ |
| 17 | `app/lib/features/dashboard/presentation/widgets/cross_regulation_indicator.dart` | Crear | 5 | ✅ |
| 18 | `app/lib/features/dashboard/presentation/dashboard_screen.dart` | Modificar | 5 | ✅ |
| 19 | `app/lib/features/academico/presentation/practica_screen.dart` | Modificar | 5 | ✅ |
| 20 | `app/lib/features/perfil/presentation/perfil_screen.dart` | Modificar | 5 | ✅ |

**Total:** 8 archivos nuevos, 12 archivos modificados (el archivo `neurofisiologia_provider.dart` se añade como nuevo en Fase 3, compensando el que `cognitive_load_bar.dart` ya existía).

---

## 10. Principios de Diseño

| Principio | Aplicación en el plan |
|---|---|
| **Español en BD** | Todas las tablas, columnas, triggers y RPC usan nombres en español (`estado_cognitivo_usuario`, `registros_carga_fisica`, `estado_regulacion_cruzada`, `registros_repaso_srs`) |
| **Extender vs. duplicar** | Columnas añadidas a `horarios_academicos` en lugar de tabla paralela. SM-2 usa `materiales_estudio` existente + tabla de auditoría ligera |
| **Flat Design estricto** | `elevation: 0`, sin `boxShadow`, fondos con `.withOpacity(0.08–0.1)`, sin carruseles redundantes ni scroll anidado |
| **Getter SUM en tiempo real** | `caloriasEstudioHoyProvider` agrega desde BD sin columna acumulativa que requiera triggers de escritura adicionales |
| **Timezone seguro** | Límites de día local (`DateTime(año, mes, día)`) en todos los providers de fecha. Nunca substring hacks de UTC |
| **SyncHub exhaustivo** | Invalidación de providers de fatiga + retos + timeline + insignias, tanto para eventos de ida como de vuelta |
| **Reversibilidad total** | Toda operación de completar tiene su contraparte de desmarcar: trigger SQL bidireccional, métodos Dart `desmarcar*`, eventos `*Desmarcado` en SyncHub |
| **SM-2 escala 0-5** | `Sm2Calculator` modificado para rango 0-5 con fórmula `(5−q)` en EF. `Sm2PhysioService` solo calcula `Q_adj`, sin mapeos intermedios |
| **Trigger con cronómetro real** | `trg_insertar_carga_fisica` usa `NEW.duracion_minutos` (poblado por el cliente desde el cronómetro), no diferencias de timestamps que pueden abarcar días entre planificación y ejecución |
| **Idioma UI** | Todo texto visible, etiqueta, unidad de medida y opción de menú en español |
| **Servicios puros** | Todos los servicios nuevos son clases con métodos estáticos sin estado ni I/O. La lógica de negocio está separada de la capa de datos |

---

## 11. Estado de Implementación

### Fases Completadas (v8.0 — 01-07-2026)

| Fase | Descripción | Archivos | Estado |
|------|-------------|----------|--------|
| **Fase 1** | Migraciones Supabase | 2 migraciones nuevas (00027, 00028), 4 tablas (`estado_cognitivo_usuario`, `estado_regulacion_cruzada`, `registros_carga_fisica`, `registros_repaso_srs`), 3 columnas en `horarios_academicos` (`met_value`, `calorias_quemadas`, `carga_cognitiva_generada`), 2 triggers (`trg_inicializar_estado_cognitivo`, `trg_insertar_carga_fisica`), 1 RPC (`recalcular_regulacion_cruzada`) | ✅ COMPLETADO |
| **Fase 2** | Servicios Dart | 4 servicios estáticos: `StudyCalorieService` (Mifflin-St Jeor + MET Cognitivo), `CognitiveLoadCalculatorService` (C_acum exponencial), `CrossRegulationService` (V_mod asintótico + T_max por tramos ACWR), `Sm2PhysioService` (Q_adj por fatiga serotoninérgica) | ✅ COMPLETADO |
| **Fase 3** | DTOs y Providers | `neurofisiologia_provider.dart` con 6 providers (`estadoCognitivoProvider`, `estadoRegulacionCruzadaProvider`, `caloriasEstudioHoyProvider`, `cargaFisicaHoyProvider`, `cargaFisicaMaximaProvider`, `tMaxEstudioProvider`); 4 DTOs en `db_models.dart` (`EstadoCognitivoUsuarioDb`, `EstadoRegulacionCruzadaDb`, `RegistroRepasoSrsDb`, `RegistroCargaFisicaDb`); `Sm2Calculator` modificado a escala 0-5 con parámetro `double` para EF, umbral fallo `calidad.round() < 3`, fórmula `(5−q)`, clamp EF [1.3, 3.0] | ✅ COMPLETADO |
| **Fase 4** | Modificación de Servicios | `RecomendacionContextoService` con ajuste asintótico por regulación cruzada (`diasProximoExamen`); `InboxConfig.tMaxEstudioMinutos` (default 90); `TimeBlockIaService` con regla H3 dinámica; `finalizarSesion()` llama RPC `recalcular_regulacion_cruzada`; nuevos métodos `desmarcarSesion()`, `completarBloqueEstudio()`, `desmarcarBloqueEstudio()` en `rutina_provider.dart`; nuevos eventos `bloqueEstudioDesmarcado`, `sesionDesmarcada` en `DominioEvento`; SyncHub ampliado con invalidación simétrica ida/vuelta + providers neurofisiológicos + retos | ✅ COMPLETADO |
| **Fase 5** | UI Flat Design | `CrossRegulationIndicator` (48px, alertas ACWR/examen); `_EstudioCaloriasChip` ("Tu cerebro también entrena"); `CognitiveLoadBar` lee `capacidadAtencionActual` desde `estadoCognitivoProvider`; `DashboardScreen` integra ambos widgets; `PracticaScreen` con modal 5 niveles (0-5) e intervalos pre-calculados por `Sm2PhysioService` + auditoría `registros_repaso_srs`; `PerfilScreen` tarjeta `🔥 Gasto calórico hoy` con desglose 🏋️/🧠 desde `caloriasEstudioHoyProvider` | ✅ COMPLETADO |
| **Fase 6** | Gamificación Unificada | No iniciada — pendiente de decisión de producto | ⏳ PENDIENTE |

### Métricas de Implementación

| Métrica | Valor |
|---------|-------|
| Archivos nuevos | 9 |
| Archivos modificados | 11 |
| Tablas BD nuevas | 4 |
| Columnas nuevas (en tabla existente) | 3 |
| Triggers BD | 2 |
| RPC nuevas | 1 |
| Providers Riverpod nuevos | 6 |
| DTOs Dart nuevos | 4 |
| Servicios estáticos nuevos | 4 |
| Widgets Flat Design nuevos | 2 |
| Eventos SyncHub nuevos | 2 |
| Métodos Dart nuevos (mutaciones) | 3 |
