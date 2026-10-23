-- Enfoque de uso de la cuenta (UsageFocus): 'academico', 'deporte' o 'ambos'. NULL = aún no elegido
-- (el onboarding lo pregunta). La regla de qué se muestra con cada enfoque vive en la aplicación.
-- El cierre del onboarding pasa a guardarse en la cuenta: con enfoque solo académico no existe el
-- perfil físico, que era donde se guardaba (perfil_bienestar_usuario.onboarding_completado).
ALTER TABLE usuarios ADD COLUMN enfoque VARCHAR(20);
ALTER TABLE usuarios ADD COLUMN onboarding_completado BOOLEAN NOT NULL DEFAULT FALSE;

-- Las cuentas existentes usaban la app completa: siguen igual.
UPDATE usuarios SET enfoque = 'ambos';

UPDATE usuarios
   SET onboarding_completado = TRUE
 WHERE id IN (SELECT usuario_id FROM perfil_bienestar_usuario WHERE onboarding_completado = TRUE);
