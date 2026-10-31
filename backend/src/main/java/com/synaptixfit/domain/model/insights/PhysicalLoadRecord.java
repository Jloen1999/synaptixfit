package com.synaptixfit.domain.model.insights;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Carga interna de una sesión de entrenamiento o de un bloque de deporte del calendario sin rutina
 * (session-RPE de Foster): {@code RPE x minutos}.
 *
 * <p>Una sesión o un bloque generan como máximo un registro ({@code sessionId} o {@code blockId} es la
 * clave de idempotencia).
 * Sin RPE válido se usa 5 (esfuerzo moderado) y la duración mínima es 1 minuto, como en el
 * trigger heredado {@code trg_insertar_carga_fisica}.
 */
public final class PhysicalLoadRecord {

    public static final int DEFAULT_RPE = 5;
    private static final int MAX_MINUTES = 24 * 60;

    private final UUID id;
    private final UUID userId;
    private final UUID sessionId;
    private final UUID blockId;
    private final Instant createdAt;
    private LocalDate date;
    private int rpe;
    private int durationMinutes;

    public PhysicalLoadRecord(UUID id, UUID userId, UUID sessionId, UUID blockId, LocalDate date, int rpe,
                              int durationMinutes, Instant createdAt) {
        this.id = Guard.notNull(id, "id");
        this.userId = Guard.notNull(userId, "userId");
        this.sessionId = sessionId;
        this.blockId = blockId;
        this.date = Guard.notNull(date, "date");
        this.rpe = Guard.range(rpe, "rpe", 1, 10);
        this.durationMinutes = Guard.range(durationMinutes, "durationMinutes", 1, MAX_MINUTES);
        this.createdAt = Guard.notNull(createdAt, "createdAt");
    }

    public static PhysicalLoadRecord forSession(UUID userId, UUID sessionId, LocalDate date, int rpe,
                                                int durationMinutes, Instant now) {
        Guard.notNull(sessionId, "sessionId");
        return new PhysicalLoadRecord(UUID.randomUUID(), userId, sessionId, null, date, normalizeRpe(rpe),
                normalizeDuration(durationMinutes), now);
    }

    /** Registro de un bloque de deporte completado; sin esfuerzo indicado se toma {@link #DEFAULT_RPE}. */
    public static PhysicalLoadRecord forBlock(UUID userId, UUID blockId, LocalDate date, int rpe,
                                              int durationMinutes, Instant now) {
        Guard.notNull(blockId, "blockId");
        return new PhysicalLoadRecord(UUID.randomUUID(), userId, null, blockId, date, normalizeRpe(rpe),
                normalizeDuration(durationMinutes), now);
    }

    /** Actualiza los datos si la sesión se ha vuelto a completar con otros valores. Devuelve si cambió algo. */
    public boolean update(LocalDate newDate, int newRpe, int newDurationMinutes) {
        LocalDate d = Guard.notNull(newDate, "date");
        int r = normalizeRpe(newRpe);
        int m = normalizeDuration(newDurationMinutes);
        boolean changed = !d.equals(date) || r != rpe || m != durationMinutes;
        date = d;
        rpe = r;
        durationMinutes = m;
        return changed;
    }

    static int normalizeRpe(int rpe) {
        if (rpe < 1) {
            return DEFAULT_RPE;
        }
        return Math.min(rpe, 10);
    }

    static int normalizeDuration(int minutes) {
        return Math.max(1, Math.min(minutes, MAX_MINUTES));
    }

    /** Unidades arbitrarias (AU): RPE x minutos. */
    public double load() {
        return load(rpe, durationMinutes);
    }

    /** Carga de una sesión (session-RPE de Foster): la única definición de la fórmula. */
    public static double load(int rpe, int durationMinutes) {
        return (double) rpe * durationMinutes;
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public UUID sessionId() { return sessionId; }
    public UUID blockId() { return blockId; }
    public LocalDate date() { return date; }
    public int rpe() { return rpe; }
    public int durationMinutes() { return durationMinutes; }
    public Instant createdAt() { return createdAt; }
}
