-- ============================================================
-- Migración: Insignias y Rachas Avanzadas
-- ============================================================

CREATE TABLE IF NOT EXISTS insignias (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre          TEXT NOT NULL UNIQUE,
    descripcion     TEXT NOT NULL,
    icono           TEXT NOT NULL DEFAULT '🏅',
    categoria       TEXT NOT NULL CHECK (categoria IN ('entrenamiento','estudio','social','racha','especial')),
    criterio_tipo   TEXT NOT NULL,
    criterio_valor  INTEGER NOT NULL DEFAULT 1,
    rareza          TEXT NOT NULL DEFAULT 'comun' CHECK (rareza IN ('comun','rara','epica','legendaria')),
    orden           INTEGER NOT NULL DEFAULT 0,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS usuario_insignias (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    insignia_id     UUID NOT NULL REFERENCES insignias(id) ON DELETE CASCADE,
    obtenida_en     TIMESTAMPTZ NOT NULL DEFAULT now(),
    notificada      BOOLEAN NOT NULL DEFAULT false,
    visible         BOOLEAN NOT NULL DEFAULT true,
    UNIQUE(usuario_id, insignia_id)
);

ALTER TABLE insignias ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuario_insignias ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lectura publica insignias" ON insignias FOR SELECT USING (true);
CREATE POLICY "Lectura owner usuario_insignias" ON usuario_insignias FOR SELECT USING (auth.uid() = usuario_id);
CREATE POLICY "Insercion authenticated usuario_insignias" ON usuario_insignias FOR INSERT WITH CHECK (auth.uid() = usuario_id);

CREATE INDEX idx_usuario_insignias_usuario ON usuario_insignias(usuario_id);
CREATE INDEX idx_insignias_categoria ON insignias(categoria);

-- Catálogo inicial de 15 insignias
INSERT INTO insignias (nombre, descripcion, icono, categoria, criterio_tipo, criterio_valor, rareza, orden) VALUES
('Primeros pasos', 'Completa tu primera sesión de entrenamiento', '🏅', 'entrenamiento', 'sesiones_completadas', 1, 'comun', 1),
('Constancia de hierro', 'Completa 10 sesiones de entrenamiento', '💪', 'entrenamiento', 'sesiones_completadas', 10, 'comun', 2),
('Atleta dedicado', 'Completa 50 sesiones de entrenamiento', '🏋️', 'entrenamiento', 'sesiones_completadas', 50, 'rara', 3),
('Maestro del esfuerzo', 'Alcanza RPE ≥ 8 en 5 sesiones', '🔥', 'entrenamiento', 'rpe_alto', 5, 'rara', 4),
('Equilibrio perfecto', 'Completa 7 check-ins diarios consecutivos', '⚖️', 'entrenamiento', 'checkins_consecutivos', 7, 'epica', 5),
('Mente brillante', 'Completa 20 bloques de estudio', '🧠', 'estudio', 'bloques_estudio', 20, 'comun', 6),
('Planificador nato', 'Crea 3 planes de estudio', '📋', 'estudio', 'planes_estudio', 3, 'comun', 7),
('Notas de oro', 'Escribe 10 apuntes', '✍️', 'estudio', 'apuntes_creados', 10, 'comun', 8),
('Alma social', 'Publica 5 publicaciones en el feed', '💬', 'social', 'publicaciones_feed', 5, 'comun', 9),
('Popular', 'Recibe 10 likes en tus publicaciones', '🌟', 'social', 'likes_recibidos', 10, 'rara', 10),
('Racha de fuego', 'Mantén una racha de 7 días consecutivos', '🔥', 'racha', 'racha_dias', 7, 'comun', 11),
('Imparable', 'Mantén una racha de 30 días consecutivos', '⚡', 'racha', 'racha_dias', 30, 'rara', 12),
('Leyenda', 'Mantén una racha de 100 días consecutivos', '👑', 'racha', 'racha_dias', 100, 'legendaria', 13),
('Primer reto', 'Completa tu primer reto', '🎯', 'especial', 'retos_completados', 1, 'comun', 14),
('Coleccionista', 'Obtén 10 insignias distintas', '🏆', 'especial', 'insignias_obtenidas', 10, 'epica', 15)
ON CONFLICT (nombre) DO NOTHING;
