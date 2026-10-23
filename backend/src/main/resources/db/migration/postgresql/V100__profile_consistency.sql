-- Módulo Perfil: corrige incoherencias heredadas del esquema de Supabase.

-- 1. Días disponibles: el array (días ISO 1-7) es la fuente de verdad y dias_disponibles_semana
--    se deriva de él. Antes se guardaban por separado y podían contradecirse.
UPDATE perfil_bienestar_usuario
SET dias_disponibles = ARRAY(SELECT DISTINCT d FROM unnest(dias_disponibles) AS d WHERE d BETWEEN 1 AND 7 ORDER BY d)
WHERE dias_disponibles IS NOT NULL;

UPDATE perfil_bienestar_usuario
SET dias_disponibles = CASE LEAST(GREATEST(dias_disponibles_semana, 1), 7)
        WHEN 1 THEN '{1}'::integer[]
        WHEN 2 THEN '{1,4}'::integer[]
        WHEN 3 THEN '{1,3,5}'::integer[]
        WHEN 4 THEN '{1,2,4,5}'::integer[]
        WHEN 5 THEN '{1,2,3,4,5}'::integer[]
        WHEN 6 THEN '{1,2,3,4,5,6}'::integer[]
        ELSE '{1,2,3,4,5,6,7}'::integer[]
    END
WHERE dias_disponibles IS NULL OR cardinality(dias_disponibles) = 0;

UPDATE perfil_bienestar_usuario SET dias_disponibles_semana = cardinality(dias_disponibles);

ALTER TABLE perfil_bienestar_usuario ALTER COLUMN dias_disponibles SET NOT NULL;
ALTER TABLE perfil_bienestar_usuario
    ADD CONSTRAINT ck_perfil_dias_coherentes CHECK (
        dias_disponibles <@ ARRAY[1, 2, 3, 4, 5, 6, 7]
        AND cardinality(dias_disponibles) = dias_disponibles_semana);

-- 2. El valor por defecto 'fitness_general' violaba el propio CHECK de objetivos estándar.
ALTER TABLE perfil_bienestar_usuario ALTER COLUMN objetivo_principal SET DEFAULT 'Hipertrofia Muscular';

-- 3. Fechas del semestre: la de fin nunca antes que la de inicio.
UPDATE perfil_academico_usuario SET fecha_fin_clases = NULL
WHERE fecha_inicio_clases IS NOT NULL AND fecha_fin_clases IS NOT NULL AND fecha_fin_clases < fecha_inicio_clases;

ALTER TABLE perfil_academico_usuario
    ADD CONSTRAINT ck_perfil_acad_fechas CHECK (
        fecha_inicio_clases IS NULL OR fecha_fin_clases IS NULL OR fecha_fin_clases >= fecha_inicio_clases);

-- 4. Historial de objetivos: un único periodo abierto por usuario (se cierran los sobrantes, salvo el más reciente).
UPDATE historial_objetivos h
SET fecha_fin = GREATEST(h.fecha_inicio, CURRENT_DATE)
WHERE h.fecha_fin IS NULL
  AND EXISTS (SELECT 1 FROM historial_objetivos o
              WHERE o.usuario_id = h.usuario_id AND o.fecha_fin IS NULL
                AND (o.fecha_inicio, o.creado_en, o.id) > (h.fecha_inicio, h.creado_en, h.id));

CREATE UNIQUE INDEX ux_historial_objetivos_abierto ON historial_objetivos (usuario_id) WHERE fecha_fin IS NULL;

-- 5. Consulta del historial de peso por usuario y fecha (gráficas).
CREATE INDEX idx_historial_peso_usuario_fecha ON historial_peso (usuario_id, registrado_en);
