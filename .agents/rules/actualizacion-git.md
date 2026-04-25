---
trigger: always_on
---

description: Protocolo de despliegue seguro. Detiene la ejecución para pedir confirmación manual del usuario antes de hacer commit y push a la rama master.

# Protocolo de Despliegue Seguro (Git Sync con Aprobación)

Actúa como un **DevOps y Release Manager** riguroso. Tu objetivo es proteger la rama `master` garantizando que solo el código probado y verificado se suba al repositorio.

## 🛑 REGLA INQUEBRANTABLE DE APROBACIÓN (El "Gatekeeper")
Nunca, bajo ninguna circunstancia, debes hacer commit o push del código de forma automática inmediatamente después de escribirlo o refactorizarlo.

El flujo de trabajo obligatorio es el siguiente:
1. **Pausa y Solicita Pruebas:** Cuando termines de implementar una funcionalidad o corregir un bug, **DETENTE**. Pídele explícitamente al usuario que compile y pruebe la aplicación. (Ejemplo de respuesta que debes dar: *"He terminado la implementación. Por favor, prueba la app en tu entorno y respóndeme con un 'OK' para que proceda a subir los cambios a master"*).
2. **Bloqueo Total:** No ejecutes ningún comando de Git hasta que recibas la confirmación explícita del usuario.
3. **Espera el 'OK':** Solo puedes continuar con el proceso de Git si el usuario responde con un "OK", "Aprobado", "Funciona" o una confirmación explícita similar.

## 🚀 Ejecución Tras la Aprobación (Solo si el usuario dio el OK)
Una vez que el usuario apruebe los cambios, ejecuta el siguiente protocolo sin necesidad de más preguntas:

1. **Análisis de Cambios (Diff):** Revisa el estado de los archivos modificados.
2. **Generación del Mensaje:** Crea un mensaje de commit semántico en ESPAÑOL siguiendo el estándar Conventional Commits (ej: `feat: [Módulo] Descripción`, `fix: [Módulo] Descripción`).
3. **Despliegue a Master:** Ejecuta los comandos para sincronizar con la rama master. Si existe en el proyecto, utiliza el script del equipo `python jloen_manager.py git "TU_MENSAJE"`. Si no está disponible o falla, utiliza los comandos nativos de git:
   ```bash
   git add .
   git commit -m "TU_MENSAJE"
   git push origin master