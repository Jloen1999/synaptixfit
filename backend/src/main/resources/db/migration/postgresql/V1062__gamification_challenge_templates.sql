-- Retos que se cuentan solos y plantillas de retos productivos (ADR 0043).

-- 1. Regla automática de un reto: «por_unidad» de «metrica» cada «unidad», «objetivo» veces. La copia el alta desde
--    una plantilla y no se edita; «regla_cumplidas» es el recuento del servidor (se rehace siempre desde cero, se
--    guarda para listar sin leer otros módulos). Sin regla, el reto es de los de siempre.
ALTER TABLE retos
    ADD COLUMN regla_metrica         text,
    ADD COLUMN regla_unidad          text,
    ADD COLUMN regla_por_unidad      integer,
    ADD COLUMN regla_objetivo        integer,
    ADD COLUMN regla_solo_laborables boolean NOT NULL DEFAULT false,
    ADD COLUMN regla_cumplidas       integer NOT NULL DEFAULT 0 CHECK (regla_cumplidas >= 0),
    ADD COLUMN plantilla_codigo      text;

ALTER TABLE retos ADD CONSTRAINT ck_retos_regla CHECK (
    (regla_metrica IS NULL AND regla_unidad IS NULL AND regla_por_unidad IS NULL AND regla_objetivo IS NULL)
    OR (regla_metrica IN ('REVIEWS', 'FOCUS_MINUTES', 'EARLY_FOCUS', 'WORKOUTS', 'STUDY_AND_MOVE', 'TESTS',
                          'CHECK_INS', 'PLANNED_WEEKS', 'RUNS')
        AND regla_unidad IN ('DAY', 'WEEK', 'TOTAL')
        AND regla_por_unidad BETWEEN 1 AND 10000
        AND regla_objetivo BETWEEN 1 AND 10000));

CREATE INDEX idx_retos_regla ON retos (usuario_id) WHERE regla_metrica IS NOT NULL;

-- 2. Catálogo de plantillas (solo lectura), con título y meta por idioma.
CREATE TABLE plantillas_reto (
    id                uuid PRIMARY KEY,
    codigo            text    NOT NULL UNIQUE,
    tipo              text    NOT NULL CHECK (tipo IN ('fitness', 'academic')),
    dificultad        text    NOT NULL CHECK (dificultad IN ('baja', 'media', 'alta')),
    dias              integer NOT NULL CHECK (dias BETWEEN 1 AND 90),
    metrica           text    NOT NULL CHECK (metrica IN ('REVIEWS', 'FOCUS_MINUTES', 'EARLY_FOCUS', 'WORKOUTS',
                                                     'STUDY_AND_MOVE', 'TESTS', 'CHECK_INS', 'PLANNED_WEEKS',
                                                     'RUNS')),
    unidad            text    NOT NULL CHECK (unidad IN ('DAY', 'WEEK', 'TOTAL')),
    por_unidad        integer NOT NULL CHECK (por_unidad BETWEEN 1 AND 10000),
    objetivo          integer NOT NULL CHECK (objetivo BETWEEN 1 AND 10000),
    solo_laborables   boolean NOT NULL DEFAULT false,
    orden             integer NOT NULL DEFAULT 0
);

CREATE TABLE plantillas_reto_textos (
    plantilla_id uuid NOT NULL REFERENCES plantillas_reto (id) ON DELETE CASCADE,
    idioma       text NOT NULL,
    titulo       text NOT NULL CHECK (char_length(titulo) BETWEEN 5 AND 80),
    meta         text NOT NULL CHECK (char_length(meta) BETWEEN 1 AND 500),
    PRIMARY KEY (plantilla_id, idioma)
);

INSERT INTO plantillas_reto (id, codigo, tipo, dificultad, dias, metrica, unidad, por_unidad, objetivo,
                             solo_laborables, orden)
VALUES
('d2721891-2193-57a0-8d01-1c0724f1f303'::uuid, 'repasa_cada_dia', 'academic', 'media', 14, 'REVIEWS', 'DAY', 1, 12, false, 0),
('1cb634fc-29cb-5496-b312-625fec442e11'::uuid, 'pomodoro_diario', 'academic', 'baja', 7, 'FOCUS_MINUTES', 'DAY', 25, 5, false, 1),
('8087f5b4-5997-5da1-b5b2-6a3e3cd6f038'::uuid, 'diez_horas_concentracion', 'academic', 'alta', 14, 'FOCUS_MINUTES', 'TOTAL', 1, 600, false, 2),
('357d69ca-c911-5097-886e-7a51102381e0'::uuid, 'estudio_temprano', 'academic', 'media', 14, 'EARLY_FOCUS', 'DAY', 1, 8, true, 3),
('b589c268-ccff-5afe-a732-d9409e483765'::uuid, 'simulacro_semanal', 'academic', 'media', 28, 'TESTS', 'WEEK', 1, 4, false, 4),
('309cba6b-a444-5e6e-8066-85871db982e9'::uuid, 'planifica_tu_semana', 'academic', 'media', 28, 'PLANNED_WEEKS', 'WEEK', 1, 4, false, 5),
('de4ba5e6-41d5-5c64-89b8-e261ca62b748'::uuid, 'estudia_y_muevete', 'academic', 'media', 7, 'STUDY_AND_MOVE', 'DAY', 1, 5, false, 6),
('2a2e6d08-5cb6-5ffd-a9a9-caf3a7b0fdf3'::uuid, 'entrena_en_examenes', 'fitness', 'alta', 21, 'WORKOUTS', 'WEEK', 3, 3, false, 7),
('f25a46a8-1b57-5ccd-8ee9-30f109cb32b6'::uuid, 'primeros_5_km', 'fitness', 'alta', 42, 'RUNS', 'TOTAL', 1, 18, false, 8),
('a274046a-9bee-514a-929d-68dbce57d2d8'::uuid, 'registro_diario', 'fitness', 'media', 21, 'CHECK_INS', 'DAY', 1, 18, false, 9);

INSERT INTO plantillas_reto_textos (plantilla_id, idioma, titulo, meta)
VALUES
('d2721891-2193-57a0-8d01-1c0724f1f303'::uuid, 'es', 'Repasa cada día', 'Haz al menos un repaso al día, 12 de los próximos 14 días.'),
('d2721891-2193-57a0-8d01-1c0724f1f303'::uuid, 'en', 'Review every day', 'Do at least one review a day on 12 of the next 14 days.'),
('d2721891-2193-57a0-8d01-1c0724f1f303'::uuid, 'fr', 'Révise chaque jour', 'Fais au moins une révision par jour, 12 des 14 prochains jours.'),
('d2721891-2193-57a0-8d01-1c0724f1f303'::uuid, 'pt', 'Revê todos os dias', 'Faz pelo menos uma revisão por dia, em 12 dos próximos 14 dias.'),
('1cb634fc-29cb-5496-b312-625fec442e11'::uuid, 'es', 'Un Pomodoro al día', 'Concéntrate al menos 25 minutos con el Pomodoro, 5 de los próximos 7 días.'),
('1cb634fc-29cb-5496-b312-625fec442e11'::uuid, 'en', 'One Pomodoro a day', 'Focus for at least 25 minutes with the Pomodoro on 5 of the next 7 days.'),
('1cb634fc-29cb-5496-b312-625fec442e11'::uuid, 'fr', 'Un Pomodoro par jour', 'Concentre-toi au moins 25 minutes avec le Pomodoro, 5 des 7 prochains jours.'),
('1cb634fc-29cb-5496-b312-625fec442e11'::uuid, 'pt', 'Um Pomodoro por dia', 'Concentra-te pelo menos 25 minutos com o Pomodoro, em 5 dos próximos 7 dias.'),
('8087f5b4-5997-5da1-b5b2-6a3e3cd6f038'::uuid, 'es', '10 horas de concentración', 'Suma 10 horas de Pomodoro en 2 semanas.'),
('8087f5b4-5997-5da1-b5b2-6a3e3cd6f038'::uuid, 'en', '10 hours of focus', 'Add up 10 hours of Pomodoro in 2 weeks.'),
('8087f5b4-5997-5da1-b5b2-6a3e3cd6f038'::uuid, 'fr', '10 heures de concentration', 'Cumule 10 heures de Pomodoro en 2 semaines.'),
('8087f5b4-5997-5da1-b5b2-6a3e3cd6f038'::uuid, 'pt', '10 horas de concentração', 'Soma 10 horas de Pomodoro em 2 semanas.'),
('357d69ca-c911-5097-886e-7a51102381e0'::uuid, 'es', 'Primer estudio antes de las 10', 'Empieza un Pomodoro antes de las 10 de la mañana, 8 de los próximos 10 días laborables.'),
('357d69ca-c911-5097-886e-7a51102381e0'::uuid, 'en', 'First study before 10 am', 'Start a Pomodoro before 10 in the morning on 8 of the next 10 weekdays.'),
('357d69ca-c911-5097-886e-7a51102381e0'::uuid, 'fr', 'Première révision avant 10 h', 'Lance un Pomodoro avant 10 h du matin, 8 des 10 prochains jours de semaine.'),
('357d69ca-c911-5097-886e-7a51102381e0'::uuid, 'pt', 'Primeiro estudo antes das 10', 'Começa um Pomodoro antes das 10 da manhã, em 8 dos próximos 10 dias úteis.'),
('b589c268-ccff-5afe-a732-d9409e483765'::uuid, 'es', 'Simulacro semanal', 'Haz al menos un test o simulacro cada semana, 4 semanas.'),
('b589c268-ccff-5afe-a732-d9409e483765'::uuid, 'en', 'Weekly mock exam', 'Do at least one quiz or mock exam every week, for 4 weeks.'),
('b589c268-ccff-5afe-a732-d9409e483765'::uuid, 'fr', 'Examen blanc hebdomadaire', 'Fais au moins un test ou un examen blanc chaque semaine, pendant 4 semaines.'),
('b589c268-ccff-5afe-a732-d9409e483765'::uuid, 'pt', 'Simulado semanal', 'Faz pelo menos um teste ou simulado por semana, durante 4 semanas.'),
('309cba6b-a444-5e6e-8066-85871db982e9'::uuid, 'es', 'Planifica tu semana', 'Deja planificadas 4 semanas en el calendario, con al menos 3 eventos cada una.'),
('309cba6b-a444-5e6e-8066-85871db982e9'::uuid, 'en', 'Plan your week', 'Get 4 weeks planned in the calendar, with at least 3 events each.'),
('309cba6b-a444-5e6e-8066-85871db982e9'::uuid, 'fr', 'Planifie ta semaine', 'Planifie 4 semaines dans le calendrier, avec au moins 3 événements chacune.'),
('309cba6b-a444-5e6e-8066-85871db982e9'::uuid, 'pt', 'Planeia a tua semana', 'Deixa 4 semanas planeadas no calendário, com pelo menos 3 eventos cada uma.'),
('de4ba5e6-41d5-5c64-89b8-e261ca62b748'::uuid, 'es', 'Estudia y muévete', 'Haz un Pomodoro y un entreno el mismo día, 5 de los próximos 7 días.'),
('de4ba5e6-41d5-5c64-89b8-e261ca62b748'::uuid, 'en', 'Study and move', 'Do a Pomodoro and a workout on the same day, on 5 of the next 7 days.'),
('de4ba5e6-41d5-5c64-89b8-e261ca62b748'::uuid, 'fr', 'Révise et bouge', 'Fais un Pomodoro et un entraînement le même jour, 5 des 7 prochains jours.'),
('de4ba5e6-41d5-5c64-89b8-e261ca62b748'::uuid, 'pt', 'Estuda e mexe-te', 'Faz um Pomodoro e um treino no mesmo dia, em 5 dos próximos 7 dias.'),
('2a2e6d08-5cb6-5ffd-a9a9-caf3a7b0fdf3'::uuid, 'es', 'Entrena también en exámenes', 'Entrena 3 veces por semana durante 3 semanas, aunque haya exámenes.'),
('2a2e6d08-5cb6-5ffd-a9a9-caf3a7b0fdf3'::uuid, 'en', 'Keep training during exams', 'Train 3 times a week for 3 weeks, even with exams.'),
('2a2e6d08-5cb6-5ffd-a9a9-caf3a7b0fdf3'::uuid, 'fr', 'Entraîne-toi même en examens', 'Entraîne-toi 3 fois par semaine pendant 3 semaines, même en période d''examens.'),
('2a2e6d08-5cb6-5ffd-a9a9-caf3a7b0fdf3'::uuid, 'pt', 'Treina também nos exames', 'Treina 3 vezes por semana durante 3 semanas, mesmo com exames.'),
('f25a46a8-1b57-5ccd-8ee9-30f109cb32b6'::uuid, 'es', 'Tus primeros 5 km', 'Sal a correr 18 veces en 6 semanas (3 por semana) grabando la carrera.'),
('f25a46a8-1b57-5ccd-8ee9-30f109cb32b6'::uuid, 'en', 'Your first 5 km', 'Go running 18 times in 6 weeks (3 a week), recording each run.'),
('f25a46a8-1b57-5ccd-8ee9-30f109cb32b6'::uuid, 'fr', 'Tes premiers 5 km', 'Sors courir 18 fois en 6 semaines (3 par semaine) en enregistrant la course.'),
('f25a46a8-1b57-5ccd-8ee9-30f109cb32b6'::uuid, 'pt', 'Os teus primeiros 5 km', 'Sai para correr 18 vezes em 6 semanas (3 por semana), gravando a corrida.'),
('a274046a-9bee-514a-929d-68dbce57d2d8'::uuid, 'es', '¿Qué tal estás? 3 semanas', 'Responde «¿Qué tal estás hoy?» 18 de los próximos 21 días. Solo lo ves tú.'),
('a274046a-9bee-514a-929d-68dbce57d2d8'::uuid, 'en', 'How are you? 3 weeks', 'Answer «How are you today?» on 18 of the next 21 days. Only you can see it.'),
('a274046a-9bee-514a-929d-68dbce57d2d8'::uuid, 'fr', 'Comment ça va ? 3 semaines', 'Réponds à « Comment ça va aujourd''hui ? » 18 des 21 prochains jours. Toi seul le vois.'),
('a274046a-9bee-514a-929d-68dbce57d2d8'::uuid, 'pt', 'Como estás? 3 semanas', 'Responde a «Como estás hoje?» em 18 dos próximos 21 dias. Só tu o vês.');
