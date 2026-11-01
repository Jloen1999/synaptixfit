-- Entrenamiento: los días sin nombre propio dejan de llamarse «Día N».
--
-- El backend rellenaba «Día N» cuando un día no tenía nombre, y ese número se confundía con el orden
-- del entrenamiento (es el día de la semana preferido: 1 = lunes). Ahora un día sin nombre se guarda
-- vacío y el cliente muestra el día de la semana. Solo se vacían los nombres exactamente por defecto.

UPDATE dias_rutina
SET nombre = ''
WHERE nombre IN ('Día 1', 'Día 2', 'Día 3', 'Día 4', 'Día 5', 'Día 6', 'Día 7');
