-- ============================================================================
-- Migración 20260701000029: Shadowban + Modo Pánico (Trust & Safety)
-- ============================================================================

BEGIN;

-- ── A. Columna is_shadowbanned en usuarios ─────────────────────────────────
ALTER TABLE public.usuarios ADD COLUMN IF NOT EXISTS is_shadowbanned BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_usuarios_shadowbanned ON public.usuarios(is_shadowbanned)
  WHERE is_shadowbanned = true;

-- ── B. Tabla configuracion_global (fila única, semáforo de plataforma) ────
CREATE TABLE IF NOT EXISTS public.configuracion_global (
    id                      BOOLEAN PRIMARY KEY DEFAULT true CHECK (id = true),
    lockdown_activo         BOOLEAN NOT NULL DEFAULT false,
    lockdown_iniciado_en    TIMESTAMPTZ,
    lockdown_iniciado_por   UUID REFERENCES public.usuarios(id),
    actualizado_en          TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO public.configuracion_global (id) VALUES (true) ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.configuracion_global ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin read config" ON public.configuracion_global;
CREATE POLICY "Admin read config" ON public.configuracion_global
  FOR SELECT USING (public.es_admin(auth.uid()));

DROP POLICY IF EXISTS "Admin update config" ON public.configuracion_global;
CREATE POLICY "Admin update config" ON public.configuracion_global
  FOR UPDATE USING (public.es_admin(auth.uid()))
  WITH CHECK (public.es_admin(auth.uid()));

-- ── C. Helpers SECURITY DEFINER ────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.lockdown_activo()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT lockdown_activo FROM public.configuracion_global WHERE id = true),
    false
  );
$$;

CREATE OR REPLACE FUNCTION public.excluir_si_shadowban(p_autor_id UUID)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT
    auth.uid() = p_autor_id
    OR public.es_admin(auth.uid())
    OR NOT EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = p_autor_id AND is_shadowbanned = true
    );
$$;

GRANT EXECUTE ON FUNCTION public.lockdown_activo() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.excluir_si_shadowban(UUID) TO authenticated, anon;

-- ── D. RLS tablas sociales: SELECT + shadowban, INSERT + lockdown ─────────

-- actividades_sociales: SELECT
DROP POLICY IF EXISTS "Lectura publica actividades" ON public.actividades_sociales;
DROP POLICY IF EXISTS "Lectura filtrada shadowban" ON public.actividades_sociales;
CREATE POLICY "Lectura filtrada shadowban" ON public.actividades_sociales
  FOR SELECT USING (public.excluir_si_shadowban(usuario_id));

-- actividades_sociales: INSERT
DROP POLICY IF EXISTS "Insercion authenticated actividades" ON public.actividades_sociales;
DROP POLICY IF EXISTS "Insercion con lockdown" ON public.actividades_sociales;
CREATE POLICY "Insercion con lockdown" ON public.actividades_sociales
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated'
    AND auth.uid() = usuario_id
    AND (NOT public.lockdown_activo() OR public.es_admin(auth.uid()))
  );

-- comentarios_feed: SELECT
DROP POLICY IF EXISTS "Lectura publica comentarios" ON public.comentarios_feed;
DROP POLICY IF EXISTS "Lectura filtrada shadowban" ON public.comentarios_feed;
CREATE POLICY "Lectura filtrada shadowban" ON public.comentarios_feed
  FOR SELECT USING (public.excluir_si_shadowban(usuario_id));

-- comentarios_feed: INSERT
DROP POLICY IF EXISTS "Insercion authenticated comentarios" ON public.comentarios_feed;
DROP POLICY IF EXISTS "Insercion con lockdown" ON public.comentarios_feed;
CREATE POLICY "Insercion con lockdown" ON public.comentarios_feed
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated'
    AND auth.uid() = usuario_id
    AND (NOT public.lockdown_activo() OR public.es_admin(auth.uid()))
  );

-- interacciones_sociales: SELECT
DROP POLICY IF EXISTS "Lectura publica interacciones" ON public.interacciones_sociales;
DROP POLICY IF EXISTS "Lectura filtrada shadowban" ON public.interacciones_sociales;
CREATE POLICY "Lectura filtrada shadowban" ON public.interacciones_sociales
  FOR SELECT USING (public.excluir_si_shadowban(usuario_id));

-- interacciones_sociales: INSERT
DROP POLICY IF EXISTS "Insercion authenticated interacciones" ON public.interacciones_sociales;
DROP POLICY IF EXISTS "Insercion con lockdown" ON public.interacciones_sociales;
CREATE POLICY "Insercion con lockdown" ON public.interacciones_sociales
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated'
    AND auth.uid() = usuario_id
    AND (NOT public.lockdown_activo() OR public.es_admin(auth.uid()))
  );

-- ── E. Contenido peer-visible: añadir filtro shadowban a peer_select ──────

-- rutinas_peer_select
DROP POLICY IF EXISTS rutinas_peer_select ON public.rutinas;
CREATE POLICY rutinas_peer_select ON public.rutinas
  FOR SELECT
  USING (
    public.excluir_si_shadowban(usuario_id)
    AND public.nivel_privacidad_de(usuario_id) <> 'privado'
    AND visibilidad <> 'private'
    AND (
      (visibilidad = 'public'
        AND public.nivel_privacidad_de(usuario_id) = 'publico')
      OR (
        (visibilidad = 'friends'
          OR public.nivel_privacidad_de(usuario_id) = 'amigos')
        AND public.son_amigos(auth.uid(), usuario_id)
      )
    )
  );

-- retos_peer_select
DROP POLICY IF EXISTS retos_peer_select ON public.retos;
CREATE POLICY retos_peer_select ON public.retos
  FOR SELECT
  USING (
    public.excluir_si_shadowban(usuario_id)
    AND public.nivel_privacidad_de(usuario_id) <> 'privado'
    AND visibilidad <> 'private'
    AND (
      (visibilidad = 'public'
        AND public.nivel_privacidad_de(usuario_id) = 'publico')
      OR (
        (visibilidad = 'friends'
          OR public.nivel_privacidad_de(usuario_id) = 'amigos')
        AND public.son_amigos(auth.uid(), usuario_id)
      )
    )
  );

-- horarios_peer_select
DROP POLICY IF EXISTS horarios_peer_select ON public.horarios_academicos;
CREATE POLICY horarios_peer_select ON public.horarios_academicos
  FOR SELECT
  USING (
    public.excluir_si_shadowban(usuario_id)
    AND (
      public.nivel_privacidad_de(usuario_id) = 'publico'
      OR (
        public.nivel_privacidad_de(usuario_id) = 'amigos'
        AND public.son_amigos(auth.uid(), usuario_id)
      )
    )
  );

-- ── F. Trigger: auto-shadowban cuentas creadas durante lockdown ────────────

CREATE OR REPLACE FUNCTION public.shadowban_nuevo_si_lockdown()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.lockdown_activo() THEN
    NEW.is_shadowbanned := true;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_lockdown_shadowban_nuevo ON public.usuarios;
CREATE TRIGGER trg_lockdown_shadowban_nuevo
  BEFORE INSERT ON public.usuarios
  FOR EACH ROW
  EXECUTE FUNCTION public.shadowban_nuevo_si_lockdown();

-- ── G. Trigger: auditoría de cambios en configuracion_global ──────────────

CREATE OR REPLACE FUNCTION public.auditar_cambio_config_global()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.admin_auditoria (admin_id, accion, entidad, detalle)
  VALUES (
    auth.uid(),
    CASE
      WHEN NEW.lockdown_activo AND OLD.lockdown_activo IS DISTINCT FROM NEW.lockdown_activo
        THEN 'activar_lockdown'
      WHEN NOT NEW.lockdown_activo AND OLD.lockdown_activo IS DISTINCT FROM NEW.lockdown_activo
        THEN 'desactivar_lockdown'
      ELSE 'actualizar_config_global'
    END,
    'configuracion_global',
    jsonb_build_object(
      'lockdown_previo', OLD.lockdown_activo,
      'lockdown_nuevo', NEW.lockdown_activo
    )
  );
  NEW.actualizado_en := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auditar_config_global ON public.configuracion_global;
CREATE TRIGGER trg_auditar_config_global
  BEFORE UPDATE ON public.configuracion_global
  FOR EACH ROW
  EXECUTE FUNCTION public.auditar_cambio_config_global();

COMMIT;
