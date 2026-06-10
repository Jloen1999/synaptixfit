-- Enable realtime for exercise catalog tables so the frontend
-- syncs automatically when exercises are inserted, updated or deleted.
begin;

do $$ begin
  alter publication supabase_realtime add table ejercicios;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table partes_cuerpo;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table musculos;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table equipamientos;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table ejercicio_musculo_objetivo;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table ejercicio_musculo_secundario;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table ejercicio_parte_cuerpo;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table ejercicio_equipamiento;
exception when duplicate_object then null;
end $$;

commit;
