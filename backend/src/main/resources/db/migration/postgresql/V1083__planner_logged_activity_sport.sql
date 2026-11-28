-- Deportes (ADR 0068): la actividad apuntada dice qué deporte fue (catálogo `Sport`), con su nombre libre si es
-- «otro», y, en los de partido, si fue partido o entreno, el resultado y el marcador. `clase` se conserva: las apps
-- ya instaladas la siguen leyendo. Sin reglas nuevas: solo describe la actividad.
ALTER TABLE actividades_apuntadas
    ADD COLUMN deporte varchar(12),
    ADD COLUMN deporte_nombre varchar(40),
    ADD COLUMN modalidad varchar(10),
    ADD COLUMN resultado varchar(5),
    ADD COLUMN marcador varchar(20);

-- Lo que se medía en distancia ya decía su deporte.
UPDATE actividades_apuntadas SET deporte = clase WHERE clase IN ('RUN', 'WALK', 'BIKE', 'SWIM');

-- Los partidos, por su título (la misma regla y el mismo orden que `Sport.fromLegacy`). El «_» cubre la vocal con
-- o sin tilde.
UPDATE actividades_apuntadas SET deporte = 'FOOTBALL', modalidad = 'MATCH'
WHERE deporte IS NULL AND clase = 'MATCH' AND bloque_id IN (SELECT id FROM horarios_academicos
    WHERE lower(temas) LIKE '%f_tbol%' OR lower(temas) LIKE '%football%' OR lower(temas) LIKE '%soccer%'
       OR lower(temas) LIKE '%futebol%');
UPDATE actividades_apuntadas SET deporte = 'PADEL', modalidad = 'MATCH'
WHERE deporte IS NULL AND clase = 'MATCH' AND bloque_id IN (SELECT id FROM horarios_academicos
    WHERE lower(temas) LIKE '%p_del%' OR lower(temas) LIKE '%paddle%');
UPDATE actividades_apuntadas SET deporte = 'BASKETBALL', modalidad = 'MATCH'
WHERE deporte IS NULL AND clase = 'MATCH' AND bloque_id IN (SELECT id FROM horarios_academicos
    WHERE lower(temas) LIKE '%baloncesto%' OR lower(temas) LIKE '%basket%' OR lower(temas) LIKE '%b_squet%');
UPDATE actividades_apuntadas SET deporte = 'VOLLEYBALL', modalidad = 'MATCH'
WHERE deporte IS NULL AND clase = 'MATCH' AND bloque_id IN (SELECT id FROM horarios_academicos
    WHERE lower(temas) LIKE '%v_ley%' OR lower(temas) LIKE '%volley%' OR lower(temas) LIKE '%voleibol%'
       OR lower(temas) LIKE '%v_lei%');
UPDATE actividades_apuntadas SET deporte = 'TENNIS', modalidad = 'MATCH'
WHERE deporte IS NULL AND clase = 'MATCH' AND bloque_id IN (SELECT id FROM horarios_academicos
    WHERE lower(temas) LIKE '%tenis%' OR lower(temas) LIKE '%tennis%');

-- El resto es «otro deporte» con su título como nombre (sin espacios de más y de 40 letras como mucho).
UPDATE actividades_apuntadas a SET deporte = 'OTHER',
    deporte_nombre = (SELECT NULLIF(rtrim(substring(regexp_replace(btrim(b.temas), '\s+', ' ', 'g') FROM 1 FOR 40)), '')
                      FROM horarios_academicos b WHERE b.id = a.bloque_id)
WHERE a.deporte IS NULL;

ALTER TABLE actividades_apuntadas
    ALTER COLUMN deporte SET DEFAULT 'OTHER',
    ALTER COLUMN deporte SET NOT NULL,
    ADD CONSTRAINT ck_actividades_apuntadas_deporte CHECK (deporte IN ('RUN', 'WALK', 'BIKE', 'SWIM', 'FOOTBALL',
        'PADEL', 'BASKETBALL', 'VOLLEYBALL', 'TENNIS', 'OTHER')),
    ADD CONSTRAINT ck_actividades_apuntadas_modalidad CHECK (modalidad IS NULL OR modalidad IN ('MATCH', 'TRAINING')),
    ADD CONSTRAINT ck_actividades_apuntadas_resultado CHECK (resultado IS NULL OR resultado IN ('WIN', 'DRAW', 'LOSS'));
