-- Fix: Subida de nivel inmediata con arrastre del sobrante (multinivel).
-- PROBLEMA: la versión anterior solo subía UN nivel por llamada. Si una
--   recompensa superaba varios umbrales (o dejaba xp_total >= umbral del nuevo
--   nivel), la UI mostraba un "valor superado" (ej. 300/200 XP) que no tiene
--   sentido.
-- AHORA: se itera mientras el XP acumulado alcance el umbral del nivel actual,
--   restando el umbral y subiendo de nivel en cada vuelta. El sobrante final
--   queda como XP inicial del siguiente nivel y SIEMPRE es menor que el umbral,
--   por lo que nunca se muestra un valor por encima del objetivo.
-- Umbral del nivel N = 100 * N (consistente con la UI: nivel * 100).

CREATE OR REPLACE FUNCTION public.otorgar_xp(p_usuario_id uuid, p_cantidad_xp integer)
RETURNS TABLE(nuevo_nivel integer, nueva_xp integer, sube_nivel boolean)
LANGUAGE plpgsql
AS $$
declare
  v_nivel int;
  v_xp int;
  v_umbral int;
  v_subio boolean := false;
begin
  if p_cantidad_xp <= 0 then
    raise exception 'p_cantidad_xp debe ser mayor a 0';
  end if;

  select u.nivel, u.xp_total
  into v_nivel, v_xp
  from public.usuarios u
  where u.id = p_usuario_id
  for update;

  if not found then
    raise exception 'Usuario % no existe', p_usuario_id;
  end if;

  v_xp := v_xp + p_cantidad_xp;

  v_umbral := 100 * v_nivel;
  while v_xp >= v_umbral loop
    v_xp := v_xp - v_umbral;
    v_nivel := v_nivel + 1;
    v_subio := true;
    v_umbral := 100 * v_nivel;
  end loop;

  update public.usuarios
  set nivel = v_nivel,
      xp_total = v_xp,
      actualizado_en = now()
  where id = p_usuario_id;

  nuevo_nivel := v_nivel;
  nueva_xp := v_xp;
  sube_nivel := v_subio;
  return next;
end;
$$;
