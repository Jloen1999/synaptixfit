-- ADR 0031. Series de calentamiento y «hasta no poder más», consejos de cada ejercicio y notas propias.

-- Una serie de calentamiento (aproximación) tiene su propia numeración y no cuenta como serie de trabajo:
-- ni volumen, ni récords, ni propuesta de peso. «al_fallo»: la serie se hizo hasta no poder más.
ALTER TABLE series_sesion ADD COLUMN calentamiento boolean NOT NULL DEFAULT false;
ALTER TABLE series_sesion ADD COLUMN al_fallo boolean NOT NULL DEFAULT false;

-- «Las claves» y «Errores comunes» de un ejercicio, por idioma (si falta el idioma, se usa el español).
CREATE TABLE consejos_ejercicio (
    ejercicio_id uuid NOT NULL REFERENCES ejercicios (id) ON DELETE CASCADE,
    idioma varchar(5) NOT NULL,
    claves text[] NOT NULL DEFAULT '{}'::text[],
    errores text[] NOT NULL DEFAULT '{}'::text[],
    PRIMARY KEY (ejercicio_id, idioma)
);

-- Nota de una persona sobre un ejercicio («asiento en el 4, agarre ancho»). Solo la ve ella.
CREATE TABLE notas_ejercicio (
    usuario_id uuid NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    ejercicio_id uuid NOT NULL REFERENCES ejercicios (id) ON DELETE CASCADE,
    texto varchar(500) NOT NULL,
    actualizado_en timestamp with time zone NOT NULL DEFAULT now(),
    PRIMARY KEY (usuario_id, ejercicio_id)
);
