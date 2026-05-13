-- Migration: trigger de cascada dias_rutina → semanas_rutina
-- Mantiene semanas_rutina.estado sincronizado con el estado de sus días.
-- Si todos los días están 'completado' → semana 'completada'.
-- Si algún día no está 'completado' → semana 'pendiente'.

create or replace function public.actualizar_estado_semana()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_semana_id uuid;
begin
  v_semana_id := coalesce(new.semana_id, old.semana_id);

  update public.semanas_rutina
  set estado = case
    when (
      select bool_and(estado = 'completado')
      from public.dias_rutina
      where semana_id = v_semana_id
    ) then 'completada'
    else 'pendiente'
  end
  where id = v_semana_id;

  return null;
end;
$$;

drop trigger if exists trg_dias_rutina_estado on public.dias_rutina;

create trigger trg_dias_rutina_estado
  after insert or update of estado or delete on public.dias_rutina
  for each row
  execute function public.actualizar_estado_semana();
