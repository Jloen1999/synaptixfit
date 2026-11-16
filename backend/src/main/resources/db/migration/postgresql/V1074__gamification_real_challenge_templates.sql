-- Plantillas de reto reales (ADR 0054): los 10 retos de la fase 3A. Las que cambian de regla se retiran (activa =
-- false) y entran como plantillas nuevas: los retos en curso guardan su propia copia de la regla (V1062) y siguen
-- contándose igual hasta que terminan.
--   · «Entrena también en exámenes»: 2 entrenos por semana (antes 3), como «Mantenerte en exámenes».
--   · «Estudia y muévete»: 3 de 7 días (antes 5), lo que proponen las rutinas de inicio.
--   · «Tus primeros 5 km» → «Empieza a correr»: 3 salidas por semana, 8 de las 9 semanas del plan de la rutina.
--   · Nuevo «Tu primer mes entrenando»: 2 entrenos por semana, 4 semanas (el mínimo de fuerza de la OMS).
--   · «Primer estudio antes de las 10» se retira: chocaba con clases de mañana y turnos de tarde.

UPDATE plantillas_reto SET activa = false
WHERE codigo IN ('entrena_en_examenes', 'estudia_y_muevete', 'primeros_5_km', 'estudio_temprano');

INSERT INTO plantillas_reto (id, codigo, tipo, dificultad, dias, metrica, unidad, por_unidad, objetivo,
                             solo_laborables, orden, activa)
VALUES
('3bb32118-342d-5b6b-b4b9-6e405072e36f'::uuid, 'primer_mes_entrenando', 'fitness', 'baja', 28, 'WORKOUTS', 'WEEK', 2, 4, false, 0, true),
('b59c57cd-5e27-5e17-9cad-99840b00d7aa'::uuid, 'entrena_en_examenes_2', 'fitness', 'media', 21, 'WORKOUTS', 'WEEK', 2, 3, false, 1, true),
('a7f0d115-9b19-5e5c-8967-bfb12df49482'::uuid, 'estudia_y_muevete_2', 'academic', 'media', 7, 'STUDY_AND_MOVE', 'DAY', 1, 3, false, 2, true),
('126f5145-5c91-5a7c-959e-0fab7c9add3c'::uuid, 'empieza_a_correr', 'fitness', 'alta', 63, 'RUNS', 'WEEK', 3, 8, false, 8, true);

-- Orden de la galería: el de la propuesta (los que se quedan, entre los nuevos).
UPDATE plantillas_reto SET orden = 3 WHERE codigo = 'pomodoro_diario';
UPDATE plantillas_reto SET orden = 4 WHERE codigo = 'diez_horas_concentracion';
UPDATE plantillas_reto SET orden = 5 WHERE codigo = 'repasa_cada_dia';
UPDATE plantillas_reto SET orden = 6 WHERE codigo = 'simulacro_semanal';
UPDATE plantillas_reto SET orden = 7 WHERE codigo = 'planifica_tu_semana';
UPDATE plantillas_reto SET orden = 9 WHERE codigo = 'registro_diario';

INSERT INTO plantillas_reto_textos (plantilla_id, idioma, titulo, meta)
VALUES
('3bb32118-342d-5b6b-b4b9-6e405072e36f'::uuid, 'es', 'Tu primer mes entrenando', 'Entrena 2 veces por semana durante 4 semanas. Es el mínimo de fuerza que recomienda la OMS.'),
('3bb32118-342d-5b6b-b4b9-6e405072e36f'::uuid, 'en', 'Your first month of training', 'Train twice a week for 4 weeks. It''s the minimum strength training the WHO recommends.'),
('3bb32118-342d-5b6b-b4b9-6e405072e36f'::uuid, 'fr', 'Ton premier mois d''entraînement', 'Entraîne-toi 2 fois par semaine pendant 4 semaines. C''est le minimum de renforcement recommandé par l''OMS.'),
('3bb32118-342d-5b6b-b4b9-6e405072e36f'::uuid, 'pt', 'O teu primeiro mês a treinar', 'Treina 2 vezes por semana durante 4 semanas. É o mínimo de força que a OMS recomenda.'),
('b59c57cd-5e27-5e17-9cad-99840b00d7aa'::uuid, 'es', 'Entrena también en exámenes', 'Entrena 2 veces por semana durante 3 semanas, aunque haya exámenes. Media hora basta.'),
('b59c57cd-5e27-5e17-9cad-99840b00d7aa'::uuid, 'en', 'Keep training during exams', 'Train twice a week for 3 weeks, even with exams. Half an hour is enough.'),
('b59c57cd-5e27-5e17-9cad-99840b00d7aa'::uuid, 'fr', 'Entraîne-toi même en examens', 'Entraîne-toi 2 fois par semaine pendant 3 semaines, même en période d''examens. Une demi-heure suffit.'),
('b59c57cd-5e27-5e17-9cad-99840b00d7aa'::uuid, 'pt', 'Treina também nos exames', 'Treina 2 vezes por semana durante 3 semanas, mesmo com exames. Meia hora chega.'),
('a7f0d115-9b19-5e5c-8967-bfb12df49482'::uuid, 'es', 'Estudia y muévete', 'Haz un Pomodoro y un entreno el mismo día, 3 de los próximos 7 días.'),
('a7f0d115-9b19-5e5c-8967-bfb12df49482'::uuid, 'en', 'Study and move', 'Do a Pomodoro and a workout on the same day, on 3 of the next 7 days.'),
('a7f0d115-9b19-5e5c-8967-bfb12df49482'::uuid, 'fr', 'Révise et bouge', 'Fais un Pomodoro et un entraînement le même jour, 3 des 7 prochains jours.'),
('a7f0d115-9b19-5e5c-8967-bfb12df49482'::uuid, 'pt', 'Estuda e mexe-te', 'Faz um Pomodoro e um treino no mesmo dia, em 3 dos próximos 7 dias.'),
('126f5145-5c91-5a7c-959e-0fab7c9add3c'::uuid, 'es', 'Empieza a correr', 'Sal a correr 3 veces por semana durante 9 semanas, grabando la carrera. Cuentan 8 de las 9: una semana mala no pasa nada.'),
('126f5145-5c91-5a7c-959e-0fab7c9add3c'::uuid, 'en', 'Start running', 'Go running 3 times a week for 9 weeks, recording each run. 8 of the 9 weeks count: one bad week is fine.'),
('126f5145-5c91-5a7c-959e-0fab7c9add3c'::uuid, 'fr', 'Commence à courir', 'Sors courir 3 fois par semaine pendant 9 semaines en enregistrant la course. 8 semaines sur 9 suffisent : une mauvaise semaine, ce n''est pas grave.'),
('126f5145-5c91-5a7c-959e-0fab7c9add3c'::uuid, 'pt', 'Começa a correr', 'Sai para correr 3 vezes por semana durante 9 semanas, gravando a corrida. Contam 8 das 9: uma semana má não faz mal.');
