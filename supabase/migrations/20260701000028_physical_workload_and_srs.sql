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
