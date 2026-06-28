-- Migration 0013 (20260622000013): archivos_asignatura
-- Repositorio de archivos (PDF, imágenes, diapositivas) adjuntos a una
-- asignatura. El binario físico vive en Cloudflare R2; aquí solo se guardan
-- los METADATOS y la clave de objeto (jerarquía estricta por IDs).
--
-- Clave de objeto en R2:
--   usuarios/{user_id}/asignaturas/{asignatura_id}/archivos/{timestamp}_{nombre.ext}

-- 1. Tabla de metadatos
CREATE TABLE IF NOT EXISTS public.archivos_asignatura (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id              uuid NOT NULL,
  asignatura_id           uuid NOT NULL REFERENCES public.asignaturas(id) ON DELETE CASCADE,
  nombre_archivo          text NOT NULL,
  cloudflare_object_key   text NOT NULL,
  url_publica_o_firmada   text NOT NULL,
  tamano_bytes            bigint NOT NULL DEFAULT 0,
  tipo_mime               text,
  creado_en               timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT ck_archivos_nombre_len CHECK (char_length(nombre_archivo) >= 1),
  CONSTRAINT ck_archivos_tamano_pos CHECK (tamano_bytes >= 0),
  CONSTRAINT uq_archivos_object_key UNIQUE (cloudflare_object_key)
);

-- 2. Índices
CREATE INDEX IF NOT EXISTS idx_archivos_asignatura
  ON public.archivos_asignatura (asignatura_id, creado_en DESC);
CREATE INDEX IF NOT EXISTS idx_archivos_usuario
  ON public.archivos_asignatura (usuario_id);

-- 3. RLS (propietario + bypass admin)
ALTER TABLE public.archivos_asignatura ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'archivos_asignatura'
      AND policyname = 'Propietario: lectura'
  ) THEN
    CREATE POLICY "Propietario: lectura"
      ON public.archivos_asignatura
      FOR SELECT USING (usuario_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'archivos_asignatura'
      AND policyname = 'Propietario: insert'
  ) THEN
    CREATE POLICY "Propietario: insert"
      ON public.archivos_asignatura
      FOR INSERT WITH CHECK (usuario_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'archivos_asignatura'
      AND policyname = 'Propietario: delete'
  ) THEN
    CREATE POLICY "Propietario: delete"
      ON public.archivos_asignatura
      FOR DELETE USING (usuario_id = auth.uid());
  END IF;
END $$;

-- 4. Admin bypass (es_admin existe desde migration 0006)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'es_admin'
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'archivos_asignatura'
      AND policyname = 'Admin: todo'
  ) THEN
    CREATE POLICY "Admin: todo"
      ON public.archivos_asignatura
      FOR ALL USING (public.es_admin())
      WITH CHECK (public.es_admin());
  END IF;
END $$;

-- 5. Limpieza al hacer wipe/delete de usuario: la FK ON DELETE CASCADE de la
--    asignatura ya arrastra los archivos. Adicionalmente, las funciones
--    wipe_user_data / delete_user pueden borrar por usuario_id si se desea.
