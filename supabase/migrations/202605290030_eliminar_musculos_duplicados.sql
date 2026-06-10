-- Migration: 0030_eliminar_musculos_duplicados
-- Objetivo: Eliminar musculos redundantes y migrar sus referencias
--           en las tablas puente (ejercicio_musculo_objetivo,
--           ejercicio_musculo_secundario) hacia el musculo canónico.


-- abdominales -> abdomen
update public.ejercicio_musculo_objetivo
  set musculo_id = (select id from public.musculos where nombre = 'abdomen')
  where musculo_id = (select id from public.musculos where nombre = 'abdominales');

update public.ejercicio_musculo_secundario
  set musculo_id = (select id from public.musculos where nombre = 'abdomen')
  where musculo_id = (select id from public.musculos where nombre = 'abdominales');

-- deltoides anteriores -> deltoides anterior
update public.ejercicio_musculo_objetivo
  set musculo_id = (select id from public.musculos where nombre = 'deltoides anterior')
  where musculo_id = (select id from public.musculos where nombre = 'deltoides anteriores');

update public.ejercicio_musculo_secundario
  set musculo_id = (select id from public.musculos where nombre = 'deltoides anterior')
  where musculo_id = (select id from public.musculos where nombre = 'deltoides anteriores');

-- dorsales -> dorsal ancho
update public.ejercicio_musculo_objetivo
  set musculo_id = (select id from public.musculos where nombre = 'dorsal ancho')
  where musculo_id = (select id from public.musculos where nombre = 'dorsales');

update public.ejercicio_musculo_secundario
  set musculo_id = (select id from public.musculos where nombre = 'dorsal ancho')
  where musculo_id = (select id from public.musculos where nombre = 'dorsales');

-- glúteos -> glúteo mayor
update public.ejercicio_musculo_objetivo
  set musculo_id = (select id from public.musculos where nombre = 'glúteo mayor')
  where musculo_id = (select id from public.musculos where nombre = 'glúteos');

update public.ejercicio_musculo_secundario
  set musculo_id = (select id from public.musculos where nombre = 'glúteo mayor')
  where musculo_id = (select id from public.musculos where nombre = 'glúteos');

-- hombros -> deltoides
update public.ejercicio_musculo_objetivo
  set musculo_id = (select id from public.musculos where nombre = 'deltoides')
  where musculo_id = (select id from public.musculos where nombre = 'hombros');

update public.ejercicio_musculo_secundario
  set musculo_id = (select id from public.musculos where nombre = 'deltoides')
  where musculo_id = (select id from public.musculos where nombre = 'hombros');

-- parte interna del muslo -> aductores
update public.ejercicio_musculo_objetivo
  set musculo_id = (select id from public.musculos where nombre = 'aductores')
  where musculo_id = (select id from public.musculos where nombre = 'parte interna del muslo');

update public.ejercicio_musculo_secundario
  set musculo_id = (select id from public.musculos where nombre = 'aductores')
  where musculo_id = (select id from public.musculos where nombre = 'parte interna del muslo');

-- pectorales -> pecho
update public.ejercicio_musculo_objetivo
  set musculo_id = (select id from public.musculos where nombre = 'pecho')
  where musculo_id = (select id from public.musculos where nombre = 'pectorales');

update public.ejercicio_musculo_secundario
  set musculo_id = (select id from public.musculos where nombre = 'pecho')
  where musculo_id = (select id from public.musculos where nombre = 'pectorales');

-- tibiales -> tibial anterior
update public.ejercicio_musculo_objetivo
  set musculo_id = (select id from public.musculos where nombre = 'tibial anterior')
  where musculo_id = (select id from public.musculos where nombre = 'tibiales');

update public.ejercicio_musculo_secundario
  set musculo_id = (select id from public.musculos where nombre = 'tibial anterior')
  where musculo_id = (select id from public.musculos where nombre = 'tibiales');

-- tobillos -> estabilizadores de tobillo
update public.ejercicio_musculo_objetivo
  set musculo_id = (select id from public.musculos where nombre = 'estabilizadores de tobillo')
  where musculo_id = (select id from public.musculos where nombre = 'tobillos');

update public.ejercicio_musculo_secundario
  set musculo_id = (select id from public.musculos where nombre = 'estabilizadores de tobillo')
  where musculo_id = (select id from public.musculos where nombre = 'tobillos');

delete from public.musculos where nombre = 'abdominales';
delete from public.musculos where nombre = 'deltoides anteriores';
delete from public.musculos where nombre = 'dorsales';
delete from public.musculos where nombre = 'glúteos';
delete from public.musculos where nombre = 'hombros';
delete from public.musculos where nombre = 'parte interna del muslo';
delete from public.musculos where nombre = 'pectorales';
delete from public.musculos where nombre = 'tibiales';
delete from public.musculos where nombre = 'tobillos';
