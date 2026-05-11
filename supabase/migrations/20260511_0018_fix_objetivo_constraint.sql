-- =============================================================================
-- Migración 0018: Corrige constraint de objetivo en rutinas
-- Los valores válidos deben coincidir con PerfilBienestarDb.objetivoPrincipal
-- =============================================================================

begin;

-- Mapear 'hipertrofia' (valor legacy) a 'ganar_masa' (nuevo estándar)
update public.rutinas
  set objetivo = 'ganar_masa'
  where objetivo = 'hipertrofia';

alter table public.rutinas
  drop constraint if exists rutinas_objetivo_check;

alter table public.rutinas
  add constraint rutinas_objetivo_check
    check (objetivo in (
      'fitness_general',
      'perder_peso',
      'ganar_masa',
      'fuerza',
      'resistencia',
      'movilidad',
      'mixto'
    ));

commit;
