-- Retos v2 — Deep-linking: sincronización bidireccional reto/tarea ⇄ examen/entrega.
--
-- Si un reto o una subtarea tiene entidad_vinculada_id apuntando a una fila de
-- entregas_examenes, al completar/descompletar cualquiera de los dos lados el
-- otro se actualiza solo (server-side, fiable, venga del lienzo o de la app).
--
-- Coherencia de XP: el lado entrega→reto otorga/resta XP usando la MISMA guarda
-- xp_otorgado que la lógica Dart (Fase 5), por lo que nunca hay doble otorgado.
-- Anti-bucle: triggers con WHEN (OLD <> NEW) + UPDATE guardado con IS DISTINCT.

BEGIN;

-- Helper: XP por dificultad (espejo de xpPorDificultad en Dart).
CREATE OR REPLACE FUNCTION public.xp_por_dificultad(p_dif text)
RETURNS integer
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_dif WHEN 'baja' THEN 20 WHEN 'alta' THEN 70 ELSE 40 END;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- entrega/examen → reto/hito (sincroniza estado + ajusta XP exacto)
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.sync_entrega_a_reto()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
declare
  r record;
  v_xp integer;
begin
  -- Retos vinculados.
  for r in
    select id, usuario_id, dificultad, xp_otorgado
    from public.retos
    where entidad_vinculada_id = NEW.id
      and esta_completado is distinct from NEW.esta_completado
  loop
    if NEW.esta_completado then
      v_xp := public.xp_por_dificultad(r.dificultad);
      if r.xp_otorgado = 0 then
        perform public.otorgar_xp(r.usuario_id, v_xp);
        update public.retos
          set esta_completado = true, xp_otorgado = v_xp, actualizado_en = now()
          where id = r.id;
      else
        update public.retos
          set esta_completado = true, actualizado_en = now()
          where id = r.id;
      end if;
    else
      if r.xp_otorgado > 0 then
        perform public.restar_xp(r.usuario_id, r.xp_otorgado);
      end if;
      update public.retos
        set esta_completado = false, xp_otorgado = 0, actualizado_en = now()
        where id = r.id;
    end if;
  end loop;

  -- Subtareas (hitos) vinculadas.
  for r in
    select h.id, h.dificultad, h.xp_otorgado, rr.usuario_id
    from public.hitos_de_reto h
    join public.retos rr on rr.id = h.reto_id
    where h.entidad_vinculada_id = NEW.id
      and h.esta_completado is distinct from NEW.esta_completado
  loop
    if NEW.esta_completado then
      v_xp := public.xp_por_dificultad(r.dificultad);
      if r.xp_otorgado = 0 then
        perform public.otorgar_xp(r.usuario_id, v_xp);
        update public.hitos_de_reto
          set esta_completado = true, progreso_actual = 100,
              estado = 'completado', xp_otorgado = v_xp
          where id = r.id;
      else
        update public.hitos_de_reto
          set esta_completado = true, progreso_actual = 100, estado = 'completado'
          where id = r.id;
      end if;
    else
      if r.xp_otorgado > 0 then
        perform public.restar_xp(r.usuario_id, r.xp_otorgado);
      end if;
      update public.hitos_de_reto
        set esta_completado = false, progreso_actual = 0,
            estado = 'en_progreso', xp_otorgado = 0
        where id = r.id;
    end if;
  end loop;

  return NEW;
end;
$$;

DROP TRIGGER IF EXISTS trg_sync_entrega_a_reto ON public.entregas_examenes;
CREATE TRIGGER trg_sync_entrega_a_reto
  AFTER UPDATE OF esta_completado ON public.entregas_examenes
  FOR EACH ROW
  WHEN (OLD.esta_completado IS DISTINCT FROM NEW.esta_completado)
  EXECUTE FUNCTION public.sync_entrega_a_reto();

-- ───────────────────────────────────────────────────────────────────────────
-- reto → entrega (solo estado; el XP ya lo gestiona el otro lado)
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.sync_reto_a_entrega()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
begin
  if NEW.entidad_vinculada_id is not null then
    update public.entregas_examenes
      set esta_completado = NEW.esta_completado
      where id = NEW.entidad_vinculada_id
        and esta_completado is distinct from NEW.esta_completado;
  end if;
  return NEW;
end;
$$;

DROP TRIGGER IF EXISTS trg_sync_reto_a_entrega ON public.retos;
CREATE TRIGGER trg_sync_reto_a_entrega
  AFTER UPDATE OF esta_completado ON public.retos
  FOR EACH ROW
  WHEN (OLD.esta_completado IS DISTINCT FROM NEW.esta_completado)
  EXECUTE FUNCTION public.sync_reto_a_entrega();

-- ───────────────────────────────────────────────────────────────────────────
-- hito → entrega
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.sync_hito_a_entrega()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
begin
  if NEW.entidad_vinculada_id is not null then
    update public.entregas_examenes
      set esta_completado = NEW.esta_completado
      where id = NEW.entidad_vinculada_id
        and esta_completado is distinct from NEW.esta_completado;
  end if;
  return NEW;
end;
$$;

DROP TRIGGER IF EXISTS trg_sync_hito_a_entrega ON public.hitos_de_reto;
CREATE TRIGGER trg_sync_hito_a_entrega
  AFTER UPDATE OF esta_completado ON public.hitos_de_reto
  FOR EACH ROW
  WHEN (OLD.esta_completado IS DISTINCT FROM NEW.esta_completado)
  EXECUTE FUNCTION public.sync_hito_a_entrega();

COMMIT;
