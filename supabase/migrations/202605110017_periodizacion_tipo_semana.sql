-- =============================================================================
-- Migración 0017: Periodización inteligente — tipo de semana
-- Añade tipo_semana a semanas_rutina para que la IA pueda planificar
-- microciclos (adaptación, carga, pico, descarga) automáticamente.
-- =============================================================================

begin;

alter table public.semanas_rutina
  add column if not exists tipo_semana text
  check (tipo_semana in ('adaptacion', 'carga', 'pico', 'descarga'))
  default 'carga';

-- Índice para consultas rápidas de periodización
create index if not exists idx_semanas_rutina_tipo
  on public.semanas_rutina (rutina_id, numero_semana, tipo_semana);

commit;
