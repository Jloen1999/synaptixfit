package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.planner.BlockAlreadyCompletedException;
import com.synaptixfit.domain.exception.planner.BlockInFutureException;
import com.synaptixfit.domain.exception.planner.BlockInPastException;
import com.synaptixfit.domain.exception.planner.BlockLockedException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Bloque del calendario (lienzo semanal): estudio, clase, deporte, examen, repaso…
 *
 * <p>Reglas:
 * <ul>
 *   <li>Dura al menos 30 minutos ({@link TimeRange}).</li>
 *   <li>Los bloques fijos y los hitos inamovibles no cambian de horario.</li>
 *   <li>No se mueve ni se crea (desde el usuario) un bloque en el pasado.</li>
 *   <li>Un bloque completado no cambia de horario: su experiencia depende de la duración y
 *       cambiarla permitiría ganar más de lo que luego se resta al desmarcar.</li>
 *   <li>Experiencia: {@code ceil(minutos / 30) * 10}, una sola vez mientras esté completado (ninguna
 *       si refleja una sesión de rutina o un repaso SM-2, ver {@link #experienceReward()}).</li>
 * </ul>
 */
public final class CalendarBlock {

    public static final int TOPICS_MAX = 1000;
    public static final int LOCATION_MAX = 200;

    /** Semanas extra al «Repetir cada semana»: 15 más la primera cubren un cuatrimestre. */
    public static final int MAX_WEEKLY_REPEATS = 15;

    private final UUID id;
    private final UUID userId;
    private TimeRange range;
    private int dayOfWeek;
    private ActivityType type;
    private Details details;
    private boolean hasConflict;
    private UUID studyPlanId;
    private boolean completed;
    private Instant attendanceRegisteredAt;
    private final boolean fixed;
    private final boolean immovable;
    private boolean xpAwarded;
    private final String icsUid;
    private final UUID studyMaterialId;
    private Double metValue;
    private Double caloriesBurned;
    private Double cognitiveLoad;
    private final Instant createdAt;

    /**
     * Datos editables del bloque que no afectan a su horario.
     *
     * @param routineId      rutina vinculada (bloques de deporte)
     * @param routineWeekId  semana de la rutina
     * @param routineDayId   día de la rutina
     * @param challengeId    reto vinculado
     * @param milestoneId    tarea de reto vinculada
     * @param deadlineId     entrega o examen vinculados
     */
    public record Details(UUID subjectId, String topics, String location, Priority priority, boolean isPrivate,
                          ClassKind classKind, UUID routineId, UUID routineWeekId, UUID routineDayId,
                          UUID challengeId, UUID milestoneId, UUID deadlineId) {

        public Details {
            topics = optionalText(topics, "topics", TOPICS_MAX);
            location = optionalText(location, "location", LOCATION_MAX);
            priority = priority == null ? Priority.MEDIUM : priority;
        }

        public static Details empty() {
            return new Details(null, null, null, Priority.MEDIUM, false, null, null, null, null, null, null, null);
        }

        /**
         * Lo que hereda una copia de «Repetir cada semana»: asignatura, temas, lugar, prioridad,
         * privacidad y tipo de clase. Los vínculos (rutina, reto, tarea, entrega) no: un bloque
         * ligado a un examen o a un día de rutina no tiene sentido repetido cada semana.
         */
        public Details withoutLinks() {
            return new Details(subjectId, topics, location, priority, isPrivate, classKind, null, null, null, null,
                    null, null);
        }
    }

    /** Copia de este bloque en otra franja (otra semana), sin vínculos y sin completar. */
    public CalendarBlock weeklyCopy(UUID newId, TimeRange newRange, int newDayOfWeek, Instant now) {
        return builder()
                .id(newId)
                .userId(userId)
                .range(newRange)
                .dayOfWeek(newDayOfWeek)
                .type(type)
                .details(details.withoutLinks())
                .fixed(fixed)
                .createdAt(now)
                .build();
    }

    private CalendarBlock(Builder b) {
        this.id = Objects.requireNonNull(b.id, "id");
        this.userId = Objects.requireNonNull(b.userId, "userId");
        this.range = Guard.notNull(b.range, "range");
        this.dayOfWeek = b.dayOfWeek < 1 || b.dayOfWeek > 7 ? 1 : b.dayOfWeek;
        this.type = b.type == null ? ActivityType.STUDY : b.type;
        this.details = b.details == null ? Details.empty() : b.details;
        this.hasConflict = b.hasConflict;
        this.studyPlanId = b.studyPlanId;
        this.completed = b.completed;
        this.attendanceRegisteredAt = b.attendanceRegisteredAt;
        this.fixed = b.fixed;
        this.immovable = b.immovable;
        this.xpAwarded = b.xpAwarded;
        this.icsUid = b.icsUid;
        this.studyMaterialId = b.studyMaterialId;
        this.metValue = b.metValue;
        this.caloriesBurned = b.caloriesBurned;
        this.cognitiveLoad = b.cognitiveLoad;
        this.createdAt = b.createdAt;
    }

    public static Builder builder() {
        return new Builder();
    }

    /** Minutos que puntúan como mucho en un bloque (antes un bloque de 24 h daba 480 XP). */
    public static final int MAX_REWARDED_MINUTES = 240;
    /** XP máxima al día por bloques completados (unas 10 h de estudio). */
    public static final int DAILY_XP_CAP = 200;

    /** Experiencia de completar un bloque de {@code minutes} minutos (10 por cada media hora, hasta 4 h). */
    public static int experienceFor(long minutes) {
        return (int) Math.ceil(Math.min(minutes, MAX_REWARDED_MINUTES) / 30.0) * 10;
    }

    /**
     * ¿Puede dar su XP un bloque con {@code reward} si ese día los bloques ya dieron {@code awardedToday}?
     * Es todo o nada (no se reparte una parte) para que al desmarcarlo se reste exactamente lo que dio.
     */
    public static boolean fitsDailyXp(int awardedToday, int reward) {
        return awardedToday + reward <= DAILY_XP_CAP;
    }

    /** Pendiente, en curso, hecho o no hecho respecto a {@code now} ({@link ItemTimeStatus}). */
    public ItemTimeStatus timeStatus(Instant now) {
        return ItemTimeStatus.ofBlock(type, range.start(), range.end(), completed, now);
    }

    /** Solo se marca como hecho un bloque que ya ha empezado. */
    public void requireStarted(Instant now) {
        if (now.isBefore(range.start())) {
            throw new BlockInFutureException();
        }
    }

    /** Comprueba que el bloque empieza en el futuro (creación por el usuario). */
    public void requireNotInPast(Instant now) {
        if (range.start().isBefore(now)) {
            throw new BlockInPastException();
        }
    }

    /** Mueve el bloque a otra franja (cambia inicio y fin). */
    public void moveTo(TimeRange newRange, int newDayOfWeek, Instant now) {
        requireTimeEditable();
        if (newRange.start().isBefore(now)) {
            throw new BlockInPastException();
        }
        this.range = newRange;
        this.dayOfWeek = newDayOfWeek;
    }

    /** Cambia la hora de fin (duración mínima 30 min; el nuevo fin no puede quedar en el pasado). */
    public void resize(Instant newEnd, Instant now) {
        requireTimeEditable();
        TimeRange resized = new TimeRange(range.start(), newEnd);
        if (!newEnd.isAfter(now)) {
            throw new BlockInPastException();
        }
        this.range = resized;
    }

    private void requireTimeEditable() {
        if (fixed || immovable) {
            throw new BlockLockedException();
        }
        if (completed) {
            throw new BlockAlreadyCompletedException();
        }
    }

    /**
     * Actualiza un bloque importado (ICS, escaneo de horario) con los datos de su origen, que manda
     * aunque el bloque sea inamovible. Si ya está completado conserva su horario.
     */
    public void syncFromSource(TimeRange sourceRange, int sourceDayOfWeek, ActivityType sourceType,
                               Details sourceDetails) {
        if (!completed) {
            this.range = sourceRange;
            this.dayOfWeek = sourceDayOfWeek;
        }
        revise(sourceType, sourceDetails);
    }

    /**
     * Cambia tipo y detalles. Un bloque completado no puede cambiar de tipo ni dejar de reflejar (o empezar
     * a reflejar) una sesión de rutina o un repaso: su XP depende de ello y desmarcarlo después restaría otra
     * cantidad (con vincular, desmarcar, desvincular y volver a completar se ganaba XP sin límite).
     */
    public void revise(ActivityType newType, Details newDetails) {
        Guard.notNull(newType, "type");
        Guard.notNull(newDetails, "details");
        if (completed && (newType != type || mirrors(newType, newDetails) != mirrorsTrackedActivity())) {
            throw new BlockAlreadyCompletedException();
        }
        this.type = newType;
        this.details = newDetails;
    }

    /**
     * Marca el bloque como completado con su coste energético y cognitivo (nulos si no aplica).
     *
     * @return false si ya estaba completado (idempotente)
     */
    public boolean complete(Instant now, Double met, Double calories, Double load) {
        if (completed) {
            return false;
        }
        this.completed = true;
        this.attendanceRegisteredAt = type == ActivityType.CLASS ? now : null;
        this.metValue = met;
        this.caloriesBurned = calories;
        this.cognitiveLoad = load;
        return true;
    }

    /** @return false si no estaba completado (idempotente) */
    public boolean uncomplete() {
        if (!completed) {
            return false;
        }
        this.completed = false;
        this.attendanceRegisteredAt = null;
        this.metValue = null;
        this.caloriesBurned = null;
        this.cognitiveLoad = null;
        return true;
    }

    /**
     * Experiencia que da este bloque al completarse. Es 0 para descanso, comida y sueño, y también
     * cuando el bloque solo refleja una actividad que ya puntúa en su propio módulo, para no dar XP
     * dos veces por lo mismo: un bloque de deporte vinculado a un día de rutina (la XP la da la
     * sesión de entrenamiento) y un bloque de repaso de un material (la XP la da el repaso SM-2).
     */
    public int experienceReward() {
        if (!type.grantsExperience() || mirrorsTrackedActivity()) {
            return 0;
        }
        return experienceFor(range.minutes());
    }

    /**
     * Bloque de deporte que no es una sesión de rutina (p. ej. «Fútbol 90 min»): al completarlo su carga
     * física cuenta en el ACWR y la fatiga (las sesiones de rutina ya la registran por su cuenta).
     */
    public boolean countsAsPhysicalActivity() {
        return type == ActivityType.SPORT && !mirrorsTrackedActivity();
    }

    /** ¿Es el reflejo en el calendario de una sesión de rutina o de un repaso SM-2? */
    public boolean mirrorsTrackedActivity() {
        return mirrors(type, details);
    }

    private boolean mirrors(ActivityType t, Details d) {
        return (t == ActivityType.SPORT && d.routineDayId() != null)
                || (t == ActivityType.REVIEW && studyMaterialId != null);
    }

    public void markExperienceAwarded(boolean awarded) {
        this.xpAwarded = awarded;
    }

    public void flagConflict(boolean conflict) {
        this.hasConflict = conflict;
    }

    public void attachToPlan(UUID planId) {
        this.studyPlanId = planId;
    }

    public boolean isLocked() {
        return fixed || immovable;
    }

    private static String optionalText(String value, String field, int max) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String v = value.strip();
        if (v.length() > max) {
            throw new FieldValidationException(field, "INVALID_LENGTH", field + " must have at most " + max + " characters");
        }
        return v;
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public TimeRange range() { return range; }
    public Instant start() { return range.start(); }
    public Instant end() { return range.end(); }
    public int dayOfWeek() { return dayOfWeek; }
    public ActivityType type() { return type; }
    public Details details() { return details; }
    public UUID subjectId() { return details.subjectId(); }
    public boolean hasConflict() { return hasConflict; }
    public UUID studyPlanId() { return studyPlanId; }
    public boolean completed() { return completed; }
    public Instant attendanceRegisteredAt() { return attendanceRegisteredAt; }
    public boolean fixed() { return fixed; }
    public boolean immovable() { return immovable; }
    public boolean xpAwarded() { return xpAwarded; }
    public String icsUid() { return icsUid; }
    public UUID studyMaterialId() { return studyMaterialId; }
    public Double metValue() { return metValue; }
    public Double caloriesBurned() { return caloriesBurned; }
    public Double cognitiveLoad() { return cognitiveLoad; }
    public Instant createdAt() { return createdAt; }

    /** Constructor fluido para crear o reconstruir el bloque. */
    public static final class Builder {
        private UUID id;
        private UUID userId;
        private TimeRange range;
        private int dayOfWeek = 1;
        private ActivityType type;
        private Details details;
        private boolean hasConflict;
        private UUID studyPlanId;
        private boolean completed;
        private Instant attendanceRegisteredAt;
        private boolean fixed;
        private boolean immovable;
        private boolean xpAwarded;
        private String icsUid;
        private UUID studyMaterialId;
        private Double metValue;
        private Double caloriesBurned;
        private Double cognitiveLoad;
        private Instant createdAt;

        public Builder id(UUID v) { this.id = v; return this; }
        public Builder userId(UUID v) { this.userId = v; return this; }
        public Builder range(TimeRange v) { this.range = v; return this; }
        public Builder dayOfWeek(int v) { this.dayOfWeek = v; return this; }
        public Builder type(ActivityType v) { this.type = v; return this; }
        public Builder details(Details v) { this.details = v; return this; }
        public Builder hasConflict(boolean v) { this.hasConflict = v; return this; }
        public Builder studyPlanId(UUID v) { this.studyPlanId = v; return this; }
        public Builder completed(boolean v) { this.completed = v; return this; }
        public Builder attendanceRegisteredAt(Instant v) { this.attendanceRegisteredAt = v; return this; }
        public Builder fixed(boolean v) { this.fixed = v; return this; }
        public Builder immovable(boolean v) { this.immovable = v; return this; }
        public Builder xpAwarded(boolean v) { this.xpAwarded = v; return this; }
        public Builder icsUid(String v) { this.icsUid = v; return this; }
        public Builder studyMaterialId(UUID v) { this.studyMaterialId = v; return this; }
        public Builder metValue(Double v) { this.metValue = v; return this; }
        public Builder caloriesBurned(Double v) { this.caloriesBurned = v; return this; }
        public Builder cognitiveLoad(Double v) { this.cognitiveLoad = v; return this; }
        public Builder createdAt(Instant v) { this.createdAt = v; return this; }

        public CalendarBlock build() {
            return new CalendarBlock(this);
        }
    }
}
