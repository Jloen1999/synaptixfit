-- Migration: documentos_ia_ampliar_check — añade 'guia_docente' a los CHECKs
--
-- La feature "Dashboard Inteligente de Asignatura" extrae datos de la guía
-- docente mediante IA y los persiste en documentos_ia. El nuevo valor
-- 'guia_docente' se usa tanto en fuente_tipo como en tipo, porque la
-- "fuente" es la asignatura misma (fuente_id = asignatura_id), no un
-- apunte ni un archivo individual.
--
-- Los CHECKs actuales solo permiten:
--   fuente_tipo IN ('apunte', 'archivo')
--   tipo        IN ('resumen', 'mapa_mental')

-- Los nombres de constraints CHECK autogenerados por Postgres siguen el
-- patrón {tabla}_{columna}_check. Usamos DROP IF EXISTS + ADD CONSTRAINT
-- con nombres canónicos para que sean predecibles en futuras migraciones.

ALTER TABLE public.documentos_ia
    DROP CONSTRAINT IF EXISTS documentos_ia_fuente_tipo_check;

ALTER TABLE public.documentos_ia
    ADD CONSTRAINT documentos_ia_fuente_tipo_check
    CHECK (fuente_tipo IN ('apunte', 'archivo', 'guia_docente'));

ALTER TABLE public.documentos_ia
    DROP CONSTRAINT IF EXISTS documentos_ia_tipo_check;

ALTER TABLE public.documentos_ia
    ADD CONSTRAINT documentos_ia_tipo_check
    CHECK (tipo IN ('resumen', 'mapa_mental', 'guia_docente'));
