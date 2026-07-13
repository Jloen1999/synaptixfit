-- ============================================================================
-- MIGRACIONES PENDIENTES — Ejecutar en Supabase SQL Editor
-- Proyecto: bimivpacrelltwfwrdnq
-- Fecha: 12/06/2026
-- Sprint 7
-- ============================================================================

-- ============================================================================
-- Migración 202606120050: Dependencias entre hitos de retos
-- ============================================================================
ALTER TABLE retos
  ADD COLUMN IF NOT EXISTS tiene_dependencias BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE hitos_de_reto
  ADD COLUMN IF NOT EXISTS estado TEXT NOT NULL DEFAULT 'bloqueado'
    CHECK (estado IN ('bloqueado', 'disponible', 'en_progreso', 'completado')),
  ADD COLUMN IF NOT EXISTS dependencias UUID[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS tipo_condicion TEXT NOT NULL DEFAULT 'AND'
    CHECK (tipo_condicion IN ('AND', 'OR', 'X_OF_Y')),
  ADD COLUMN IF NOT EXISTS condicion_n INTEGER NOT NULL DEFAULT 1
    CHECK (condicion_n >= 1);

UPDATE hitos_de_reto
SET estado = CASE
  WHEN esta_completado THEN 'completado'
  ELSE 'disponible'
END
WHERE estado = 'bloqueado';

CREATE OR REPLACE FUNCTION public.desbloquear_hitos(p_reto_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  h RECORD;
  completadas INT;
  total_deps INT;
BEGIN
  FOR h IN SELECT * FROM public.hitos_de_reto
    WHERE reto_id = p_reto_id
      AND estado = 'bloqueado'
      AND dependencias IS NOT NULL
      AND array_length(dependencias, 1) > 0
  LOOP
    total_deps := array_length(h.dependencias, 1);

    SELECT COUNT(*) INTO completadas
    FROM public.hitos_de_reto dep
    WHERE dep.id = ANY(h.dependencias) AND dep.estado = 'completado';

    IF h.tipo_condicion = 'AND' AND completadas = total_deps THEN
      UPDATE public.hitos_de_reto SET estado = 'disponible' WHERE id = h.id;
    ELSIF h.tipo_condicion = 'OR' AND completadas >= 1 THEN
      UPDATE public.hitos_de_reto SET estado = 'disponible' WHERE id = h.id;
    ELSIF h.tipo_condicion = 'X_OF_Y' AND completadas >= h.condicion_n THEN
      UPDATE public.hitos_de_reto SET estado = 'disponible' WHERE id = h.id;
    END IF;
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.trigger_desbloquear_hitos()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.estado = 'completado' AND (OLD.estado IS NULL OR OLD.estado != 'completado') THEN
    PERFORM public.desbloquear_hitos(NEW.reto_id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_hito_completado ON public.hitos_de_reto;

CREATE TRIGGER trg_hito_completado
  AFTER UPDATE OF estado ON public.hitos_de_reto
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_desbloquear_hitos();

-- ============================================================================
-- Migración 202606140001: Vista analítica semanal
-- ============================================================================
CREATE OR REPLACE VIEW public.v_analitica_semanal AS
SELECT
  usuario_id,
  date_trunc('week', completada_en)::date AS semana_inicio,
  COUNT(*)::int AS sesiones,
  COALESCE(ROUND(AVG(rpe)::numeric, 1), 0) AS rpe_promedio,
  COALESCE(SUM(duracion_minutos), 0)::int AS minutos_totales,
  COALESCE(SUM(calorias_quemadas), 0)::int AS calorias_totales
FROM public.sesiones_registradas
WHERE completada_en IS NOT NULL
GROUP BY usuario_id, date_trunc('week', completada_en)::date
ORDER BY usuario_id, semana_inicio DESC;

-- ============================================================================
-- Migraciones 20260701000027 y 20260701000028: Fórmulas Neurofisiológicas
-- Fecha: 30/06/2026
-- Sprint: Integración de coste cognitivo, regulación cruzada y SM-2-Physio
-- ============================================================================

-- Migración: Coste cognitivo del estudio
-- Objetivo: Extender horarios_academicos con columnas de gasto calórico y carga cognitiva,
--           y crear el estado cognitivo por usuario (relación 1:1).
BEGIN;

-- 1. Extender horarios_academicos con columnas de coste cognitivo
ALTER TABLE public.horarios_academicos
  ADD COLUMN IF NOT EXISTS met_value               NUMERIC(4,2)  DEFAULT 1.30,
  ADD COLUMN IF NOT EXISTS calorias_quemadas       NUMERIC(6,2),
  ADD COLUMN IF NOT EXISTS carga_cognitiva_generada NUMERIC(6,4);

-- 2. Tabla de estado cognitivo (1:1 con usuarios, mutable en tiempo real)
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

-- 3. Trigger que inicializa el estado cognitivo al crear un usuario
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

-- 4. RLS
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


-- Migración: Carga física, regulación cruzada y auditoría SRS
-- Objetivo: Crear tablas de carga física diaria, estado de regulación cruzada (1:1 cache),
--           auditoría inmutable de repasos SRS, trigger bidireccional y RPC de recálculo.
BEGIN;

-- 1. Registros de carga física diaria (eventos atómicos, insert-only desde trigger)
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

-- 2. Estado de regulación cruzada (1:1 con usuarios, cache materializado)
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

-- 3. Auditoría inmutable de repasos SRS (q_real + q_ajustado según el paper)
CREATE TABLE IF NOT EXISTS public.registros_repaso_srs (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  material_estudio_id  UUID NOT NULL REFERENCES public.materiales_estudio(id) ON DELETE CASCADE,
  fecha_repaso         TIMESTAMPTZ NOT NULL DEFAULT now(),
  q_real               SMALLINT NOT NULL CHECK (q_real BETWEEN 0 AND 5),
  q_ajustado           NUMERIC(3,2) NOT NULL,
  coeficiente_fatiga   NUMERIC(4,3) NOT NULL DEFAULT 0,
  creado_en            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Trigger BIDIRECCIONAL de carga física
--    IDA:  inserta carga cuando completada_en pasa de NULL a fecha
--    VUELTA: elimina carga cuando completada_en pasa de fecha a NULL
--    Usa NEW.duracion_minutos (cronómetro real del cliente), no timestamps.
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

-- 5. RPC: recalcular estado de regulación cruzada
--    Carga aguda = SUM carga_diaria últimos 7 días
--    Carga crónica = AVG carga_diaria últimos 28 días (suma / 28)
--    ACWR = aguda / crónica (generado por columna STORED en la tabla)
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

-- 6. RLS para todas las tablas nuevas
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

-- 7. Índices para consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_carga_fisica_usuario_fecha
  ON public.registros_carga_fisica(usuario_id, fecha_registro);
CREATE INDEX IF NOT EXISTS idx_carga_fisica_sesion
  ON public.registros_carga_fisica(sesion_id);
CREATE INDEX IF NOT EXISTS idx_repaso_srs_material
  ON public.registros_repaso_srs(material_estudio_id, fecha_repaso);

COMMIT;
