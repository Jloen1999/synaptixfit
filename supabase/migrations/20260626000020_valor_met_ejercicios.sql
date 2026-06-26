-- ============================================================
-- Migración 0020: Añade columna valor_met a ejercicios
-- y actualiza la vista v_ejercicios_completos para incluirla.
--
-- El coeficiente MET (Metabolic Equivalent of Task) del
-- Compendio de Adultos 2024 permite al CalorieCalculatorService
-- estimar el gasto calórico con precisión científica.
-- ============================================================

-- 1. Añadir columna a la tabla ejercicios
ALTER TABLE public.ejercicios
  ADD COLUMN IF NOT EXISTS valor_met DOUBLE PRECISION NOT NULL DEFAULT 6.0;

-- 2. Recrear la vista denormalizada incluyendo valor_met
DROP VIEW IF EXISTS public.v_ejercicios_completos CASCADE;

CREATE OR REPLACE VIEW public.v_ejercicios_completos AS
SELECT
    e.id,
    e.nombre,
    e.url_gif,
    e.url_preview,
    e.instrucciones,
    e.dificultad,
    e.descripcion,
    e.finalidad,
    e.modalidad_entrenamiento,
    e.tipo_medicion,
    e.es_circuito,
    e.valor_met,
    COALESCE(
        (SELECT string_agg(DISTINCT pc.nombre, ', ')
         FROM public.ejercicio_parte_cuerpo epc
         JOIN public.partes_cuerpo pc ON pc.id = epc.parte_cuerpo_id
         WHERE epc.ejercicio_id = e.id), ''
    ) AS partes_cuerpo,
    COALESCE(
        (SELECT string_agg(DISTINCT m.nombre, ', ')
         FROM public.ejercicio_musculo_objetivo emo
         JOIN public.musculos m ON m.id = emo.musculo_id
         WHERE emo.ejercicio_id = e.id), ''
    ) AS musculos_objetivo,
    COALESCE(
        (SELECT string_agg(DISTINCT m.nombre, ', ')
         FROM public.ejercicio_musculo_secundario ems
         JOIN public.musculos m ON m.id = ems.musculo_id
         WHERE ems.ejercicio_id = e.id), ''
    ) AS musculos_secundarios,
    COALESCE(
        (SELECT string_agg(DISTINCT eq.nombre, ', ')
         FROM public.ejercicio_equipamiento eeq
         JOIN public.equipamientos eq ON eq.id = eeq.equipamiento_id
         WHERE eeq.ejercicio_id = e.id), ''
    ) AS equipamientos,
    e.creado_en
FROM public.ejercicios e;
