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
