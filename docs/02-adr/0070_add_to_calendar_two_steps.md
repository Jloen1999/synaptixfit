# ADR 0070: «Añadir al calendario» en dos pasos

- **Estado:** aceptado (28-11-2026). Solo cliente.
- **Contexto:** la hoja de crear mezclaba chips de tipo, «Más tipos», tres pasos numerados y una pestaña «Distribuir rutina»; quien quería apuntar un partido o un WOD no encontraba dónde.
- **Decisión:** crear va en dos pasos. Paso 1, «¿Qué quieres añadir?», con ocho tarjetas (`AppShortcutTile` en `AppShortcutGrid`, icono y texto): Estudio, Clase, Entrega o examen, Gimnasio, Deporte, WOD, Personal y Descanso, comida o sueño. Paso 2, solo los campos de lo elegido, «Cambiar tipo», cuándo y duración, «Más opciones» plegado (repetir, privado, prioridad, reto…) y una sola acción que dice lo que se añade («Añadir partido de pádel»).
- **Deporte y WOD** se guardan como evento de tipo deporte con su nombre en `topics` («Partido de pádel», «WOD»), usando el catálogo `Sport`/`SportLabels` (ADR 0068 y 0069): sin campos nuevos en la API.
- **Gimnasio** elige la rutina o «Sesión libre» y lleva dentro «Repartir mi rutina en la semana» (antes la pestaña «Distribuir rutina»).
- **Entrega o examen** sigue abriendo el formulario de entrega (`BlockEditorOutcome.deadlineRequested`, ADR 0039).
- **Editar** un evento no cambia: conserva sus pasos y su selector de tipo.
- **Consecuencias:** «Repaso» ya no se crea a mano desde la hoja (no está entre las ocho tarjetas; un evento de repaso existente se sigue editando). El foco entra en el paso 2 por «Cambiar tipo» (o por «Nombre» en Personal).
- **Textos:** `frontend/tool/l10n_add_sheet_tanda5.py` (es/en/fr/pt).
