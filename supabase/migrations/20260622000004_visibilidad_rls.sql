-- Visibilidad efectiva: activa RLS en rutinas, retos y horarios_academicos
-- (bloques de estudio) y aplica la privacidad del perfil + la visibilidad por
-- ítem. Incluye:
--   * Funciones SECURITY DEFINER (evitan recursión de RLS y son eficientes).
--   * Política del dueño (CRUD completo sobre lo suyo).
--   * Política de admin (acceso total, para el panel de administración).
--   * Política de lectura para pares según privacidad + amistades aceptadas.
--   * Trigger que, al poner el perfil en 'privado', invalida (vuelve 'private')
--     cualquier rutina o reto que estuviera en 'public'/'friends'.
--
-- NOTA: hasta ahora estas 3 tablas tenían RLS DESACTIVADO. La app depende del
-- filtrado por usuario_id en el cliente; estas políticas lo refuerzan en BD
-- sin romper los flujos del dueño ni del admin.

BEGIN;

-- ───────────────────────────────────────────────────────────────────────────
-- Helpers (SECURITY DEFINER → ignoran RLS de las tablas que consultan)
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.es_admin(p_uid uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.usuarios WHERE id = p_uid AND rol = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.nivel_privacidad_de(p_uid uuid)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT nivel_privacidad FROM public.usuarios WHERE id = p_uid;
$$;

CREATE OR REPLACE FUNCTION public.son_amigos(p_a uuid, p_b uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.amistades
    WHERE estado = 'aceptada'
      AND ((solicitante_id = p_a AND receptor_id = p_b)
        OR (solicitante_id = p_b AND receptor_id = p_a))
  );
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- Trigger de invalidación: perfil → 'privado' obliga a privatizar el contenido
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.invalidar_contenido_al_privatizar()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.nivel_privacidad = 'privado'
     AND NEW.nivel_privacidad IS DISTINCT FROM OLD.nivel_privacidad THEN
    UPDATE public.rutinas SET visibilidad = 'private'
      WHERE usuario_id = NEW.id AND visibilidad <> 'private';
    UPDATE public.retos SET visibilidad = 'private'
      WHERE usuario_id = NEW.id AND visibilidad <> 'private';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_invalidar_contenido_privado ON public.usuarios;
CREATE TRIGGER trg_invalidar_contenido_privado
  AFTER UPDATE OF nivel_privacidad ON public.usuarios
  FOR EACH ROW
  EXECUTE FUNCTION public.invalidar_contenido_al_privatizar();

-- ───────────────────────────────────────────────────────────────────────────
-- RUTINAS
-- ───────────────────────────────────────────────────────────────────────────
ALTER TABLE public.rutinas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS rutinas_owner_all ON public.rutinas;
CREATE POLICY rutinas_owner_all ON public.rutinas
  FOR ALL
  USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS rutinas_admin_all ON public.rutinas;
CREATE POLICY rutinas_admin_all ON public.rutinas
  FOR ALL
  USING (public.es_admin(auth.uid()))
  WITH CHECK (public.es_admin(auth.uid()));

DROP POLICY IF EXISTS rutinas_peer_select ON public.rutinas;
CREATE POLICY rutinas_peer_select ON public.rutinas
  FOR SELECT
  USING (
    public.nivel_privacidad_de(usuario_id) <> 'privado'
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

-- ───────────────────────────────────────────────────────────────────────────
-- RETOS
-- ───────────────────────────────────────────────────────────────────────────
ALTER TABLE public.retos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS retos_owner_all ON public.retos;
CREATE POLICY retos_owner_all ON public.retos
  FOR ALL
  USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS retos_admin_all ON public.retos;
CREATE POLICY retos_admin_all ON public.retos
  FOR ALL
  USING (public.es_admin(auth.uid()))
  WITH CHECK (public.es_admin(auth.uid()));

DROP POLICY IF EXISTS retos_peer_select ON public.retos;
CREATE POLICY retos_peer_select ON public.retos
  FOR SELECT
  USING (
    public.nivel_privacidad_de(usuario_id) <> 'privado'
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

-- ───────────────────────────────────────────────────────────────────────────
-- HORARIOS_ACADEMICOS (bloques de estudio) — sin flag por ítem: la visibilidad
-- se rige por la privacidad del perfil del dueño.
-- ───────────────────────────────────────────────────────────────────────────
ALTER TABLE public.horarios_academicos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS horarios_owner_all ON public.horarios_academicos;
CREATE POLICY horarios_owner_all ON public.horarios_academicos
  FOR ALL
  USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS horarios_admin_all ON public.horarios_academicos;
CREATE POLICY horarios_admin_all ON public.horarios_academicos
  FOR ALL
  USING (public.es_admin(auth.uid()))
  WITH CHECK (public.es_admin(auth.uid()));

DROP POLICY IF EXISTS horarios_peer_select ON public.horarios_academicos;
CREATE POLICY horarios_peer_select ON public.horarios_academicos
  FOR SELECT
  USING (
    public.nivel_privacidad_de(usuario_id) = 'publico'
    OR (
      public.nivel_privacidad_de(usuario_id) = 'amigos'
      AND public.son_amigos(auth.uid(), usuario_id)
    )
  );

COMMIT;
