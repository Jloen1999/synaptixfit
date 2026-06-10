-- Migration: Reparar FK de bienestar hacia usuarios tras reset de esquema
-- Fecha: 2026-04-21
-- Objetivo:
-- 1) Reponer trigger de sincronización auth.users -> public.usuarios
-- 2) Backfill de filas faltantes en public.usuarios para usuarios ya existentes

begin;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.usuarios (id, email, nombre_completo, url_avatar)
  values (
    new.id,
    coalesce(new.email, new.id::text || '@local.invalid'),
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(coalesce(new.email, ''), '@', 1), 'usuario'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do update
    set email = excluded.email,
        nombre_completo = coalesce(excluded.nombre_completo, public.usuarios.nombre_completo),
        url_avatar = coalesce(excluded.url_avatar, public.usuarios.url_avatar),
        actualizado_en = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_auth_user();

insert into public.usuarios (id, email, nombre_completo, url_avatar)
select
  au.id,
  coalesce(au.email, au.id::text || '@local.invalid') as email,
  coalesce(au.raw_user_meta_data ->> 'full_name', split_part(coalesce(au.email, ''), '@', 1), 'usuario') as nombre_completo,
  au.raw_user_meta_data ->> 'avatar_url' as url_avatar
from auth.users au
left join public.usuarios u on u.id = au.id
where u.id is null;

commit;
