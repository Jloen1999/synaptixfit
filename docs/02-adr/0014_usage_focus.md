# 0014. Enfoque de uso: estudios, deporte o ambos

* **Estado:** Aprobado
* **Fecha:** 2026-10-21
* **Autores:** Equipo SynaptixFit

## Contexto
SynaptixFit une estudio y entrenamiento, pero no todo el mundo usa las dos partes. Una persona que solo entrena veía asignaturas, entregas y repasos; una que solo estudia veía rutinas, check-in y ACWR. Eso añadía carga visual y pasos inútiles en el registro.

## Decisión
- Cada cuenta tiene un **enfoque de uso** (`UsageFocus`: `ACADEMIC`, `FITNESS` o `BOTH`), guardado en `usuarios.enfoque` (V650). Se elige en el onboarding (paso `FOCUS`) y se cambia en Perfil → Editar cuenta (`PATCH /api/v1/me`). Sin elegir equivale a `BOTH`; las cuentas que ya existían se rellenaron con `ambos`.
- **El servidor decide qué entra en cada ámbito**, en el dominio:
  - `OnboardingStatus.pendingSteps`: con solo estudios no pide el perfil físico; con solo deporte no pide perfil académico ni asignaturas. El cierre del onboarding pasa a `usuarios.onboarding_completado` (con solo estudios no existe el perfil físico, donde se guardaba antes).
  - Inicio (`DashboardService`, `SmartBannerRules`, `ActivityType.visibleFor`): avisos, eventos de hoy, próximo entreno y retos destacados solo del ámbito que se usa.
  - Retos (`ChallengeType.allowedFor`): crear, editar o clonar un reto de otro ámbito da `CHALLENGE_TYPE_OUTSIDE_FOCUS`; los listados se limitan al ámbito.
  - Insignias (`BadgeCategory.visibleFor`) y sugerencias del planificador (`PlanningSuggestionService`) se filtran con `UsageFocusPort`.
- **El cliente solo decide qué se ve**: oculta la pestaña Académico o Rutinas, redirige `/academic*` o `/training*`, y en Inicio, Progreso, Perfil y Planificador muestra las secciones del ámbito. La correspondencia del cliente vive en un único sitio, `UsageFocus` del dominio (`allowsBlock`, `allowsEvent`, `challengeTypes`, `allowsBadges`), igual que en el servidor.

## Consecuencias
* **Positivas:** cada persona ve solo lo que usa; el registro es más corto; la regla está en el dominio y se prueba sin infraestructura.
* **Negativas:** el enfoque es un filtro de vista, no un permiso: la API de un ámbito sigue respondiendo (los datos son de la persona). La correspondencia de tipos está en el servidor y en `UsageFocus` del cliente y hay que mantenerlas a la par. La regulación cruzada sigue calculándose aunque no se muestre con un solo enfoque.
