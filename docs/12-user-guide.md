# 12 - Guía de Usuario

**Proyecto:** SynaptixFit  
**Versión:** 4.0  
**Fecha:** 13-05-2026

---

## 1. ¿Qué es SynaptixFit?

SynaptixFit es una aplicación móvil diseñada para estudiantes universitarios que necesitan equilibrar su carga académica con sus objetivos de bienestar físico. La app integra en una sola experiencia:

- 📚 Planificación de estudio con detección de conflictos horarios.
- 💪 Gestión de rutinas de entrenamiento con catálogo de ejercicios.
- 🎯 Sistema de retos personales con gamificación.
- 👥 Red social de logros entre compañeros.
- 🔔 Notificaciones inteligentes que se adaptan a tu ritmo.

---

## 2. Roles de Usuario

| Rol | Descripción | Permisos |
|-----|------------|----------|
| **Estudiante** | Usuario principal de la aplicación | Crear, ver, editar y compartir sus propios recursos |
| **Administrador** | Gestión del catálogo y moderación | Gestionar ejercicios, notificaciones globales |

---

## 3. Primeros Pasos

### 3.1 Registro

1. Abre la app y toca **"Crear Cuenta"**.
2. Introduce tu correo universitario y una contraseña segura (mín. 8 caracteres, 1 mayúscula, 1 número).
3. Verifica tu correo con el código OTP enviado.

### 3.2 Onboarding — Perfil Físico

Tras registrarte, la app te pedirá:

1. **Datos demográficos:** Edad, sexo, ciudad.
2. **Datos físicos:** Peso (kg) y altura (cm). Se calcula tu IMC automáticamente.
3. **Nivel de actividad:** De sedentario a muy activo.
4. **Objetivos:** Perder peso, ganar masa, fitness general, fuerza o resistencia.

> 💡 Puedes saltarte esto y completarlo después desde **Perfil → Configuración**.

---

## 4. Flujos Principales

### 4.1 Dashboard (Pantalla de Inicio)

Al abrir la app verás:

- Tu saludo personalizado con racha actual.
- **KPIs del día:** Calorías quemadas, sesiones completadas, horas de estudio.
- **Retos activos** con barra de progreso.
- **Botón flotante (+)** para crear una nueva rutina.

### 4.2 Crear una Rutina de Entrenamiento

Hay dos formas de crear una rutina:

**Vía rápida con IA (recomendada):**
1. Ve a **Bienestar → Rutinas**.
2. Pulsa el botón verde **"Sugerir Rutina con IA"**.
3. Verás una animación profesional de generación IA mostrándote paso a paso qué está analizando (perfil, historial, estado diario, ejercicios, etc.).
4. En segundos, la IA habrá rellenado el nombre, descripción y objetivo de tu rutina. Puedes cancelar en cualquier momento pulsando **"Cancelar"**.
5. Revisa los campos, ajusta si lo deseas, y continúa a Paso 2 para añadir ejercicios (también puedes usar IA con "Recomendar ejercicios").

> 💡 También puedes usar la IA desde dentro del Paso 1 con los botones "Recomendar rutina con IA" y "Recomendar ejercicios". Ambos muestran la misma pantalla de carga profesional con botón de cancelación.

**Vía manual (3 pasos):**

```
PASO 1 — Metadatos:
  1. Ve a la pestaña Bienestar → Mis Rutinas → botón (+)
  2. Define: nombre, descripción, objetivo (fuerza, hipertrofia, etc.)
  3. Elige visibilidad, duración (1-12 semanas) y días por semana
  4. Opcional: pulsa "Recomendar rutina con IA" para que Gemini sugiera todo
     └─ Puedes cancelar la recomendación en cualquier momento si tarda

PASO 2 — Estructura (Semanas × Días × Ejercicios):
  1. Selecciona cada semana y añade/edita sus días
  2. Por cada día: añade ejercicios desde el catálogo (~1300 ejercicios)
  3. Ajusta series, repeticiones, descanso y peso (acepta decimales: 75.5 kg)
  4. Opcional: pulsa "Sugerir ejercicios con IA" para llenar un día automáticamente
     └─ También puedes cancelar si prefieres elegir manualmente

PASO 3 — Revisa tu rutina:
  1. Revisa el resumen completo: semanas, días y ejercicios totales
  2. Toca "Crear rutina" para guardar todo en tu perfil
  3. Serás redirigido a la pantalla de detalle de tu nueva rutina
```

> 💡 El campo de peso acepta valores decimales (ej: 22.5, 75.0) para cargas precisas.

### 4.3 Revisar y Gestionar tu Rutina

Al abrir una rutina desde "Mis Rutinas", verás una vista detallada con navegación por niveles:

**Navegación por drill-down (3 niveles):**

| Nivel | ¿Qué ves? | ¿Qué puedes hacer? |
|-------|-----------|-------------------|
| **Semanas** | Chips horizontales con tipo (Adapt/Carga/Pico/Desc) y conteo de ejercicios | Toca una semana para ver sus días |
| **Días** | Lista de días con vista previa de ejercicios y estado (pendiente/en progreso/completado) | Toca un día para **expandirlo** y ver todos sus ejercicios con detalle |
| **Ejercicios** | Lista completa de ejercicios del día con series, reps, descanso y peso | Edita los valores inline, sustituye ejercicios (long-press), o inicia la sesión |

**Interacciones clave:**
- **Expandir/colapsar día:** un solo tap muestra u oculta los ejercicios del día
- **Editar ejercicio:** tap en un ejercicio habilita los controles ± para cambiar series/reps/descanso/peso
- **Sustituir ejercicio:** mantén presionado un ejercicio para reemplazarlo desde el catálogo
- **Iniciar sesión:** botón "Iniciar" en un día (solo disponible si el día tiene ejercicios)
- **Añadir día/ejercicio:** botones para agregar más días a una semana o ejercicios a un día

### 4.4 Completar una Sesión (con check-in inteligente)

1. Desde **Mis Rutinas**, abre la rutina y pulsa **"Iniciar"** en el día que quieras entrenar.
2. El cronómetro y los ejercicios aparecen **inmediatamente**.
3. Al completar tu **primera serie**, durante el descanso de 90s, la app te preguntará **"¿Cómo te sientes hoy?"** (sueño, estrés, energía, dolor).
   - *Si ya respondiste hoy, no se volverá a preguntar.*
4. Según tus respuestas, la **IA de SynaptixFit** te sugerirá adaptaciones:
   - Reducir series si hay fatiga alta
   - Evitar ejercicios de zonas con dolor
   - Bajar intensidad si tu energía está baja
   - Puedes aceptar todas, una sola, o ignorar
5. Continúa tu sesión con los ajustes aplicados.
6. Al finalizar, la app preguntará tu **RPE** (esfuerzo percibido) y si guardar los cambios para futuras sesiones.

### 4.5 Planificar tu Semana Académica

1. Ve a la pestaña **Académico**.
2. Agrega tus asignaturas y bloques de clase.
3. La app detecta automáticamente conflictos con tus entrenamientos.
4. Revisa las sugerencias de ajuste y acepta o descarta.

### 4.6 Crear un Reto

**Reto simple:**
1. Ve a **Retos → Crear Reto**.
2. Completa: título, tipo (fitness/académico), meta, fechas y visibilidad.
3. Toca "Publicar".

**Reto complejo:**
1. Igual que el simple, pero añade hitos con pesos.
2. La app valida que la suma de pesos sea exactamente 100%.
3. Los hitos se pueden reordenar arrastrándolos.

### 4.7 Interactuar en el Muro Social

- Ve a la pestaña **Social**.
- Visualiza logros de tus amigos.
- Da "me gusta" o comenta (máx. 200 caracteres).
- Filtra por: hoy, esta semana o este mes.

---

## 5. Configuración de Privacidad

Desde **Perfil → Configuración → Privacidad**:

| Opción | Valores posibles | Default |
|--------|-----------------|---------|
| Visibilidad del perfil | Público, Solo amigos, Privado | Solo amigos |
| Autopost de logros | Activado / Desactivado | Activado |
| Datos físicos | Siempre privados | Privado (no modificable) |

---

## 6. Notificaciones

Las notificaciones se clasifican automáticamente en tres niveles:

| Nivel | Color | Ejemplos |
|-------|-------|---------|
| 🔴 **Crítica** | Rojo | Conflicto horario, reto a punto de vencer |
| 🟡 **Recomendada** | Amarillo | Sugerencia de ajuste de carga, hito próximo |
| 🔵 **Informativa** | Azul | Logro de un amigo, recordatorio general |

Puedes configurar una **franja de silencio** (ej: 22:00-08:00) desde Configuración.

---

## 7. Preguntas Frecuentes (FAQ)

**¿Qué pasa si pierdo mi racha?**  
La racha se muestra informativamente, sin penalización. Puede ocultarse desde Configuración.

**¿Puedo usar la app sin conexión?**  
Sí. Los datos se guardan localmente y se sincronizan al reconectar.

**¿Mis datos físicos son visibles para otros?**  
No. Peso, altura e IMC son siempre privados (regla RB-20).

**¿Puedo clonar un reto público de otro usuario?**  
Sí. Desde el detalle de un reto público, toca "Clonar reto".

**¿Cuántos ejercicios necesita una rutina?**  
Mínimo 3 ejercicios para poder guardarla.

---

**Documento compilado:** 13-05-2026  
**Última revisión:** v3.3
