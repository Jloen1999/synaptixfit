-- Importaciones de plan docente (módulo Académico). El estudiante sube el PDF sin tener aún la
-- asignatura; la IA lo analiza en segundo plano y el resultado (JSON de la guía, mismo formato que
-- documentos_ia.contenido) espera aquí a que lo revise y lo aplique. Los estados y su significado
-- viven en el dominio (TeachingGuideImport): la columna solo guarda el código.
CREATE TABLE importaciones_plan_docente (
    id                  UUID         NOT NULL PRIMARY KEY,
    usuario_id          UUID         NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    asignatura_destino  UUID         REFERENCES asignaturas (id) ON DELETE SET NULL,
    clave_objeto        TEXT         NOT NULL,
    nombre_archivo      VARCHAR(255) NOT NULL,
    tipo_mime           VARCHAR(100) NOT NULL,
    tamano_bytes        BIGINT       NOT NULL,
    estado              VARCHAR(20)  NOT NULL,
    resultado           TEXT,
    codigo_error        VARCHAR(60),
    asignatura_aplicada UUID         REFERENCES asignaturas (id) ON DELETE SET NULL,
    creado_en           TIMESTAMP WITH TIME ZONE NOT NULL,
    actualizado_en      TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_importaciones_plan_docente_usuario ON importaciones_plan_docente (usuario_id, creado_en);
