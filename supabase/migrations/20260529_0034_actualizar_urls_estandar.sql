-- Migration: 0034_actualizar_urls_estandar
-- Objetivo: Insertar /estandar/ en todas las URLs de ejercicios
--           para reflejar la nueva estructura de carpetas en R2.

update public.ejercicios set url_gif = replace(url_gif, 'ejercicios/demic/', 'ejercicios/demic/estandar/') where url_gif like '%ejercicios/demic/%' and url_gif not like '%demic/estandar/%';
update public.ejercicios set url_gif = replace(url_gif, 'ejercicios/exercisedb/', 'ejercicios/exercisedb/estandar/') where url_gif like '%ejercicios/exercisedb/%' and url_gif not like '%exercisedb/estandar/%';
update public.ejercicios set url_gif = replace(url_gif, 'ejercicios/gym_workout/', 'ejercicios/gym_workout/estandar/') where url_gif like '%ejercicios/gym_workout/%' and url_gif not like '%gym_workout/estandar/%';
update public.ejercicios set url_gif = replace(url_gif, 'ejercicios/cardio/', 'ejercicios/cardio/estandar/') where url_gif like '%ejercicios/cardio/%' and url_gif not like '%cardio/estandar/%';
update public.ejercicios set url_gif = replace(url_gif, 'ejercicios/synaptixfit/', 'ejercicios/synaptixfit/estandar/') where url_gif like '%ejercicios/synaptixfit/%' and url_gif not like '%synaptixfit/estandar/%';
