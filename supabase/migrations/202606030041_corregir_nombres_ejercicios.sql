-- Migration: 0041_corregir_nombres_ejercicios
-- Objetivo: Corregir 5 ejercicios cuyo nombre quedo como 'A'
--           (placeholder generado al migrar dataset_final.json con nombre null).
--
-- Los nombres correctos se derivan de los nombres de archivo en las URLs.
-- dataset_final.json no tiene campo 'nombre', por lo que el generador
-- de la migracion 0038 uso 'A' como fallback para valores null.

begin;

update public.ejercicios
set nombre = 'Hyght Dumbbell Fly'
where id = 'c63ebc00-0964-4bef-84f6-8d081a3b87ba';

update public.ejercicios
set nombre = 'Hyght Dumbbell Fly (female)'
where id = '7ae6a411-b3ee-433e-83ab-24aec7a7a457';

update public.ejercicios
set nombre = 'Bodyweight Bent Over Rear Delt Fly'
where id = '991c00e5-3f48-49a5-87be-85ac9b1ca58f';

update public.ejercicios
set nombre = 'Lying Floor Fly'
where id = '33b43a86-d7ce-4139-bc72-6aeed0f87285';

update public.ejercicios
set nombre = 'Bodyweight Standing Fly (male)'
where id = '77494be3-1d70-4071-90fb-69fa82b64dd5';

commit;
