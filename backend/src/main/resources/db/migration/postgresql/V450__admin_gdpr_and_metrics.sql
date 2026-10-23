-- Administración y RGPD.

-- 1. Una cuenta anonimizada (RGPD) no conserva credenciales: User.anonymize() borra el hash de
--    la contraseña y el identificador de Google. El CHECK heredado lo impedía.
ALTER TABLE usuarios DROP CONSTRAINT ck_usuarios_credencial;
ALTER TABLE usuarios ADD CONSTRAINT ck_usuarios_credencial
    CHECK ((password_hash IS NOT NULL) OR (google_sub IS NOT NULL) OR (eliminado_en IS NOT NULL));

-- 2. Indicadores del panel. Cambios respecto a la vista heredada:
--    - «hoy» se calcula en UTC (antes dependía de la zona horaria de la sesión);
--    - total_usuarios excluye las cuentas anonimizadas o desactivadas;
--    - usuarios_activos_hoy cuenta también focus y bloques de estudio completados, no solo entrenos;
--    - rutinas_activas exige estado 'activo' y retos_activos que no hayan vencido;
--    - nuevas columnas usuarios_nuevos_hoy y usuarios_shadowbaneados.
DROP VIEW IF EXISTS v_admin_metricas;
CREATE VIEW v_admin_metricas AS
SELECT
    (SELECT count(*) FROM usuarios WHERE eliminado_en IS NULL) AS total_usuarios,
    (SELECT count(DISTINCT a.usuario_id) FROM (
        SELECT usuario_id FROM sesiones_registradas
         WHERE (completada_en AT TIME ZONE 'UTC')::date = (now() AT TIME ZONE 'UTC')::date
        UNION
        SELECT usuario_id FROM sesiones_focus
         WHERE fecha = (now() AT TIME ZONE 'UTC')::date
        UNION
        SELECT usuario_id FROM horarios_academicos
         WHERE completado AND (hora_inicio AT TIME ZONE 'UTC')::date = (now() AT TIME ZONE 'UTC')::date
    ) a) AS usuarios_activos_hoy,
    (SELECT count(*) FROM sesiones_registradas
      WHERE (completada_en AT TIME ZONE 'UTC')::date = (now() AT TIME ZONE 'UTC')::date) AS sesiones_hoy,
    (SELECT count(*) FROM rutinas WHERE eliminado_en IS NULL AND estado = 'activo') AS rutinas_activas,
    (SELECT count(*) FROM retos WHERE NOT esta_completado AND fecha_fin >= now()) AS retos_activos,
    ((SELECT count(*) FROM actividades_sociales WHERE reportado = true)
     + (SELECT count(*) FROM comentarios_feed WHERE reportado = true AND NOT eliminado)) AS contenido_reportado_pendiente,
    (SELECT count(*) FROM usuarios
      WHERE (creado_en AT TIME ZONE 'UTC')::date = (now() AT TIME ZONE 'UTC')::date) AS usuarios_nuevos_hoy,
    (SELECT count(*) FROM usuarios WHERE is_shadowbanned AND eliminado_en IS NULL) AS usuarios_shadowbaneados;

-- 3. Auditoría: listado por fecha y línea de tiempo / redacción por entidad.
CREATE INDEX IF NOT EXISTS idx_admin_auditoria_creado_en ON admin_auditoria USING btree (creado_en DESC);
CREATE INDEX IF NOT EXISTS idx_admin_auditoria_entidad ON admin_auditoria USING btree (entidad_id, creado_en DESC);
