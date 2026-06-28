-- Fix: Alinear el umbral de subida de nivel con la UI.
-- ANTES: v_umbral = 1000 * nivel (la UI mostraba nivel * 100)
-- AHORA: v_umbral = 100 * nivel (consistente con la UI)

CREATE OR REPLACE FUNCTION public.otorgar_xp(p_usuario_id uuid, p_cantidad_xp integer)
RETURNS TABLE(nuevo_nivel integer, nueva_xp integer, sube_nivel boolean)
LANGUAGE plpgsql
AS $$
declare
  v_nivel_actual int;
  v_xp_actual int;
  v_umbral int;
  v_total int;
begin
  if p_cantidad_xp <= 0 then
    raise exception 'p_cantidad_xp debe ser mayor a 0';
  end if;

  select u.nivel, u.xp_total
  into v_nivel_actual, v_xp_actual
  from public.usuarios u
  where u.id = p_usuario_id
  for update;

  if not found then
    raise exception 'Usuario % no existe', p_usuario_id;
  end if;

  v_umbral := 100 * v_nivel_actual;
  v_total := v_xp_actual + p_cantidad_xp;

  if v_total >= v_umbral then
    update public.usuarios
    set nivel = nivel + 1,
        xp_total = v_total - v_umbral,
        actualizado_en = now()
    where id = p_usuario_id
    returning nivel, xp_total into nuevo_nivel, nueva_xp;

    sube_nivel := true;
  else
    update public.usuarios
    set xp_total = v_total,
        actualizado_en = now()
    where id = p_usuario_id
    returning nivel, xp_total into nuevo_nivel, nueva_xp;

    sube_nivel := false;
  end if;

  return next;
end;
$$;
