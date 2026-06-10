-- Migration: Agregar RLS para tablas de bienestar
-- Fecha: 2026-04-21
-- Propósito: Habilitar Row Level Security en tablas perfil_bienestar_usuario,
--           historial_peso y plan_entrenamiento_semanal para permitir que
--           los usuarios accedan solo a sus propios datos.

begin;

-- Habilitar RLS en las tablas de bienestar
alter table if exists public.perfil_bienestar_usuario enable row level security;
alter table if exists public.historial_peso enable row level security;
alter table if exists public.plan_entrenamiento_semanal enable row level security;

-- =============================================================================
-- Políticas para perfil_bienestar_usuario
-- =============================================================================
-- Cada usuario puede ver y modificar solo su propio perfil de bienestar

drop policy if exists perfil_bienestar_select on public.perfil_bienestar_usuario;
create policy perfil_bienestar_select on public.perfil_bienestar_usuario
for select
using (auth.uid() = usuario_id);

drop policy if exists perfil_bienestar_insert on public.perfil_bienestar_usuario;
create policy perfil_bienestar_insert on public.perfil_bienestar_usuario
for insert
with check (auth.uid() = usuario_id);

drop policy if exists perfil_bienestar_update on public.perfil_bienestar_usuario;
create policy perfil_bienestar_update on public.perfil_bienestar_usuario
for update
using (auth.uid() = usuario_id)
with check (auth.uid() = usuario_id);

-- No permitir eliminación del perfil de bienestar
-- (Es un dato crítico del onboarding que no debería borrarse)

-- =============================================================================
-- Políticas para historial_peso
-- =============================================================================
-- Cada usuario puede ver y agregar historiales de peso solo de sí mismo

drop policy if exists historial_peso_select on public.historial_peso;
create policy historial_peso_select on public.historial_peso
for select
using (auth.uid() = usuario_id);

drop policy if exists historial_peso_insert on public.historial_peso;
create policy historial_peso_insert on public.historial_peso
for insert
with check (auth.uid() = usuario_id);

-- Los registros históricos no se pueden actualizar (append-only)
-- No se permite DELETE

-- =============================================================================
-- Políticas para plan_entrenamiento_semanal
-- =============================================================================
-- Cada usuario puede ver, crear y actualizar solo sus propios planes

drop policy if exists plan_entrenamiento_select on public.plan_entrenamiento_semanal;
create policy plan_entrenamiento_select on public.plan_entrenamiento_semanal
for select
using (auth.uid() = usuario_id);

drop policy if exists plan_entrenamiento_insert on public.plan_entrenamiento_semanal;
create policy plan_entrenamiento_insert on public.plan_entrenamiento_semanal
for insert
with check (auth.uid() = usuario_id);

drop policy if exists plan_entrenamiento_update on public.plan_entrenamiento_semanal;
create policy plan_entrenamiento_update on public.plan_entrenamiento_semanal
for update
using (auth.uid() = usuario_id)
with check (auth.uid() = usuario_id);

drop policy if exists plan_entrenamiento_delete on public.plan_entrenamiento_semanal;
create policy plan_entrenamiento_delete on public.plan_entrenamiento_semanal
for delete
using (auth.uid() = usuario_id);

commit;
