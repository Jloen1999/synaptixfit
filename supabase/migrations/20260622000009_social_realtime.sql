-- ============================================================
-- Migración: Muro social en tiempo real
-- Añade las tablas sociales a la publicación `supabase_realtime` para que
-- el feed se actualice de forma inmediata (insert/update/delete) sin recarga
-- manual. Idempotente: solo añade la tabla si aún no está publicada.
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'actividades_sociales'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.actividades_sociales;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'interacciones_sociales'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.interacciones_sociales;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'comentarios_feed'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.comentarios_feed;
  END IF;
END $$;

-- REPLICA IDENTITY FULL para recibir la fila completa en UPDATE/DELETE.
ALTER TABLE public.actividades_sociales REPLICA IDENTITY FULL;
ALTER TABLE public.interacciones_sociales REPLICA IDENTITY FULL;
ALTER TABLE public.comentarios_feed REPLICA IDENTITY FULL;

-- Reaseguramos la lectura pública del feed (idempotente) por si la migración
-- 20260616000002_social_moderacion no se aplicó en algún entorno.
ALTER TABLE public.actividades_sociales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lectura publica actividades" ON public.actividades_sociales;
CREATE POLICY "Lectura publica actividades" ON public.actividades_sociales
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Insercion authenticated actividades" ON public.actividades_sociales;
CREATE POLICY "Insercion authenticated actividades" ON public.actividades_sociales
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = usuario_id);
