package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * Check-in diario de fatiga (uno por usuario y día). Escalas 1-5.
 *
 * <p>Puntuación de fatiga 0-100 (heredada): {@code (6-sueño)*5 + (estrés-1)*5 + (6-energía)*4 +
 * (dolor-1)*7}. Por encima de 50 se recomienda adaptar el entrenamiento.
 */
public final class DailyCheckIn {

    public static final int ADAPTATION_THRESHOLD = 50;

    private final UUID id;
    private final UUID userId;
    private final LocalDate date;
    private int sleepQuality;
    private int stress;
    private int energy;
    private int soreness;
    private List<String> painZones;
    private boolean readyToTrain;
    private String notes;
    private final Instant createdAt;

    public DailyCheckIn(UUID id, UUID userId, LocalDate date, int sleepQuality, int stress, int energy,
                        int soreness, List<String> painZones, boolean readyToTrain, String notes, Instant createdAt) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.date = Objects.requireNonNull(date, "date");
        this.createdAt = createdAt;
        apply(new Values(sleepQuality, stress, energy, soreness, painZones, readyToTrain, notes));
    }

    public static DailyCheckIn create(UUID userId, LocalDate date, Values values, Instant now) {
        return new DailyCheckIn(UUID.randomUUID(), userId, date, values.sleepQuality(), values.stress(),
                values.energy(), values.soreness(), values.painZones(), values.readyToTrain(), values.notes(), now);
    }

    public void apply(Values v) {
        this.sleepQuality = Guard.range(v.sleepQuality(), "sleepQuality", 1, 5);
        this.stress = Guard.range(v.stress(), "stress", 1, 5);
        this.energy = Guard.range(v.energy(), "energy", 1, 5);
        this.soreness = Guard.range(v.soreness(), "soreness", 1, 5);
        List<String> zones = v.painZones() == null ? List.of()
                : v.painZones().stream().filter(z -> z != null && !z.isBlank()).map(String::strip).distinct().toList();
        if (zones.size() > 12 || zones.stream().anyMatch(z -> z.length() > 40)) {
            throw new FieldValidationException("painZones", "OUT_OF_RANGE", "at most 12 zones of 40 characters");
        }
        this.painZones = zones;
        this.readyToTrain = v.readyToTrain();
        String n = v.notes() == null || v.notes().isBlank() ? null : v.notes().strip();
        if (n != null && n.length() > 1000) {
            throw new FieldValidationException("notes", "INVALID_LENGTH", "notes length must be at most 1000");
        }
        this.notes = n;
    }

    public int fatigueScore() {
        int score = (6 - sleepQuality) * 5 + (stress - 1) * 5 + (6 - energy) * 4 + (soreness - 1) * 7;
        return Math.max(0, Math.min(100, score));
    }

    public boolean requiresAdaptation() {
        return fatigueScore() > ADAPTATION_THRESHOLD;
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public LocalDate date() { return date; }
    public int sleepQuality() { return sleepQuality; }
    public int stress() { return stress; }
    public int energy() { return energy; }
    public int soreness() { return soreness; }
    public List<String> painZones() { return painZones; }
    public boolean readyToTrain() { return readyToTrain; }
    public String notes() { return notes; }
    public Instant createdAt() { return createdAt; }

    /** Respuestas del check-in. */
    public record Values(int sleepQuality, int stress, int energy, int soreness, List<String> painZones,
                         boolean readyToTrain, String notes) {
    }
}
