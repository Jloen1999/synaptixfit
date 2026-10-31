package com.synaptixfit.domain.model.challenge;

import com.synaptixfit.domain.exception.challenge.MilestoneAttachmentConflictException;
import com.synaptixfit.domain.model.shared.Guard;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * Tarea (hito) de un reto. Sus cambios de estado los dirige {@link Challenge}, que es quien
 * conoce las dependencias entre tareas y aplica el XP con anti-farmeo.
 *
 * <p>{@code xpAwarded} guarda el XP exacto otorgado por el estado completado actual: al
 * descompletar se resta exactamente esa cantidad.
 */
public final class Milestone {

    public static final int TITLE_MIN = 3;
    public static final int TITLE_MAX = 80;

    private final UUID id;
    private String title;
    private double weight;
    private int order;
    private double progress;
    private boolean completed;
    private MilestoneStatus status;
    private List<UUID> dependencies;
    private UnlockCondition condition;
    private int conditionN;
    private UUID subjectId;
    private Difficulty difficulty;
    private ChallengeLink link;
    private int xpAwarded;
    private UUID noteId;
    private UUID fileId;

    /** Reconstruye o crea una tarea comprobando sus invariantes. */
    public Milestone(UUID id, String title, double weight, int order, double progress, boolean completed,
                     MilestoneStatus status, List<UUID> dependencies, UnlockCondition condition, int conditionN,
                     UUID subjectId, Difficulty difficulty, ChallengeLink link, int xpAwarded,
                     UUID noteId, UUID fileId) {
        this.id = Objects.requireNonNull(id, "id");
        this.title = Guard.length(title, "title", TITLE_MIN, TITLE_MAX);
        this.weight = Guard.range(weight, "weight", 0.01, 100.0);
        this.order = order;
        this.progress = Guard.range(progress, "progress", 0.0, 100.0);
        this.completed = completed;
        this.status = completed ? MilestoneStatus.COMPLETED : (status == null ? MilestoneStatus.LOCKED : status);
        this.dependencies = dependencies == null ? List.of() : List.copyOf(dependencies);
        this.condition = condition == null ? UnlockCondition.AND : condition;
        this.conditionN = Math.max(1, conditionN);
        this.subjectId = subjectId;
        this.difficulty = difficulty == null ? Difficulty.MEDIUM : difficulty;
        this.link = link;
        this.xpAwarded = Math.max(0, xpAwarded);
        if (noteId != null && fileId != null) {
            throw new MilestoneAttachmentConflictException();
        }
        this.noteId = noteId;
        this.fileId = fileId;
    }

    // ------------------------------------------------------------ mutaciones (las dirige Challenge)

    void redefine(String title, double weight, Difficulty difficulty, UUID subjectId, UUID noteId, UUID fileId,
                  ChallengeLink link, UnlockCondition condition, int conditionN) {
        if (noteId != null && fileId != null) {
            throw new MilestoneAttachmentConflictException();
        }
        this.title = Guard.length(title, "title", TITLE_MIN, TITLE_MAX);
        this.weight = Guard.range(weight, "weight", 0.01, 100.0);
        this.difficulty = difficulty == null ? Difficulty.MEDIUM : difficulty;
        this.subjectId = subjectId;
        this.noteId = noteId;
        this.fileId = fileId;
        this.link = link;
        this.condition = condition == null ? UnlockCondition.AND : condition;
        this.conditionN = Math.max(1, conditionN);
    }

    void changeDependencies(List<UUID> newDependencies) {
        this.dependencies = List.copyOf(newDependencies);
    }

    void moveTo(int newOrder) {
        this.order = newOrder;
    }

    /**
     * Marca la tarea como completada y devuelve el XP otorgado (0 si ya lo tenía): el de su dificultad,
     * sin pasar de {@code maxXp} (lo que le queda al reto de su tope).
     */
    int markCompleted(int maxXp) {
        completed = true;
        progress = 100.0;
        status = MilestoneStatus.COMPLETED;
        if (xpAwarded > 0) {
            return 0;
        }
        xpAwarded = Math.max(0, Math.min(difficulty.xp(), maxXp));
        return xpAwarded;
    }

    /** Descompleta la tarea con el progreso indicado y devuelve el XP que hay que restar. */
    int markUncompleted(double newProgress) {
        completed = false;
        progress = Guard.range(newProgress, "progress", 0.0, 99.999);
        // Provisional: Challenge recalcula enseguida si queda bloqueada por sus dependencias.
        status = MilestoneStatus.AVAILABLE;
        int revoked = xpAwarded;
        xpAwarded = 0;
        return revoked;
    }

    void changeProgress(double newProgress) {
        this.progress = Guard.range(newProgress, "progress", 0.0, 100.0);
    }

    /** Recalcula el estado de una tarea no completada. Devuelve true si pasa de bloqueada a desbloqueada. */
    boolean refreshStatus(boolean dependenciesSatisfied) {
        if (completed) {
            status = MilestoneStatus.COMPLETED;
            return false;
        }
        MilestoneStatus previous = status;
        if (!dependenciesSatisfied) {
            status = MilestoneStatus.LOCKED;
        } else {
            status = progress > 0 ? MilestoneStatus.IN_PROGRESS : MilestoneStatus.AVAILABLE;
        }
        return previous == MilestoneStatus.LOCKED && status != MilestoneStatus.LOCKED;
    }

    /** Peso efectivo en el progreso del reto (0-100). */
    double weightedProgress() {
        return weight * progress / 100.0;
    }

    public boolean isLocked() {
        return status == MilestoneStatus.LOCKED;
    }

    public UUID id() { return id; }
    public String title() { return title; }
    public double weight() { return weight; }
    public int order() { return order; }
    public double progress() { return progress; }
    public boolean completed() { return completed; }
    public MilestoneStatus status() { return status; }
    public List<UUID> dependencies() { return dependencies; }
    public UnlockCondition condition() { return condition; }
    public int conditionN() { return conditionN; }
    public UUID subjectId() { return subjectId; }
    public Difficulty difficulty() { return difficulty; }
    public ChallengeLink link() { return link; }
    public int xpAwarded() { return xpAwarded; }
    public UUID noteId() { return noteId; }
    public UUID fileId() { return fileId; }
}
