# 12 - Guía de Usuario

**Proyecto:** SynaptixFit  
**Versión:** 4.3  
**Fecha:** 21-06-2026

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

### 3.1 Registro y Onboarding

SynaptixFit usa **Google OAuth** como método exclusivo de registro. El onboarding se compone de 4 pasos secuenciales:

1. **Inicia sesión con Google:** Toca **"Iniciar sesión con Google"** en la pantalla de acceso. La app usará tu cuenta de Google para autenticarte.
2. **Configura tu perfil académico:** Selecciona tu universidad, centro y carrera desde el catálogo académico enriquecido. Esto permite a la app personalizar tu carga académica.
3. **Establece tu nombre y contraseña:** Define tu nombre completo y una contraseña segura (mín. 8 caracteres). El email se toma automáticamente de Google (readonly).
4. **Completa tu perfil físico:**
   - **Datos demográficos:** Edad, sexo.
   - **Datos físicos:** Peso (kg) y altura (con toggle metros/cm). Se calcula tu IMC automáticamente.
   - **Nivel de actividad:** Sedentario, ligero, moderado o alto.
   - **Objetivos:** Selecciona en un grid de 2 columnas: Hipertrofia, Fuerza, Resistencia, etc.

> 💡 Puedes saltarte el perfil físico y completarlo después desde **Perfil → Configuración**. El perfil académico es obligatorio para la personalización.

#### Inicio de sesión existente

Si ya tienes cuenta, puedes iniciar sesión con:
- **Email y contraseña** (si configuraste contraseña en el onboarding)
- **Google** (mismo método que el registro)

---

## 4. Flujos Principales

### 4.1 Dashboard (Pantalla de Inicio)

El dashboard te muestra de un vistazo tu estado físico y académico:

1. **Saludo y progreso** — Tu avatar, nivel, XP y rachas (🔥 entrenamiento, 🧠 estudio).
2. **Consejo del día** — Un consejo personalizado generado por IA basado en tu energía y carga académica.
3. **Acciones rápidas** — Botones para iniciar Pomodoro, entrenar, escanear apuntes o crear un reto.
4. **Progreso semanal** — Si tienes una rutina activa, verás en qué semana vas.
5. **Carga cognitiva** — Una barra que indica tu nivel de exigencia mental actual.
6. **Estado actual** — Tres medidores circulares: Energético, Adherencia Académica y Carga Cognitiva. Toca cualquiera para ver el detalle.
7. **KPIs** — Calorías quemadas hoy y sesiones completadas esta semana.
8. **Línea de tiempo** — Tus actividades del día organizadas en 3 pestañas: Hoy (clases, estudio, entrenamiento pendiente), Semana (entregas próximas) y Retos (retos activos con progreso).

### 4.2 Crear una Rutina de Entrenamiento

Hay dos formas de crear una rutina:

**Vía rápida con IA (recomendada):**
1. Ve a **Bienestar → Rutinas**.
2. Pulsa el botón verde **"Sugerir Rutina con IA"**.
3. Verás una animación profesional de generación IA mostrándote paso a paso qué está analizando (perfil, historial, estado diario, ejercicios, etc.).
4. En segundos, la IA habrá rellenado el nombre, descripción y objetivo de tu rutina. Puedes cancelar en cualquier momento pulsando **"Cancelar"**.
5. Revisa los campos, ajusta si lo deseas, y continúa a Paso 2 para añadir ejercicios.

**Vía manual (3 pasos):**

```
PASO 1 — Metadatos:
  1. Ve a la pestaña Bienestar → Mis Rutinas → botón (+)
  2. Define: nombre, descripción, objetivo (Hipertrofia, Fuerza Máxima, etc.)
  3. Elige visibilidad, duración (1-12 semanas) y días por semana
  4. ⚡ "Generar rutina rápida" (verde, siempre visible): pipeline determinista <2s
     └─ Rellena automáticamente toda la estructura de ejercicios
  5. ✨ "Recomendar rutina con IA" (contorno, requiere API key): añade refinamiento IA

PASO 2 — Estructura (Semanas × Días × Ejercicios):
  1. Selecciona cada semana y añade/edita sus días
  2. Por cada día: añade ejercicios desde el catálogo (~1300 ejercicios)
  3. Ajusta series, repeticiones, descanso y peso (acepta decimales: 75.5 kg)

PASO 3 — Revisa tu rutina:
  1. Revisa el resumen completo: semanas, días, ejercicios, periodización
  2. Toca "Crear rutina" para guardar todo en tu perfil
  3. Serás redirigido a la pantalla de detalle de tu nueva rutina
```

> 💡 El campo de peso acepta valores decimales (ej: 22.5, 75.0) para cargas precisas.
> 💡 El botón "⚡ Generar rutina rápida" funciona sin conexión a internet (no usa IA).

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
7. Verás cuánto **XP** ganaste (`+130 XP 🔥`) y si subiste de nivel (`¡Subiste a nivel 5! 🎉`).

### 4.5 Planificar tu Semana con Time-Blocking

SynaptixFit te ayuda a organizar tu semana completa combinando clases, estudio, deporte y entregas en un solo calendario semanal. La IA distribuye tus horas de estudio automáticamente respetando tus horarios fijos.

#### 4.5.1 Configurar tus Horarios Fijos (una sola vez)

1. Ve a **Académico → Configuración**.
2. Añade tus **clases presenciales** y **compromisos fijos** indicando día de la semana, hora de inicio y duración.
3. Estos horarios aparecerán como bloques grises bloqueados en el grid de time-blocking. La IA nunca los modificará ni solapará bloques sobre ellos.

> 💡 Solo necesitas configurar esto una vez. Si tus horarios cambian al inicio de cada cuatrimestre, vuelve aquí y actualízalos.

#### 4.5.2 El Inbox — Declarar tus Intenciones

1. Ve a **Académico → Planificar mi semana**.
2. Verás la pantalla "Inbox" con un diseño minimalista:
   - **Slider de horas de estudio:** Desliza para indicar cuántas horas quieres dedicar al estudio esta semana (entre 0 y 50 horas).
   - **Slider de días de deporte:** Indica cuántos días quieres entrenar (0-7 días). La duración de cada sesión se configura en el propio Inbox con un dropdown (30/45/60/90/120 min).
   - **Entregas pendientes:** La app detecta automáticamente tus entregas y exámenes de la semana actual.
3. El slider de horas de estudio se precarga con tu objetivo del perfil académico si lo has configurado.

#### 4.5.3 Ir al Canvas

1. Revisa que tus intenciones sean correctas en el Inbox.
2. Pulsa el botón **"Ir al Canvas"**.
3. Serás llevado al lienzo semanal donde la IA genera automáticamente la distribución de tus bloques al inicializar el canvas.
4. Los bloques generados respetan tus horarios fijos y preferencias configuradas en el Inbox.

> 💡 Si no tienes la API key de Gemini configurada, la app usa un algoritmo de distribución equitativa como fallback.

#### 4.5.4 El Lienzo — Revisar y Ajustar

El Canvas muestra tu semana en una cuadrícula de 7 columnas (días) × 16 filas (horas, de 7:00 a 23:00) con fondo oscuro para reducir fatiga visual. La columna izquierda siempre corresponde al día actual.

**Barra de navegación semanal infinita:**
- `< Anterior | Sem 15-21 Jun 2026 | Siguiente > | Hoy` — permite navegar semanas hacia adelante y atrás sin límite, con retorno rápido a la semana actual.

1. **Identifica tus bloques por colores:**
   - 🔵 **Azul:** Bloques de estudio (generados por IA o manuales)
   - 🟠 **Naranja:** Sesiones de deporte. Si provienen de una rutina, muestran una barra blanca vertical a la izquierda y el nombre del día de la rutina.
   - ⚪ **Gris:** Clases y horarios fijos (no se pueden mover)
   - 🔴 **Rojo:** Exámenes y entregas (hitos inamovibles, no se pueden arrastrar)

2. **Añade bloques manualmente:**
   - Pulsa en un hueco vacío del canvas para abrir el `AcademicBlockSheet`.
   - Selecciona el tipo de bloque: Estudio, Examen, Entrega, Deporte, o Reto.
   - En la pestaña **Deporte**, puedes seleccionar una rutina y activar "Distribuir rutina completa" para colocar automáticamente todos los días de entrenamiento en el canvas.

3. **Ajusta con drag & drop:**
   - Mantén presionado cualquier bloque (excepto los grises de clase y los rojos inamovibles) y arrástralo a otro día u hora.
   - El bloque hace "snap" automático a intervalos de 30 minutos.

4. **Redimensiona bloques:**
   - Arrastra el borde inferior de un bloque para ajustar su duración.

5. **Marca bloques como completados:**
   - Cada bloque de estudio/deporte tiene un checkbox. Al marcarlo, ganas XP (`ceil(mins/30) × 10`).

6. **Elimina bloques:**
   - Desliza un bloque hacia la izquierda o pulsa el icono de papelera.

#### 4.5.5 Guardar y Visualizar

1. Cuando estés satisfecho con tu plan, pulsa **"Guardar plan"** en la barra inferior del canvas.
2. La app guarda todos los bloques generados en tu base de datos.
3. Serás redirigido a la pantalla de **Plan Semanal** donde verás:
   - Tus bloques del día en la timeline.
   - Cada bloque muestra su tipo, asignatura y duración.
   - Puedes **marcar bloques como completados** ✅ para seguir tu adherencia y ganar XP.
4. La **barra de progreso** en el Canvas te muestra cuántas horas de estudio y sesiones de deporte has planificado.
5. Si cumples ≥80% de tu plan 4 semanas seguidas, desbloquearás la insignia **"Planificador Maestro"** 🏆.

> 💡 Puedes volver al canvas en cualquier momento desde el Inbox. Los bloques se guardan automáticamente al moverlos o redimensionarlos.

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

### 4.8 Sistema de XP y Niveles

SynaptixFit premia tu consistencia con experiencia (XP) que te hace subir de nivel. Cada 1000 × nivel de XP acumulada, subes un nivel.

#### Cómo se gana XP

| Actividad | XP | Cuándo |
|-----------|-----|--------|
| **Completar una sesión de entrenamiento** | 56–190 XP | Al finalizar sesión en vivo. Depende de duración (máx 90 min) y RPE (esfuerzo percibido). |
| **Completar un reto simple** | 200 XP | Al marcar el reto como completado. |
| **Completar un reto complejo** | 400–1300 XP | Según la cantidad de hitos del reto. |
| **Cumplir meta de estudio semanal** | 150 XP | Al alcanzar ≥80% de tus horas de estudio planeadas. Único por semana. |

#### Subir de nivel

- Cada nivel requiere `1000 × nivel_actual` XP acumulada.
- Al subir de nivel, el excedente de XP se acumula para el siguiente nivel.
- Cuando subes de nivel al finalizar una sesión, ves un mensaje especial: **"¡Subiste a nivel 5! 🎉 +130 XP"**.
- Tu nivel se muestra en el saludo del dashboard y en tu perfil.

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
La racha se ha eliminado del dashboard. El progreso se mide ahora por XP y nivel, que nunca se pierden.

**¿Puedo usar la app sin conexión?**  
Sí. Los datos se guardan localmente y se sincronizan al reconectar.

**¿Mis datos físicos son visibles para otros?**  
No. Peso, altura e IMC son siempre privados (regla RB-20).

**¿Puedo clonar un reto público de otro usuario?**  
Sí. Desde el detalle de un reto público, toca "Clonar reto".

**¿Cuántos ejercicios necesita una rutina?**  
Mínimo 3 ejercicios para poder guardarla.

---

**Documento compilado:** 21-06-2026  
**Última revisión:** v4.3 — §4.5.3 actualizado: eliminado botón "Generar mi semana", reemplazado por "Ir al Canvas". §4.5.4 actualizado con distribución de rutina desde pestaña Deporte, indicador visual de rutina en bloques, y bloqueos inamovibles (exámenes/entregas). §4.5.5 actualizado: barra inferior "Guardar plan" en vez de "Guardar semana" en AppBar. Insignia "Planificador Maestro" ya implementada.
