-- Gamificación: insignia «Planificador Maestro» (4 semanas consecutivas con ≥ 80 % de adherencia
-- al plan de estudio). La app antigua evaluaba el criterio 'semanas_plan_adherencia' pero la
-- insignia nunca llegó al catálogo, así que no se podía obtener.
INSERT INTO insignias (id, nombre, descripcion, icono, categoria, criterio_tipo, criterio_valor, rareza, orden)
VALUES ('5c1e7f0a-3b2d-4e8f-9a61-7d2c4b8e1f30', 'Planificador Maestro',
        'Cumple al menos el 80 % de tu plan de estudio 4 semanas seguidas', '🗓️', 'estudio',
        'semanas_plan_adherencia', 4, 'epica', 16)
ON CONFLICT (nombre) DO NOTHING;
