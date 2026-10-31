# 0025. Pomodoro de toda la app (bloc único)

* **Estado:** Aprobado
* **Fecha:** 2026-10-31
* **Autores:** SynaptixFit

## Contexto
El perfil del cliente (`docs/01-architecture/profiles/frontend-flutter-bloc.md`) registra los blocs como
`factory`: viven lo que su pantalla. El Pomodoro vivía así, con dos problemas:
- Al salir de la pantalla se paraba, y los estudiantes querían consultar apuntes o el calendario mientras corre.
- Si se cerraba la app, la fase terminada no se registraba nunca.

## Decisión
* **Excepción al perfil, solo para `PomodoroBloc`:** se registra con `registerLazySingleton` y no se cierra al
  salir. La pantalla lo usa con `BlocProvider.value`.
* **La fase en curso se guarda en el teléfono** (`ActiveFocusTimerRepositoryContract`, SharedPreferences), con la
  cuenta que la empezó.
* **Al entrar en las pestañas, `FocusTimerHost` la recupera:**
  - si terminó con la app cerrada, la registra como completada;
  - si sigue en marcha, vuelve a contar y vuelve a programar el aviso de fin;
  - si es de otra cuenta, la descarta.
* **Al cerrar sesión** se para, se olvida la fase, se quitan su aviso y su notificación, y se vuelve a la
  configuración por defecto.
* **Cada apertura sin fase en marcha** decide de nuevo a qué asignatura o bloque se vincula (también a ninguno),
  para no arrastrar la anterior.
* **`FocusTimerBar`** lo muestra sobre la navegación. En Android hay además una notificación fija con la cuenta
  atrás (`UpdateOngoingTimerUseCase`); en iOS no, porque quedaría un aviso normal en cada cambio.
* **Quitar los recordatorios** (interruptor apagado) ya no borra el aviso ni la notificación del Pomodoro.

## Consecuencias
* **Positivas:**
  - el temporizador sigue mientras se usa el resto de la app;
  - ninguna fase completada se pierde por cerrar la app.
* **Negativas:**
  - un bloc que vive toda la sesión: hay que limpiarlo a mano al cerrar sesión (ya se hace).
* **A vigilar:**
  - si la fase termina con la app cerrada y al reabrirla no hay red, el registro falla y la fase no se reintenta.
  - no aplicar este patrón a otros blocs sin un ADR propio.
