package com.synaptixfit.domain.model.challenge;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.challenge.ChallengeAlreadyCompletedException;
import com.synaptixfit.domain.exception.challenge.ChallengeExpiredException;
import com.synaptixfit.domain.exception.challenge.ChallengeLinkOutsidePeriodException;
import com.synaptixfit.domain.exception.challenge.ChallengeLinkedException;
import com.synaptixfit.domain.exception.challenge.ChallengeNotStartedException;
import com.synaptixfit.domain.exception.challenge.InvalidChallengeDatesException;
import com.synaptixfit.domain.exception.challenge.InvalidMilestoneDependencyException;
import com.synaptixfit.domain.exception.challenge.InvalidMilestoneOrderException;
import com.synaptixfit.domain.exception.challenge.MilestoneAlreadyCompletedException;
import com.synaptixfit.domain.exception.challenge.MilestoneLinkedException;
import com.synaptixfit.domain.exception.challenge.MilestoneLockedException;
import com.synaptixfit.domain.exception.challenge.MilestoneNotFoundException;
import com.synaptixfit.domain.exception.challenge.ProgressMilestoneRequiredException;
import com.synaptixfit.domain.exception.challenge.TooManyMilestonesException;
import com.synaptixfit.domain.model.shared.AuthorAudience;
import com.synaptixfit.domain.model.shared.EffectiveVisibility;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Reto con sus tareas opcionales (agregado). Reglas principales:
 * <ul>
 *   <li>Periodo: solo se actúa sobre un reto entre su inicio y su fin ({@link #requireOpen}). Antes de
 *       empezar está «por empezar» (UPCOMING) y, después del fin, vencido: ni se completa ni se desmarca,
 *       así que no se pierde XP que luego no se podría recuperar (ADR 0028).</li>
 *   <li>Sin tareas, completar el reto otorga el XP de su dificultad. Con tareas, el XP lo da cada tarea y
 *       el reto se completa solo cuando todas lo están (progreso ponderado 100 %).</li>
 *   <li>Anti-farmeo: {@code xpAwarded} guarda el XP exacto del estado completado actual y se resta tal
 *       cual al descompletar o borrar. Un reto da como mucho {@value #MAX_XP} XP entre todas sus tareas, y
 *       un reto de sesiones marcado a mano antes de llegar al objetivo no da XP hasta que las sesiones lo
 *       alcanzan.</li>
 *   <li>Como máximo {@value #MAX_MILESTONES} tareas. Su peso en el progreso no se elige: es la parte de su
 *       dificultad en la suma de dificultades (una sola medida de importancia, ADR 0028).</li>
 *   <li>Una sola fuente de verdad: una tarea vinculada a una entrega o examen, o con bloques de estudio
 *       asignados, solo la completa ese elemento; un reto sin tareas vinculado, igual. Nada de lo que se
 *       haga en el reto cambia la entrega (ADR 0028).</li>
 *   <li>Las dependencias (AND / OR / X_OF_Y) desbloquean tareas automáticamente; una tarea bloqueada no
 *       se puede completar a mano.</li>
 *   <li>Un reto de fitness sin tareas con {@code sessionTarget} avanza con las sesiones de entrenamiento
 *       completadas en su periodo, recontadas desde cero (ADR 0009).</li>
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
    /** Foto de las entregas y exámenes vinculados (por id), cargada con el reto. Solo lectura. */
    private final Map<UUID, LinkedDeadline> linkedDeadlines;
    /** Bloques de estudio asignados a cada tarea (por id de tarea), cargados con el reto. Solo lectura. */
    private final Map<UUID, StudyBlockProgress> studyBlocks;

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
        this.manualProgress = Math.max(0, Math.min(100, b.manualProgress));
        this.sessionsCompleted = Math.max(0, b.sessionsCompleted);
        this.linkedDeadlines = Map.copyOf(b.linkedDeadlines);
        this.studyBlocks = Map.copyOf(b.studyBlocks);
        applyDetails(new ChallengeDetails(b.title, b.type, b.goal, b.visibility, b.difficulty, b.startAt, b.endAt,
                b.subjectId, b.link, b.sessionTarget));
        this.milestones = new ArrayList<>(b.milestones);
        this.milestones.sort(Comparator.comparingInt(Milestone::order));
        rebalanceWeights();
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
     * XP; las que desaparecen restan el XP que habían dado. Los pesos se derivan de la dificultad.
     */
    public ChallengeChanges replaceMilestones(List<MilestoneDraft> drafts) {
        if (drafts.size() > MAX_MILESTONES) {
            throw new TooManyMilestonesException(MAX_MILESTONES);
        }
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
                m.redefine(d.title(), d.difficulty(), subject, d.noteId(), d.fileId(), d.link(), d.condition(), n);
                m.moveTo(i + 1);
            } else {
                // Peso provisional: rebalanceWeights() lo fija enseguida a partir de la dificultad.
                m = new Milestone(UUID.randomUUID(), d.title(), 100.0, i + 1, 0, false, MilestoneStatus.AVAILABLE,
                        List.of(), d.condition(), n, subject, d.difficulty(), d.link(), 0, d.noteId(), d.fileId());
            }
            result.add(m);
        }
        for (int i = 0; i < drafts.size(); i++) {
            List<UUID> deps = drafts.get(i).dependsOn().stream().map(idx -> result.get(idx).id()).toList();
            result.get(i).changeDependencies(deps);
        }
        this.milestones = result;
        rebalanceWeights();

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

    // ---------------------------------------------------------------- acciones a mano

    /**
     * Completa el reto a mano. Sin tareas, salvo que lo complete su entrega vinculada. Con tareas, completa
     * las que se pueden marcar a mano respetando las dependencias (nunca las vinculadas ni las bloqueadas);
     * el reto queda completado si con ello lo están todas. Idempotente.
     */
    public ChallengeChanges complete(LocalDate today) {
        ChallengeChanges changes = new ChallengeChanges();
        if (completed) {
            return changes;
        }
        if (milestones.isEmpty()) {
            if (isCompletedByLink()) {
                throw new ChallengeLinkedException(id);
            }
            return markCompleted(today);
        }
        boolean any = false;
        boolean progressed = true;
        while (progressed) {
            progressed = false;
            for (Milestone m : milestones) {
                if (!m.completed() && !m.isLocked() && !isCompletedByLink(m)) {
                    changes.addXp(m.markCompleted(remainingXp()));
                    progressed = true;
                    any = true;
                }
            }
            refreshStates(changes);
        }
        syncCompletionWithMilestones(changes);
        // Sin ninguna tarea marcada no hubo actividad: la racha no sube.
        if (any) {
            touchStreak(today);
        }
        return changes;
    }

    /**
     * Descompleta el reto a mano restando exactamente el XP otorgado. Sin tareas, su progreso manual
     * vuelve a 0 (si no, seguiría mostrando 100 % estando activo). Con tareas, solo se desmarcan las que
     * se marcaron a mano: las vinculadas siguen el estado de su entrega o sus bloques. Idempotente.
     */
    public ChallengeChanges uncomplete() {
        if (completed && isCompletedByLink()) {
            throw new ChallengeLinkedException(id);
        }
        return markUncompleted(false);
    }

    /** Completa a mano una tarea: no si está bloqueada ni si la completa su vínculo. Idempotente. */
    public ChallengeChanges completeMilestone(UUID milestoneId, LocalDate today) {
        Milestone m = milestone(milestoneId);
        if (m.completed()) {
            return new ChallengeChanges();
        }
        if (isCompletedByLink(m)) {
            throw new MilestoneLinkedException(milestoneId);
        }
        if (m.isLocked()) {
            throw new MilestoneLockedException(milestoneId);
        }
        return markMilestoneCompleted(m, today);
    }

    /** Descompleta a mano una tarea restando su XP; no si la completó su vínculo. Idempotente. */
    public ChallengeChanges uncompleteMilestone(UUID milestoneId) {
        Milestone m = milestone(milestoneId);
        if (!m.completed()) {
            return new ChallengeChanges();
        }
        if (isCompletedByLink(m)) {
            throw new MilestoneLinkedException(milestoneId);
        }
        return markMilestoneUncompleted(m, 0);
    }

    /**
     * Fija el progreso manual («¿cuánto llevas?», valor absoluto 0-100). En un reto con tareas se indica la
     * tarea; sin tareas, el del reto. Al llegar al 100 % se completa. Si sube, cuenta como actividad de la
     * racha; bajar es una corrección y no cuenta.
     */
    public ChallengeChanges setProgress(UUID milestoneId, double value, LocalDate today) {
        Guard.range(value, "value", 0.0, 100.0);
        if (milestoneId == null) {
            requireManualProgressOnChallenge();
            double previous = manualProgress;
            manualProgress = value;
            if (value > previous) {
                touchStreak(today);
            }
            return manualProgress >= 100 ? markCompleted(today) : new ChallengeChanges();
        }
        Milestone m = manualMilestone(milestoneId);
        if (value >= 100) {
            return completeMilestone(milestoneId, today);
        }
        double previous = m.progress();
        ChallengeChanges changes = new ChallengeChanges();
        m.changeProgress(value);
        refreshStates(changes);
        if (value > previous) {
            touchStreak(today);
        }
        return changes;
    }

    /**
     * Suma progreso manual (API anterior: cantidad que se añade a la actual, con tope 100). Mismas reglas
     * que {@link #setProgress}; se conserva para los clientes que aún la usan.
     */
    public ChallengeChanges addProgress(UUID milestoneId, double amount, LocalDate today) {
        Guard.range(amount, "amount", 0.01, 100.0);
        double current = milestoneId == null ? manualProgress : milestone(milestoneId).progress();
        return setProgress(milestoneId, Math.min(100, current + amount), today);
    }

    private void requireManualProgressOnChallenge() {
        if (!milestones.isEmpty()) {
            throw new ProgressMilestoneRequiredException();
        }
        if (completed) {
            throw new ChallengeAlreadyCompletedException(id);
        }
        if (isCompletedByLink()) {
            throw new ChallengeLinkedException(id);
        }
    }

    private Milestone manualMilestone(UUID milestoneId) {
        Milestone m = milestone(milestoneId);
        if (m.completed()) {
            throw new MilestoneAlreadyCompletedException(milestoneId);
        }
        if (isCompletedByLink(m)) {
            throw new MilestoneLinkedException(milestoneId);
        }
        if (m.isLocked()) {
            throw new MilestoneLockedException(milestoneId);
        }
        return m;
    }

    // ---------------------------------------------------------------- sincronización con la fuente

    /**
     * La entrega o examen {@code entityId} ha cambiado de estado: se aplican las tareas vinculadas y, si el
     * reto no tiene tareas y está vinculado, el propio reto. Con tareas, el vínculo del reto es solo una
     * referencia (lo completan sus tareas). Ignora el bloqueo por dependencias: el hecho ya ha ocurrido.
     * Idempotente.
     */
    public ChallengeChanges applyDeadline(UUID entityId, boolean deadlineCompleted, LocalDate today) {
        ChallengeChanges changes = new ChallengeChanges();
        if (milestones.isEmpty()) {
            if (link != null && link.entityId().equals(entityId) && deadlineCompleted != completed) {
                changes.merge(deadlineCompleted ? markCompleted(today) : markUncompleted(true));
            }
            return changes;
        }
        for (Milestone m : milestones) {
            if (m.link() != null && m.link().entityId().equals(entityId) && m.completed() != deadlineCompleted) {
                changes.merge(deadlineCompleted ? markMilestoneCompleted(m, today) : markMilestoneUncompleted(m, 0));
            }
        }
        return changes;
    }

    /**
     * Fija el progreso de una tarea a partir de sus bloques de estudio completados: al 100 % se completa;
     * por debajo, si estaba completada, se descompleta. Si la tarea está vinculada a una entrega o examen,
     * manda la entrega y los bloques son solo tiempo de estudio. Idempotente.
     */
    public ChallengeChanges applyStudyBlockProgress(UUID milestoneId, double percent, LocalDate today) {
        Milestone m = milestone(milestoneId);
        ChallengeChanges changes = new ChallengeChanges();
        if (linkedDeadline(m.link()).isPresent()) {
            return changes;
        }
        double value = Math.max(0, Math.min(100, percent));
        if (value >= 100) {
            return m.completed() ? changes : markMilestoneCompleted(m, today);
        }
        if (m.completed()) {
            return markMilestoneUncompleted(m, value);
        }
        if (Double.compare(m.progress(), value) != 0) {
            m.changeProgress(value);
            refreshStates(changes);
        }
        return changes;
    }

    /**
     * Sincronización inicial con las fuentes ya cargadas (entregas vinculadas y bloques de cada tarea): al
     * crear, editar o ampliar un reto, lo vinculado manda. Así una entrega ya hecha deja la tarea completada
     * al vincularla, y ampliar el plazo recupera lo que pasó mientras el reto estaba vencido.
     */
    public ChallengeChanges syncWithLinks(LocalDate today) {
        ChallengeChanges changes = new ChallengeChanges();
        if (milestones.isEmpty()) {
            if (link != null) {
                linkedDeadline(link).ifPresent(d -> changes.merge(applyDeadline(link.entityId(), d.completed(), today)));
            }
            return changes;
        }
        for (Milestone m : List.copyOf(milestones)) {
            Optional<LinkedDeadline> deadline = linkedDeadline(m.link());
            if (deadline.isPresent()) {
                changes.merge(applyDeadline(m.link().entityId(), deadline.get().completed(), today));
            } else {
                studyBlocksOf(m.id()).percent()
                        .ifPresent(p -> changes.merge(applyStudyBlockProgress(m.id(), p, today)));
            }
        }
        return changes;
    }

    /**
     * Cada entrega o examen vinculado (del reto o de una tarea) debe vencer dentro del periodo del reto
     * (por días en {@code zone}): si vence después, el reto habría terminado y la tarea no podría
     * completarse nunca. Solo se comprueban {@code entityIds} (los vínculos nuevos o, si cambian las
     * fechas, todos), para no bloquear la edición de retos antiguos.
     */
    public void requireLinksWithinPeriod(Collection<UUID> entityIds, ZoneId zone) {
        LocalDate first = LocalDate.ofInstant(startAt, zone);
        LocalDate last = LocalDate.ofInstant(endAt, zone);
        for (ChallengeLink l : allLinks()) {
            if (!entityIds.contains(l.entityId())) {
                continue;
            }
            Optional<LinkedDeadline> deadline = linkedDeadline(l);
            // Un día de rutina no tiene fecha límite: no hay periodo que comprobar.
            if (deadline.isPresent() && deadline.get().dueAt() != null) {
                LocalDate due = LocalDate.ofInstant(deadline.get().dueAt(), zone);
                if (due.isBefore(first) || due.isAfter(last)) {
                    throw new ChallengeLinkOutsidePeriodException(l.entityId());
                }
            }
        }
    }

    /** ¿Tiene algo que lo complete desde fuera (entregas vinculadas o bloques asignados a sus tareas)? */
    public boolean hasLinkedSources() {
        return !allLinks().isEmpty() || studyBlocks.values().stream().anyMatch(b -> b.total() > 0);
    }

    /** Vínculos del reto y de sus tareas. */
    public List<ChallengeLink> allLinks() {
        List<ChallengeLink> links = new ArrayList<>();
        if (link != null) {
            links.add(link);
        }
        milestones.stream().map(Milestone::link).filter(Objects::nonNull).forEach(links::add);
        return links;
    }

    // ---------------------------------------------------------------- sesiones de entrenamiento

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
            changes.merge(markCompleted(today));
        } else if (reached && xpAwarded == 0) {
            // Se marcó a mano antes de tiempo (sin XP): las sesiones ya lo justifican.
            xpAwarded = difficulty.xp();
            changes.addXp(xpAwarded);
        } else if (!reached && completed && previous >= sessionTarget) {
            changes.merge(markUncompleted(true));
        }
        return changes;
    }

    /** ¿Avanza con los entrenamientos? Reto de fitness sin tareas y con objetivo de sesiones. */
    public boolean tracksTrainingSessions() {
        return type == ChallengeType.FITNESS && sessionTarget != null && milestones.isEmpty();
    }

    // ---------------------------------------------------------------- XP

    /** Anula todo el XP del reto y sus tareas (al borrarlo). Devuelve la cantidad a restar. */
    public int totalXpAwarded() {
        return xpAwarded + milestones.stream().mapToInt(Milestone::xpAwarded).sum();
    }

    /**
     * XP real de cada tarea con el tope ya aplicado: la que dio si está completada y, si no, la que daría
     * haciéndolas en orden con lo que le queda al reto hasta {@value #MAX_XP}. Así no se promete «+70 XP» en
     * una tarea que, por el tope, daría 0.
     */
    public Map<UUID, Integer> milestoneXp() {
        Map<UUID, Integer> xp = new LinkedHashMap<>();
        int left = remainingXp();
        for (Milestone m : milestones) {
            if (m.completed()) {
                xp.put(m.id(), m.xpAwarded());
            } else {
                int give = Math.min(m.difficulty().xp(), left);
                left -= give;
                xp.put(m.id(), give);
            }
        }
        return xp;
    }

    /** XP total que puede dar el reto (la ya ganada más la que falta), con el tope aplicado. */
    public int xpReward() {
        if (milestones.isEmpty()) {
            return difficulty.xp();
        }
        return milestoneXp().values().stream().mapToInt(Integer::intValue).sum();
    }

    /** XP que aún puede dar el reto antes de llegar a {@link #MAX_XP}. */
    private int remainingXp() {
        return Math.max(0, MAX_XP - totalXpAwarded());
    }

    /** Reto de sesiones que aún no las tiene: completarlo a mano no da XP. */
    private boolean belowSessionTarget() {
        return tracksTrainingSessions() && sessionsCompleted < sessionTarget;
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
            List<MilestoneDraft> drafts = milestones.stream().map(m -> new MilestoneDraft(null, m.title(),
                    m.difficulty(), null, null, null, null,
                    m.dependencies().stream().map(index::get).filter(Objects::nonNull).toList(),
                    m.condition(), m.conditionN())).toList();
            copy.replaceMilestones(drafts);
        }
        return copy;
    }

    // ---------------------------------------------------------------- consultas

    /**
     * Progreso 0-100: suma ponderada de las tareas o, sin tareas, el progreso manual (o el de las
     * sesiones de entrenamiento, si es mayor, en un reto que las cuenta).
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

    /**
     * Regla única del periodo para actuar a mano (completar, desmarcar o registrar progreso): ni antes del
     * inicio ni después del fin, esté o no completado. Desmarcar un reto vencido lo dejaría sin poder
     * recompletarse y sin su XP por un toque.
     */
    public void requireOpen(Instant now) {
        requireNotEnded(now);
        if (startAt.isAfter(now)) {
            throw new ChallengeNotStartedException(id);
        }
    }

    /** Editar las tareas solo hasta el fin: antes de empezar sí se pueden preparar. */
    public void requireNotEnded(Instant now) {
        if (endAt.isBefore(now)) {
            throw new ChallengeExpiredException(id);
        }
    }

    /** Un progreso registrado debe caer entre el inicio del reto y ahora (ni antes ni en el futuro). */
    public boolean acceptsProgressAt(Instant recordedAt, Instant now) {
        return !recordedAt.isAfter(now) && (startAt == null || !recordedAt.isBefore(startAt));
    }

    public ChallengeStatus status(Instant now) {
        return statusOf(completed, startAt, endAt, now);
    }

    /**
     * Racha que se muestra hoy: la guardada solo vale si el último día con actividad fue hoy o ayer; si no,
     * la racha ya se rompió y es 0 (la guardada solo cambia cuando hay actividad).
     */
    public int currentStreakOn(LocalDate today) {
        return lastActiveDay != null && !lastActiveDay.isBefore(today.minusDays(1)) ? currentStreak : 0;
    }

    /**
     * ¿Puede verlo otro usuario? Regla única del contenido compartido ({@link EffectiveVisibility}): la
     * visibilidad más restrictiva entre la del reto y la del perfil del autor, nunca con un bloqueo ni si
     * el autor está eliminado o silenciado. El listado de la comunidad filtra con los mismos niveles.
     */
    public boolean isVisibleTo(AuthorAudience audience) {
        return EffectiveVisibility.canView(visibility, audience);
    }

    /**
     * Regla única del estado: completado; si no, vencido cuando su fecha de fin ya pasó; si no, por
     * empezar cuando su inicio aún no ha llegado; si no, activo.
     */
    public static ChallengeStatus statusOf(boolean completed, Instant startAt, Instant endAt, Instant now) {
        if (completed) {
            return ChallengeStatus.COMPLETED;
        }
        if (endAt.isBefore(now)) {
            return ChallengeStatus.EXPIRED;
        }
        return startAt != null && startAt.isAfter(now) ? ChallengeStatus.UPCOMING : ChallengeStatus.ACTIVE;
    }

    /**
     * ¿La completa su vínculo y no un toque? Una tarea vinculada a una entrega o examen que existe, o con
     * bloques de estudio asignados. Si la entrega se borró, la tarea vuelve a marcarse a mano (si no, se
     * quedaría sin salida). El cliente lo recibe en la respuesta para no repetir la regla.
     */
    public boolean isCompletedByLink(Milestone m) {
        return linkedDeadline(m.link()).isPresent() || studyBlocksOf(m.id()).total() > 0;
    }

    /**
     * ¿Lo completa su entrega vinculada? Solo un reto sin tareas (con tareas, lo completan ellas) y solo si
     * la entrega existe.
     */
    public boolean isCompletedByLink() {
        return milestones.isEmpty() && linkedDeadline(link).isPresent();
    }

    /**
     * ¿Se puede actuar a mano ahora? La misma regla que {@link #requireOpen}, sin lanzar: el cliente la
     * recibe para no ofrecer un toque que el servidor rechazaría.
     */
    public boolean isOpenAt(Instant now) {
        return !endAt.isBefore(now) && !startAt.isAfter(now);
    }

    public Optional<LinkedDeadline> linkedDeadline(ChallengeLink l) {
        return l == null ? Optional.empty() : Optional.ofNullable(linkedDeadlines.get(l.entityId()));
    }

    public StudyBlockProgress studyBlocksOf(UUID milestoneId) {
        return studyBlocks.getOrDefault(milestoneId, StudyBlockProgress.NONE);
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

    /** Núcleo de completar un reto sin tareas (a mano, por progreso, por sesiones o por su entrega). */
    private ChallengeChanges markCompleted(LocalDate today) {
        ChallengeChanges changes = new ChallengeChanges();
        if (completed) {
            return changes;
        }
        completed = true;
        manualProgress = 100;
        if (xpAwarded == 0 && !belowSessionTarget()) {
            xpAwarded = difficulty.xp();
            changes.addXp(xpAwarded);
        }
        changes.completedTransition(true);
        touchStreak(today);
        return changes;
    }

    /**
     * Núcleo de descompletar. Sin tareas, el progreso manual vuelve a 0. Con tareas, desmarca las marcadas
     * a mano y, si {@code includeLinked}, también las vinculadas.
     */
    private ChallengeChanges markUncompleted(boolean includeLinked) {
        ChallengeChanges changes = new ChallengeChanges();
        if (!completed) {
            return changes;
        }
        if (milestones.isEmpty()) {
            changes.revokeXp(xpAwarded);
            xpAwarded = 0;
            manualProgress = 0;
            completed = false;
            changes.completedTransition(false);
            return changes;
        }
        for (Milestone m : milestones) {
            if (includeLinked || !isCompletedByLink(m)) {
                if (m.completed()) {
                    changes.revokeXp(m.markUncompleted(0));
                } else {
                    m.changeProgress(0);
                }
            }
        }
        refreshStates(changes);
        syncCompletionWithMilestones(changes);
        return changes;
    }

    private ChallengeChanges markMilestoneCompleted(Milestone m, LocalDate today) {
        ChallengeChanges changes = new ChallengeChanges();
        changes.addXp(m.markCompleted(remainingXp()));
        refreshStates(changes);
        syncCompletionWithMilestones(changes);
        touchStreak(today);
        return changes;
    }

    private ChallengeChanges markMilestoneUncompleted(Milestone m, double newProgress) {
        ChallengeChanges changes = new ChallengeChanges();
        changes.revokeXp(m.markUncompleted(newProgress));
        refreshStates(changes);
        syncCompletionWithMilestones(changes);
        return changes;
    }

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

    /**
     * Peso de cada tarea = su XP de dificultad / suma de las de todas × 100 (redondeado a centésimas; la
     * última se queda el resto para sumar 100 exacto). Antes había pesos manuales que tenían que sumar 100
     * y no cambiaban la XP: dos medidas de la misma importancia. Ahora es una sola (ADR 0028).
     */
    private void rebalanceWeights() {
        int n = milestones.size();
        if (n == 0) {
            return;
        }
        double total = milestones.stream().mapToInt(m -> m.difficulty().xp()).sum();
        double assigned = 0;
        for (int i = 0; i < n; i++) {
            Milestone m = milestones.get(i);
            double w = i == n - 1
                    ? Math.round((100.0 - assigned) * 100.0) / 100.0
                    : Math.round(m.difficulty().xp() * 10000.0 / total) / 100.0;
            m.reweigh(Math.max(0.01, w));
            assigned += w;
        }
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
        private Map<UUID, LinkedDeadline> linkedDeadlines = Map.of();
        private Map<UUID, StudyBlockProgress> studyBlocks = Map.of();

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
        public Builder linkedDeadlines(Map<UUID, LinkedDeadline> v) { this.linkedDeadlines = v; return this; }
        public Builder studyBlocks(Map<UUID, StudyBlockProgress> v) { this.studyBlocks = v; return this; }

        public Challenge build() {
            return new Challenge(this);
        }
    }
}
