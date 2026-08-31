-- Adjuntos a tareas de reto.
--
-- Cada tarea (hito) puede llevar UN único adjunto académico: o un apunte
-- (`apuntes`) o un archivo de asignatura (`archivos_asignatura`). Los nuevos
-- archivos subidos desde la creación de retos se registran también en
-- `archivos_asignatura`, por lo que aparecen en la pestaña Archivos de
-- Académico vinculados a la asignatura correspondiente.

ALTER TABLE public.hitos_de_reto
  ADD COLUMN IF NOT EXISTS apunte_id uuid REFERENCES public.apuntes(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS archivo_id uuid REFERENCES public.archivos_asignatura(id) ON DELETE SET NULL;

-- Solo uno de los dos adjuntos puede estar presente a la vez.
ALTER TABLE public.hitos_de_reto
  DROP CONSTRAINT IF EXISTS ck_hitos_adjunto_unico;
ALTER TABLE public.hitos_de_reto
  ADD CONSTRAINT ck_hitos_adjunto_unico CHECK (
    (apunte_id IS NULL) OR (archivo_id IS NULL)
  );

CREATE INDEX IF NOT EXISTS idx_hitos_de_reto_apunte
  ON public.hitos_de_reto(apunte_id);
CREATE INDEX IF NOT EXISTS idx_hitos_de_reto_archivo
  ON public.hitos_de_reto(archivo_id);
