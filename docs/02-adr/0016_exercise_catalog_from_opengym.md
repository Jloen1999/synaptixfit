# 0016. Ampliar el catálogo de ejercicios con openGym (AGPL-3.0)

* **Estado:** Aprobado
* **Fecha:** 2026-10-23
* **Autores:** Equipo SynaptixFit

## Contexto
El catálogo heredado tenía 909 ejercicios, casi todos de fuerza en gimnasio, con vídeo (Gym visual, con licencia del propietario) y textos en español irregulares. Faltaban estiramientos, movilidad, yoga, pilates, pliometría, calistenia, combate y readaptación: justo lo que hace falta para calentar, volver a la calma o entrenar sin material. Escribir miles de fichas a mano no es viable.

Los catálogos abiertos más completos encontrados son:
- **openGym** (Duarte Santos): unos 5.600 ejercicios con músculos, material, categoría y nombres en español. Licencia **AGPL-3.0**.
- **exercises-dataset** (hasaneyldrm): 1.324 ejercicios con instrucciones. Licencia MIT. Ya está incluido en openGym.

Los vídeos y las imágenes de esos repositorios son de Gym visual con licencia solo para esos proyectos.

## Decisión
- Se usan los **datos** de openGym (nombre, músculos, material, categoría y traducción), nunca su código ni sus vídeos o imágenes. Las descargas se tratan como datos: no se ejecuta nada de los repositorios.
- `tools/exercises/` limpia y traduce esos datos a nuestro vocabulario y genera una migración nueva, `V850__training_exercise_catalog_expansion.sql`. Detalles y fuentes en `tools/exercises/data/FUENTES.md`.
- Los textos que faltaban (descripción e instrucciones) y los de los 909 originales se redactan con DeepSeek a partir de nombre, material y músculos (`generate_texts.py`), y se revisan por muestreo.
- Se añade `ejercicios.categoria` (12 categorías, `ExerciseCategory`) para buscar por tipo y elegir calentamiento y vuelta a la calma, y `ejercicios.codigo_externo` para no duplicar al regenerar.
- Los ejercicios nuevos no tienen vídeo: el cliente muestra el icono de su categoría.
- El propietario del proyecto acepta la condición de la AGPL-3.0 sabiéndolo.

## Consecuencias
* **Positivas:**
  - El catálogo pasa de 909 a unos 5.400 ejercicios, con categorías que antes no existían.
  - Se pueden ofrecer alternativas para «Cambiar ejercicio» y un calentamiento y una vuelta a la calma por músculo.
  - Los 909 originales ganan una descripción y unas instrucciones mejores.
* **Negativas:**
  - **AGPL-3.0:** como la app se ofrece como servicio en red, el código del servicio que usa estos datos debe poder obtenerse con la misma licencia, y hay que mostrar la atribución («Fuente: openGym, Duarte Santos, AGPL-3.0»). Si en el futuro el código no puede ser abierto, hay que retirar estos datos con una migración nueva y quedarse solo con los de licencia MIT o propios.
  - La migración pesa unos 5 MB y alarga en unos segundos el primer arranque tras desplegarla. El healthcheck debe tolerarlo.
  - Unos 4.500 ejercicios no tienen vídeo. Se compensa con instrucciones paso a paso y el icono de la categoría.

## Alternativas descartadas
- **Solo exercises-dataset (MIT):** sin problema de licencia, pero apenas trae estiramientos, movilidad ni yoga, que eran lo que más faltaba.
- **Escribir el catálogo a mano o generarlo entero con IA:** sin una fuente que dé los músculos y el material, la IA se los inventa y el ranking de alternativas deja de ser fiable.
- **Usar también los vídeos de los repositorios:** su licencia no lo permite.
