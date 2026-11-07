-- Fecha de nacimiento opcional de la cuenta (ADR 0036). La edad ya no se pide: se calcula el día que hace falta
-- (kcal, propuestas de rutina, objetivos) y sirve para felicitar el cumpleaños. Dato personal: se borra al anonimizar
-- la cuenta, sale en la exportación de la persona y nunca en el perfil público.
ALTER TABLE usuarios ADD COLUMN fecha_nacimiento DATE;

-- La edad del perfil físico pasa a ser la que se dio antes de existir la fecha: quien ya la tenía sigue igual, y quien
-- empieza ahora puede no darla (las fórmulas usan entonces la fecha de nacimiento o una edad de referencia).
ALTER TABLE perfil_bienestar_usuario ALTER COLUMN edad DROP NOT NULL;
