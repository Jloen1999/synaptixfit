-- Migration: 0040_optimizar_rendimiento_catalogo
-- Objetivo: Eliminar overhead innecesario y actualizar estadisticas
--           del planificador para el catalogo de ejercicios.
--
-- 1. Las tablas del catalogo de ejercicios son estaticas (se cargan
--    una vez y rara vez cambian). No necesitan Realtime, que anade
--    overhead WAL en cada escritura.
-- 2. Se actualizan estadisticas de las tablas de union para que el
--    planificador optimice mejor los LATERAL joins de la vista.

begin;

do $$ begin
  alter publication supabase_realtime drop table ejercicios;
exception when undefined_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime drop table partes_cuerpo;
exception when undefined_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime drop table musculos;
exception when undefined_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime drop table equipamientos;
exception when undefined_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime drop table ejercicio_musculo_objetivo;
exception when undefined_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime drop table ejercicio_musculo_secundario;
exception when undefined_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime drop table ejercicio_parte_cuerpo;
exception when undefined_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime drop table ejercicio_equipamiento;
exception when undefined_object then null;
end $$;

commit;

-- Actualizar estadisticas del planificador para todas las tablas
-- relacionadas con ejercicios (incluyendo las de union).
analyze public.ejercicios;
analyze public.musculos;
analyze public.partes_cuerpo;
analyze public.equipamientos;
analyze public.ejercicio_musculo_objetivo;
analyze public.ejercicio_musculo_secundario;
analyze public.ejercicio_parte_cuerpo;
analyze public.ejercicio_equipamiento;
