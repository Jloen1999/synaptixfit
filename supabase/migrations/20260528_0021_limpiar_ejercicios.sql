-- Migracion: Limpia todos los datos de ejercicios, rutinas y sesiones
-- para permitir una re-carga limpia del catalogo.
-- Orden: respeta FK constraints para evitar errores.

BEGIN;

-- 1. Series de sesion (depende de sesiones_registradas y seleccion_de_ejercicios)
DELETE FROM series_sesion;

-- 2. Sesiones registradas (rutina_id es SET NULL, seguro borrar)
DELETE FROM sesiones_registradas;

-- 3. Rutinas -> cascades to seleccion_de_ejercicios, semanas_rutina, dias_rutina
DELETE FROM rutinas;

-- 4. Limpieza residual de tablas de periodizacion por si quedaron huerfanas
DELETE FROM dias_rutina;
DELETE FROM semanas_rutina;
DELETE FROM seleccion_de_ejercicios;

-- 5. Ejercicios -> cascades to ejercicio_musculo_objetivo, _secundario, _parte_cuerpo, _equipamiento
DELETE FROM ejercicios;

-- 6. Catalogos
DELETE FROM equipamientos;
DELETE FROM musculos;
DELETE FROM partes_cuerpo;

-- 7. Refrescar vista si existe como materializada
-- (v_ejercicios_completos es una vista normal, no necesita refresco)

COMMIT;
