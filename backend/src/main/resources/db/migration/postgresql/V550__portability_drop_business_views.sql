-- Portabilidad: reglas de negocio fuera de la base de datos (ADR 0012).
--
-- Estas vistas calculaban valores de negocio en SQL propio de PostgreSQL (date_trunc, AT TIME ZONE,
-- string_agg, now()). La aplicación ya no las usa: los mismos cálculos viven en el dominio y se
-- prueban con tests unitarios.
--   v_admin_metricas      -> AdminActivityAggregation (usuario activo, «hoy» en UTC) + recuentos simples
--   v_analitica_semanal   -> WeeklyTrainingMetric.byWeek (semanas de lunes en UTC, RPE medio)
--   v_ejercicios_completos -> sin uso (el catálogo se lee con ExerciseSqlReader)
-- Se eliminan para que no queden reglas duplicadas en la base de datos ni haya que traducirlas a
-- otro motor.
DROP VIEW IF EXISTS v_admin_metricas;
DROP VIEW IF EXISTS v_analitica_semanal;
DROP VIEW IF EXISTS v_ejercicios_completos;
