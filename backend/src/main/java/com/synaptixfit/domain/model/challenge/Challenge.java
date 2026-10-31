package com.synaptixfit.domain.model.challenge;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.challenge.ChallengeAlreadyCompletedException;
import com.synaptixfit.domain.exception.challenge.ChallengeExpiredException;
import com.synaptixfit.domain.exception.challenge.InvalidChallengeDatesException;
import com.synaptixfit.domain.exception.challenge.InvalidMilestoneDependencyException;
import com.synaptixfit.domain.exception.challenge.InvalidMilestoneOrderException;
import com.synaptixfit.domain.exception.challenge.InvalidMilestoneWeightsException;
import com.synaptixfit.domain.exception.challenge.MilestoneAlreadyCompletedException;
import com.synaptixfit.domain.exception.challenge.MilestoneLockedException;
import com.synaptixfit.domain.exception.challenge.MilestoneNotFoundException;
import com.synaptixfit.domain.exception.challenge.ProgressMilestoneRequiredException;
import com.synaptixfit.domain.exception.challenge.TooManyMilestonesException;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

/**
 * Reto con sus tareas opcionales (agregado). Reglas principales:
 * <ul>
 *   <li>Sin tareas, completar el reto otorga el XP de su dificultad. Con tareas, el XP lo da
 *       cada tarea y el reto se completa solo cuando todas lo están (progreso ponderado 100 %).</li>
 *   <li>Anti-farmeo: {@code xpAwarded} guarda el XP exacto del estado completado actual y se
 *       resta tal cual al descompletar o borrar. Un reto da como mucho {@value #MAX_XP} XP entre todas
 *       sus tareas (antes, 12 tareas difíciles marcadas a mano daban 840), y un reto de sesiones
 *       marcado a mano antes de llegar al objetivo no da XP hasta que las sesiones lo alcanzan.</li>
 *   <li>Como máximo {@value #MAX_MILESTONES} tareas cuyos pesos suman 100.</li>
 *   <li>Las dependencias (AND / OR / X_OF_Y) desbloquean tareas automáticamente; una tarea
 *       bloqueada no se puede completar a mano.</li>
 *   <li>Un reto de fitness sin tareas con {@code sessionTarget} avanza con las sesiones de
 *       entrenamiento completadas en su periodo, recontadas desde cero (ADR 0009).</li>
 * </ul>
 */
public final class Challenge {

    public static final int TITLE_MIN = 5;
    public static final int TITLE_MAX = 80;
    public static final int GOAL_MAX = 500;
    public static final int MAX_MILESTONES = 12;
    public static final int SESSION_TARGET_MAX = 365;
    /** Tope de XP de un reto: el doble de uno difícil sin tareas. */
    public static final int MAX_XP = 2 * Difficulty.HIGH.xp();
    /** Margen admitido en la suma de pesos (p. ej. 3 × 33,33 = 99,99). */
    static final double WEIGHT_TOLERANCE = 0.1;

    private final UUID id;
    private final UUID ownerId;
    private String title;
    private ChallengeType type;
    private String goal;
    private Visibility visibility;
    private boolean completed;
    private Instant startAt;
    private Instant endAt;
    private final Instant createdAt;
    private Instant updatedAt;
    private int currentStreak;
    private int bestStreak;
    private LocalDate lastActiveDay;
    private UUID subjectId;
    private Difficulty difficulty;
    private ChallengeLink link;
    private int xpAwarded;
    private final UUID originId;
    private final UUID originOwnerId;
    private final String originOwnerName;
    private double manualProgress;
    private Integer sessionTarget;
    private int sessionsCompleted;
    private List<Milestone> milestones;

    private Challenge(Builder b) {
        this.id = Objects.requireNonNull(b.id, "id");
        this.ownerId = Objects.requireNonNull(b.ownerId, "ownerId");
        this.createdAt = b.createdAt;
        this.updatedAt = b.updatedAt == null ? b.createdAt : b.updatedAt;
        this.completed = b.completed;
        this.currentStreak = Math.max(0, b.currentStreak);
        this.bestStreak = Math.max(this.currentStreak, b.bestStreak);
        this.lastActiveDay = b.lastActiveDay;
        this.xpAwarded = Math.max(0, b.xpAwarded);
        this.originId = b.originId;
        this.originOwnerId = b.originOwnerId;
        this.originOwnerName = b.originOwnerName;
        this.manualProgress = Math.max(0, b.manualProgress);
        this.sessionsCompleted = Math.max(0, b.sessionsCompleted);
        applyDetails(new ChallengeDetails(b.title, b.type, b.goal, b.visibility, b.difficulty, b.startAt, b.endAt,
                b.subjectId, b.link, b.sessionTarget));
        this.milestones = new ArrayList<>(b.milestones);
        this.milestones.sort(Comparator.comparingInt(Milestone::order));
    }

    public static Builder builder() {
        return new Builder();
    }

    /** Crea un reto nuevo con sus tareas iniciales (opcionales). */
    public static Challenge create(UUID id, UUID ownerId, ChallengeDetails details, List<MilestoneDraft> drafts,
                                   Instant now) {
        Challenge challenge = builder().id(id).ownerId(ownerId).title(details.title()).type(details.type())
                .goal(details.goal()).visibility(details.visibility()).difficulty(details.difficulty())
                .startAt(details.startAt()).endAt(details.endAt()).subjectId(details.subjectId())
                .link(details.link()).sessionTarget(details.sessionTarget()).createdAt(now).updatedAt(now).build();
        if (drafts != null && !drafts.isEmpty()) {
            challenge.replaceMilestones(drafts);
        }
        return challenge;
    }

    // ---------------------------------------------------------------- datos

    /** Sustituye los datos editables validando título, meta y fechas. */
    public void updateDetails(ChallengeDetails details) {
        applyDetails(details);
    }

    private void applyDetails(ChallengeDetails d) {
        this.title = Guard.length(d.title(), "title", TITLE_MIN, TITLE_MAX);
        this.goal = d.goal() == null || d.goal().isBlank() ? this.title : Guard.length(d.goal(), "goal", 1, GOAL_MAX);
        Instant start = Guard.notNull(d.startAt(), "startAt");
        Instant end = Guard.notNull(d.endAt(), "endAt");
        if (!end.isAfter(start)) {
            throw new InvalidChallengeDatesException();
        }
        this.startAt = start;
        this.endAt = end;
        this.subjectId = d.subjectId();
        this.type = d.type() != null ? d.type() : (d.subjectId() != null ? ChallengeType.ACADEMIC : ChallengeType.FITNESS);
        this.visibility = d.visibility() == null ? Visibility.PRIVATE : d.visibility();
        this.difficulty = d.difficulty() == null ? Difficulty.MEDIUM : d.difficulty();
        this.link = d.link();
        if (d.sessionTarget() != null) {
            Guard.range(d.sessionTarget(), "sessionTarget", 1, SESSION_TARGET_MAX);
            if (this.type != ChallengeType.FITNESS) {
                throw new FieldValidationException("sessionTarget", "INVALID",
                        "sessionTarget is only allowed in FITNESS challenges");
            }
        }
        this.sessionTarget = d.sessionTarget();
    }

    /** Oculta el reto a otros usuarios. Devuelve true si cambia. */
    public boolean hideFromOthers() {
        if (visibility == Visibility.PRIVATE) {
            return false;
        }
        visibility = Visibility.PRIVATE;
        return true;
    }

    public void touch(Instant now) {
        this.updatedAt = now;
    }

    // ---------------------------------------------------------------- tareas

    /**
     * Reemplaza la lista de tareas. Las tareas con {@code id} existente conservan su progreso y su
     * XP; las que desaparecen restan el XP que habían dado.
     */
    public ChallengeChanges replaceMilestones(List<MilestoneDraft> drafts) {
        if (drafts.size() > MAX_MILESTONES) {
            throw new TooManyMilestonesException(MAX_MILESTONES);
        }
        double[] weights = resolveWeights(drafts);
        validateDependencies(drafts);

        Map<UUID, Milestone> existing = new HashMap<>();
        milestones.forEach(m -> existing.put(m.id(), m));
        Set<UUID> kept = new HashSet<>();
        for (MilestoneDraft d : drafts) {
            if (d.id() != null) {
                if (!existing.containsKey(d.id())) {
                    throw new MilestoneNotFoundException(d.id());
                }
                if (!kept.add(d.id())) {
                    throw new InvalidMilestoneOrderException();
                }
            }
        }

        ChallengeChanges changes = new ChallengeChanges();
        for (Milestone m : milestones) {
            if (!kept.contains(m.id())) {
                changes.revokeXp(m.xpAwarded());
            }
        }

        List<Milestone> result = new ArrayList<>();
        for (int i = 0; i < drafts.size(); i++) {
            MilestoneDraft d = drafts.get(i);
            UUID subject = d.subjectId() != null ? d.subjectId() : this.subjectId;
            int n = d.conditionN() == null ? 1 : d.conditionN();
            Milestone m;
            if (d.id() != null) {
                m = existing.get(d.id());
                m.redefine(d.title(), weights[i], d.difficulty(), subject, d.noteId(), d.fileId(), d.link(),
                        d.condition(), n);
                m.moveTo(i + 1);
            } else {
                m = new Milestone(UUID.randomUUID(), d.title(), weights[i], i + 1, 0, false, MilestoneStatus.AVAILABLE,
                        List.of(), d.condition(), n, subject, d.difficulty(), d.link(), 0, d.noteId(), d.fileId());
            }
            result.add(m);
        }
        for (int i = 0; i < drafts.size(); i++) {
            List<UUID> deps = drafts.get(i).dependsOn().stream().map(idx -> result.get(idx).id()).toList();
            result.get(i).changeDependencies(deps);
        }
        this.milestones = result;

        if (!milestones.isEmpty() && xpAwarded > 0) {
            // Con tareas, el XP lo dan las tareas: se retira el XP propio del reto.
            changes.revokeXp(xpAwarded);
            xpAwarded = 0;
        }
        refreshStates(changes);
        syncCompletionWithMilestones(changes);
        return changes;
    }

    /** Cambia el orden de las tareas. Debe incluir cada tarea exactamente una vez. */
    public void reorderMilestones(List<UUID> orderedIds) {
        Set<UUID> current = new HashSet<>();
        milestones.forEach(m -> current.add(m.id()));
        if (orderedIds.size() != milestones.size() || !current.equals(new HashSet<>(orderedIds))) {
            throw new InvalidMilestoneOrderException();
        }
        Map<UUID, Milestone> byId = new HashMap<>();
        milestones.forEach(m -> byId.put(m.id(), m));
        List<Milestone> result = new ArrayList<>();
        for (int i = 0; i < orderedIds.size(); i++) {
            Milestone m = byId.get(orderedIds.get(i));
            m.moveTo(i + 1);
            result.add(m);
        }
        this.milestones = result;
    }

    // ---------------------------------------------------------------- completar

    /** Completa el reto (y todas sus tareas pendientes). Idempotente. */
    public ChallengeChanges complete(LocalDate today) {
        ChallengeChanges changes = new ChallengeChanges();
        if (completed) {
            return changes;
        }
        if (milestones.isEmpty()) {
            completed = true;
            if (xpAwarded == 0 && !belowSessionTarget()) {
                xpAwarded = difficulty.xp();
                changes.addXp(xpAwarded);
            }
            changes.completedTransition(true);
            changes.linkChanged(link, true);
        } else {
            for (Milestone m : milestones) {
                if (!m.completed()) {
                    changes.addXp(m.markCompleted(remainingXp()));
                    changes.linkChanged(m.link(), true);
                }
            }
            refreshStates(changes);
            syncCompletionWithMilestones(changes);
        }
        touchStreak(today);
        return changes;
    }

    /** Descompleta el reto y todas sus tareas, restando exactamente el XP otorgado. Idempotente. */
    public ChallengeChanges uncomplete() {
        ChallengeChanges changes = new ChallengeChanges();
        if (!completed) {
            return changes;
        }
        if (milestones.isEmpty()) {
            changes.revokeXp(xpAwarded);
            xpAwarded = 0;
            completed = false;
            changes.completedTransition(false);
            changes.linkChanged(link, false);
            return changes;
        }
        for (Milestone m : milestones) {
            if (m.completed()) {
                changes.revokeXp(m.markUncompleted(0));
                changes.linkChanged(m.link(), false);
            } else {
                m.changeProgress(0);
            }
        }
        refreshStates(changes);
        syncCompletionWithMilestones(changes);
        return changes;
    }

    /**
     * Completa una tarea. Idempotente. Con {@code force} (sincronización desde el planificador)
     * se ignora el bloqueo por dependencias: el hecho externo ya ha ocurrido.
     */
    public ChallengeChanges completeMilestone(UUID milestoneId, LocalDate today, boolean force) {
        Milestone m = milestone(milestoneId);
        ChallengeChanges changes = new ChallengeChanges();
        if (m.completed()) {
            return changes;
        }
        if (m.isLocked() && !force) {
            throw new MilestoneLockedException(milestoneId);
        }
        changes.addXp(m.markCompleted(remainingXp()));
        changes.linkChanged(m.link(), true);
        refreshStates(changes);
        syncCompletionWithMilestones(changes);
        touchStreak(today);
        return changes;
    }

    /** Descompleta una tarea restando su XP. Idempotente. */
    public ChallengeChanges uncompleteMilestone(UUID milestoneId) {
        Milestone m = milestone(milestoneId);
        ChallengeChanges changes = new ChallengeChanges();
        if (!m.completed()) {
            return changes;
        }
        changes.revokeXp(m.markUncompleted(0));
        changes.linkChanged(m.link(), false);
        refreshStates(changes);
        syncCompletionWithMilestones(changes);
        return changes;
    }

    /**
     * Fija el progreso de una tarea a partir de sus bloques de estudio completados (regla de
     * {@code fn_actualizar_progreso_hito}): al 100 % se completa; por debajo, si estaba completada,
     * se descompleta. Idempotente.
     */
    public ChallengeChanges applyStudyBlockProgress(UUID milestoneId, double percent, LocalDate today) {
        double value = Math.max(0, Math.min(100, percent));
        if (value >= 100) {
            return completeMilestone(milestoneId, today, true);
        }
        Milestone m = milestone(milestoneId);
        ChallengeChanges changes = new ChallengeChanges();
        if (m.completed()) {
            changes.revokeXp(m.markUncompleted(value));
            changes.linkChanged(m.link(), false);
        } else if (Double.compare(m.progress(), value) == 0) {
            return changes;
        } else {
            m.changeProgress(value);
        }
        refreshStates(changes);
        syncCompletionWithMilestones(changes);
        return changes;
    }

    /**
     * Registra progreso manual. En un reto con tareas se indica la tarea; sin tareas se acumula en
     * el reto. Al llegar al 100 % se completa. Cuenta como actividad para la racha del reto.
     */
    public ChallengeChanges addProgress(UUID milestoneId, double amount, LocalDate today) {
        Guard.range(amount, "amount", 0.01, 100.0);
        if (milestoneId == null) {
            if (!milestones.isEmpty()) {
                throw new ProgressMilestoneRequiredException();
            }
            if (completed) {
                throw new ChallengeAlreadyCompletedException(id);
            }
            manualProgress = Math.min(100, manualProgress + amount);
            touchStreak(today);
            return manualProgress >= 100 ? complete(today) : new ChallengeChanges();
        }
        Milestone m = milestone(milestoneId);
        if (m.completed()) {
            throw new MilestoneAlreadyCompletedException(milestoneId);
        }
        if (m.isLocked()) {
            throw new MilestoneLockedException(milestoneId);
        }
        double next = Math.min(100, m.progress() + amount);
        if (next >= 100) {
            return completeMilestone(milestoneId, today, false);
        }
        ChallengeChanges changes = new ChallengeChanges();
        m.changeProgress(next);
        refreshStates(changes);
        touchStreak(today);
        return changes;
    }

    /**
     * Fija las sesiones de entrenamiento completadas dentro del periodo del reto (recuento hecho desde
     * cero por quien llama, así que repetirlo no cambia nada). Al alcanzar el objetivo se completa
     * con el XP de su dificultad; si un desmarcado lo deja por debajo y lo había completado el
     * recuento, se descompleta restando ese XP. Una compleción manual por debajo del objetivo no se
     * deshace. Solo aplica a {@link #tracksTrainingSessions()}.
     */
    public ChallengeChanges applyTrainingSessions(int completedSessions, LocalDate today) {
        ChallengeChanges changes = new ChallengeChanges();
        if (!tracksTrainingSessions()) {
            return changes;
        }
        int previous = sessionsCompleted;
        sessionsCompleted = Math.max(0, completedSessions);
        if (sessionsCompleted > previous) {
            touchStreak(today);
        }
        boolean reached = sessionsCompleted >= sessionTarget;
        if (reached && !completed) {
            changes.merge(complete(today));
        } else if (reached && xpAwarded == 0) {
            // Se marcó a mano antes de tiempo (sin XP): las sesiones ya lo justifican.
            xpAwarded = difficulty.xp();
            changes.addXp(xpAwarded);
        } else if (!reached && completed && previous >= sessionTarget) {
            changes.merge(uncomplete());
        }
        return changes;
    }

    /** Reto de sesiones que aún no las tiene: completarlo a mano no da XP. */
    private boolean belowSessionTarget() {
        return tracksTrainingSessions() && sessionsCompleted < sessionTarget;
    }

    /** XP que aún puede dar el reto antes de llegar a {@link #MAX_XP}. */
    private int remainingXp() {
        return Math.max(0, MAX_XP - totalXpAwarded());
    }

    /** ¿Avanza con los entrenamientos? Reto de fitness sin tareas y con objetivo de sesiones. */
    public boolean tracksTrainingSessions() {
        return type == ChallengeType.FITNESS && sessionTarget != null && milestones.isEmpty();
    }

    /** Anula todo el XP del reto y sus tareas (al borrarlo). Devuelve la cantidad a restar. */
    public int totalXpAwarded() {
        return xpAwarded + milestones.stream().mapToInt(Milestone::xpAwarded).sum();
    }

    /** Copia del reto para otro usuario: privada, sin progreso, sin asignatura, vínculos ni adjuntos. */
    public Challenge cloneFor(UUID newId, UUID newOwnerId, String ownerName, Instant now) {
        Instant end = endAt.isAfter(now) ? endAt : now.plus(Duration.between(startAt, endAt));
        Challenge copy = builder().id(newId).ownerId(newOwnerId).title(title).type(type).goal(goal)
                .visibility(Visibility.PRIVATE).difficulty(difficulty).startAt(now).endAt(end)
                .sessionTarget(sessionTarget).originId(id).originOwnerId(ownerId).originOwnerName(ownerName)
                .createdAt(now).updatedAt(now).build();
        if (!milestones.isEmpty()) {
            Map<UUID, Integer> index = new HashMap<>();
            for (int i = 0; i < milestones.size(); i++) {
                index.put(milestones.get(i).id(), i);
            }
            List<MilestoneDraft> drafts = milestones.stream().map(m -> new MilestoneDraft(null, m.title(), m.weight(),
                    m.difficulty(), null, null, null, null,
                    m.dependencies().stream().map(index::get).filter(Objects::nonNull).toList(),
                    m.condition(), m.conditionN())).toList();
            copy.replaceMilestones(drafts);
        }
        return copy;
    }

    // ---------------------------------------------------------------- consultas

    /**
     * Progreso 0-100: suma ponderada de las tareas o, sin tareas, el progreso manual acumulado (o el
     * de las sesiones de entrenamiento, si es mayor, en un reto que las cuenta).
     */
    public double progress() {
        if (milestones.isEmpty()) {
            if (completed) {
                return 100.0;
            }
            double sessions = tracksTrainingSessions()
                    ? Math.round(sessionsCompleted * 10000.0 / sessionTarget) / 100.0 : 0;
            return Math.min(100.0, Math.max(manualProgress, sessions));
        }
        double sum = milestones.stream().mapToDouble(Milestone::weightedProgress).sum();
        return Math.min(100.0, Math.round(sum * 100.0) / 100.0);
    }

    /** Solo se avanza un reto dentro de plazo: vencido, ni se completa ni suma progreso. */
    public void requireOpen(Instant now) {
        if (status(now) == ChallengeStatus.EXPIRED) {
            throw new ChallengeExpiredException(id);
        }
    }

    /** Un progreso registrado debe caer entre el inicio del reto y ahora (ni antes ni en el futuro). */
    public boolean acceptsProgressAt(Instant recordedAt, Instant now) {
        return !recordedAt.isAfter(now) && (startAt == null || !recordedAt.isBefore(startAt));
    }

    public ChallengeStatus status(Instant now) {
        return statusOf(completed, endAt, now);
    }

    /**
     * ¿Puede verlo otro usuario? Nunca si es privado o si su autor está eliminado o silenciado;
     * público: sí; de amigos: solo con amistad aceptada. El listado paginado de la comunidad aplica
     * la misma regla en SQL ({@code ChallengeAudiencePersistenceAdapter}).
     */
    public boolean isVisibleTo(OwnerAudience audience) {
        if (visibility == Visibility.PRIVATE || !audience.ownerActive() || audience.ownerShadowbanned()) {
            return false;
        }
        return visibility == Visibility.PUBLIC || audience.friends();
    }

    /** Regla única del estado: completado; si no, vencido cuando su fecha de fin ya pasó; si no, activo. */
    public static ChallengeStatus statusOf(boolean completed, Instant endAt, Instant now) {
        if (completed) {
            return ChallengeStatus.COMPLETED;
        }
        return endAt.isBefore(now) ? ChallengeStatus.EXPIRED : ChallengeStatus.ACTIVE;
    }

    public boolean hasDependencies() {
        return milestones.stream().anyMatch(m -> !m.dependencies().isEmpty());
    }

    public Milestone milestone(UUID milestoneId) {
        return milestones.stream().filter(m -> m.id().equals(milestoneId)).findFirst()
                .orElseThrow(() -> new MilestoneNotFoundException(milestoneId));
    }

    public boolean hasMilestone(UUID milestoneId) {
        return milestones.stream().anyMatch(m -> m.id().equals(milestoneId));
    }

    public boolean isOwnedBy(UUID userId) {
        return ownerId.equals(userId);
    }

    // ---------------------------------------------------------------- reglas internas

    /** Recalcula el estado de las tareas no completadas según sus dependencias. */
    private void refreshStates(ChallengeChanges changes) {
        Map<UUID, Milestone> byId = new HashMap<>();
        milestones.forEach(m -> byId.put(m.id(), m));
        for (Milestone m : milestones) {
            int done = (int) m.dependencies().stream().map(byId::get)
                    .filter(dep -> dep != null && dep.completed()).count();
            boolean satisfied = m.condition().isSatisfied(done, m.dependencies().size(), m.conditionN());
            if (m.refreshStatus(satisfied)) {
                changes.unlocked(m.id());
            }
        }
    }

    /** Con tareas, el reto está completado si y solo si lo están todas. */
    private void syncCompletionWithMilestones(ChallengeChanges changes) {
        if (milestones.isEmpty()) {
            return;
        }
        boolean all = milestones.stream().allMatch(Milestone::completed);
        if (all != completed) {
            completed = all;
            changes.completedTransition(all);
            changes.linkChanged(link, all);
        }
    }

    /** Racha del reto: días consecutivos con actividad registrada. */
    private void touchStreak(LocalDate today) {
        if (today == null || today.equals(lastActiveDay)) {
            return;
        }
        currentStreak = today.minusDays(1).equals(lastActiveDay) ? currentStreak + 1 : 1;
        bestStreak = Math.max(bestStreak, currentStreak);
        lastActiveDay = today;
    }

    private static double[] resolveWeights(List<MilestoneDraft> drafts) {
        int n = drafts.size();
        double[] weights = new double[n];
        if (n == 0) {
            return weights;
        }
        long given = drafts.stream().filter(d -> d.weight() != null).count();
        if (given == 0) {
            double base = Math.floor(10000.0 / n) / 100.0;
            for (int i = 0; i < n; i++) {
                weights[i] = base;
            }
            weights[n - 1] = Math.round((100.0 - base * (n - 1)) * 100.0) / 100.0;
            return weights;
        }
        if (given != n) {
            throw new InvalidMilestoneWeightsException("weights must be given for every milestone or for none");
        }
        double sum = 0;
        for (int i = 0; i < n; i++) {
            double w = drafts.get(i).weight();
            if (!(w > 0) || w > 100) {
                throw new InvalidMilestoneWeightsException("each weight must be greater than 0 and at most 100");
            }
            weights[i] = w;
            sum += w;
        }
        if (Math.abs(sum - 100.0) > WEIGHT_TOLERANCE) {
            throw new InvalidMilestoneWeightsException("weights must add up to 100 (current: " + sum + ")");
        }
        return weights;
    }

    private static void validateDependencies(List<MilestoneDraft> drafts) {
        int n = drafts.size();
        List<List<Integer>> graph = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            MilestoneDraft d = drafts.get(i);
            Set<Integer> seen = new HashSet<>();
            for (Integer dep : d.dependsOn()) {
                if (dep == null || dep < 0 || dep >= n) {
                    throw new InvalidMilestoneDependencyException("milestone " + i + " depends on a missing milestone");
                }
                if (dep == i) {
                    throw new InvalidMilestoneDependencyException("milestone " + i + " cannot depend on itself");
                }
                if (!seen.add(dep)) {
                    throw new InvalidMilestoneDependencyException("milestone " + i + " has duplicated dependencies");
                }
            }
            if (d.condition() == UnlockCondition.X_OF_Y) {
                int required = d.conditionN() == null ? 1 : d.conditionN();
                if (required < 1 || required > d.dependsOn().size()) {
                    throw new InvalidMilestoneDependencyException(
                            "X_OF_Y requires between 1 and the number of dependencies of milestone " + i);
                }
            }
            graph.add(d.dependsOn());
        }
        int[] color = new int[n];
        for (int i = 0; i < n; i++) {
            if (color[i] == 0 && hasCycle(i, graph, color)) {
                throw new InvalidMilestoneDependencyException("milestone dependencies cannot form a cycle");
            }
        }
    }

    private static boolean hasCycle(int node, List<List<Integer>> graph, int[] color) {
        color[node] = 1;
        for (int next : graph.get(node)) {
            if (color[next] == 1 || (color[next] == 0 && hasCycle(next, graph, color))) {
                return true;
            }
        }
        color[node] = 2;
        return false;
    }

    // ---------------------------------------------------------------- getters

    public UUID id() { return id; }
    public UUID ownerId() { return ownerId; }
    public String title() { return title; }
    public ChallengeType type() { return type; }
    public String goal() { return goal; }
    public Visibility visibility() { return visibility; }
    public boolean completed() { return completed; }
    public Instant startAt() { return startAt; }
    public Instant endAt() { return endAt; }
    public Instant createdAt() { return createdAt; }
    public Instant updatedAt() { return updatedAt; }
    public int currentStreak() { return currentStreak; }
    public int bestStreak() { return bestStreak; }
    public LocalDate lastActiveDay() { return lastActiveDay; }
    public UUID subjectId() { return subjectId; }
    public Difficulty difficulty() { return difficulty; }
    public ChallengeLink link() { return link; }
    public int xpAwarded() { return xpAwarded; }
    public UUID originId() { return originId; }
    public UUID originOwnerId() { return originOwnerId; }
    public String originOwnerName() { return originOwnerName; }
    public double manualProgress() { return manualProgress; }
    public Integer sessionTarget() { return sessionTarget; }
    public int sessionsCompleted() { return sessionsCompleted; }
    public List<Milestone> milestones() { return List.copyOf(milestones); }

    /** Constructor fluido para crear o reconstruir el reto. */
    public static final class Builder {
        private UUID id;
        private UUID ownerId;
        private String title;
        private ChallengeType type;
        private String goal;
        private Visibility visibility;
        private boolean completed;
        private Instant startAt;
        private Instant endAt;
        private Instant createdAt;
        private Instant updatedAt;
        private int currentStreak;
        private int bestStreak;
        private LocalDate lastActiveDay;
        private UUID subjectId;
        private Difficulty difficulty;
        private ChallengeLink link;
        private int xpAwarded;
        private UUID originId;
        private UUID originOwnerId;
        private String originOwnerName;
        private double manualProgress;
        private Integer sessionTarget;
        private int sessionsCompleted;
        private List<Milestone> milestones = List.of();

        public Builder id(UUID v) { this.id = v; return this; }
        public Builder ownerId(UUID v) { this.ownerId = v; return this; }
        public Builder title(String v) { this.title = v; return this; }
        public Builder type(ChallengeType v) { this.type = v; return this; }
        public Builder goal(String v) { this.goal = v; return this; }
        public Builder visibility(Visibility v) { this.visibility = v; return this; }
        public Builder completed(boolean v) { this.completed = v; return this; }
        public Builder startAt(Instant v) { this.startAt = v; return this; }
        public Builder endAt(Instant v) { this.endAt = v; return this; }
        public Builder createdAt(Instant v) { this.createdAt = v; return this; }
        public Builder updatedAt(Instant v) { this.updatedAt = v; return this; }
        public Builder currentStreak(int v) { this.currentStreak = v; return this; }
        public Builder bestStreak(int v) { this.bestStreak = v; return this; }
        public Builder lastActiveDay(LocalDate v) { this.lastActiveDay = v; return this; }
        public Builder subjectId(UUID v) { this.subjectId = v; return this; }
        public Builder difficulty(Difficulty v) { this.difficulty = v; return this; }
        public Builder link(ChallengeLink v) { this.link = v; return this; }
        public Builder xpAwarded(int v) { this.xpAwarded = v; return this; }
        public Builder originId(UUID v) { this.originId = v; return this; }
        public Builder originOwnerId(UUID v) { this.originOwnerId = v; return this; }
        public Builder originOwnerName(String v) { this.originOwnerName = v; return this; }
        public Builder manualProgress(double v) { this.manualProgress = v; return this; }
        public Builder sessionTarget(Integer v) { this.sessionTarget = v; return this; }
        public Builder sessionsCompleted(int v) { this.sessionsCompleted = v; return this; }
        public Builder milestones(List<Milestone> v) { this.milestones = List.copyOf(v); return this; }

        public Challenge build() {
            return new Challenge(this);
        }
    }
}
