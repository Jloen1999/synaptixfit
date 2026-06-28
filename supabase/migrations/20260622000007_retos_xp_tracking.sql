-- Retos v2 — Fase 5: control exacto de XP (anti-farmeo).
--
--   * xp_otorgado: registra EXACTAMENTE cuánto XP se otorgó por el estado
--     completado actual de cada reto/hito. Permite restar la cantidad exacta
--     al deshacer y evita doble otorgado (farmeo).
--   * restar_xp(): inverso de otorgar_xp. Decrementa XP y, si cae por debajo
--     de 0, baja de nivel arrastrando el sobrante (umbral nivel N = 100*N),
--     con suelo en nivel 1 / 0 XP.

BEGIN;

ALTER TABLE public.retos
  ADD COLUMN IF NOT EXISTS xp_otorgado integer NOT NULL DEFAULT 0;

ALTER TABLE public.hitos_de_reto
  ADD COLUMN IF NOT EXISTS xp_otorgado integer NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION public.restar_xp(p_usuario_id uuid, p_cantidad_xp integer)
RETURNS TABLE(nuevo_nivel integer, nueva_xp integer)
LANGUAGE plpgsql
AS $$
declare
  v_nivel int;
  v_xp int;
  v_total int;
begin
  if p_cantidad_xp is null or p_cantidad_xp <= 0 then
    select u.nivel, u.xp_total into nuevo_nivel, nueva_xp
    from public.usuarios u where u.id = p_usuario_id;
    return next;
    return;
  end if;

  select u.nivel, u.xp_total
  into v_nivel, v_xp
  from public.usuarios u
  where u.id = p_usuario_id
  for update;

  if not found then
    return;
  end if;

  v_total := v_xp - p_cantidad_xp;

  -- Baja de nivel mientras el XP quede negativo (arrastre del sobrante).
  while v_total < 0 and v_nivel > 1 loop
    v_nivel := v_nivel - 1;
    v_total := v_total + (100 * v_nivel);
  end loop;

  if v_total < 0 then
    v_total := 0;
  end if;

  update public.usuarios
  set nivel = v_nivel,
      xp_total = v_total,
      actualizado_en = now()
  where id = p_usuario_id
  returning nivel, xp_total into nuevo_nivel, nueva_xp;

  return next;
end;
$$;

COMMIT;
