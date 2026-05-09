-- Enable realtime for exercise catalog tables so the frontend
-- syncs automatically when exercises are inserted, updated or deleted.
begin;

alter publication supabase_realtime add table ejercicios;
alter publication supabase_realtime add table partes_cuerpo;
alter publication supabase_realtime add table musculos;
alter publication supabase_realtime add table equipamientos;
alter publication supabase_realtime add table ejercicio_musculo_objetivo;
alter publication supabase_realtime add table ejercicio_musculo_secundario;
alter publication supabase_realtime add table ejercicio_parte_cuerpo;
alter publication supabase_realtime add table ejercicio_equipamiento;

commit;
