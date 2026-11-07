package com.synaptixfit.domain.model.profile;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;

/**
 * Perfil físico y de entrenamiento del usuario (onboarding físico).
 *
 * <p>Reglas: edad declarada 15-80 y opcional (desde ADR 0036 la edad sale de la fecha de nacimiento de la cuenta;
 * esta es la que se dio antes y solo se usa si no hay fecha, ver {@code BirthDate#effectiveAge}), peso 30-250 kg, altura 120-230 cm, IMC derivado de peso y altura,
 * minutos por sesión 10-180 y días disponibles como conjunto no vacío de días ISO (1 = lunes,
 * 7 = domingo). El número de días por semana se deriva siempre de ese conjunto, así no puede
 * contradecirlo (en el sistema antiguo {@code dias_disponibles_semana} y {@code dias_disponibles}
 * se guardaban por separado y podían divergir).
 */
public final class WellnessProfile {

    public static final int MIN_AGE = 15;
    public static final int MAX_AGE = 80;
    public static final int MIN_MINUTES = 10;
    public static final int MAX_MINUTES = 180;

    /**
     * Valores para el onboarding corto, si no se indican: tres días de 50 min (los 150 min
     * semanales de actividad moderada que recomienda la OMS) y actividad ligera, lo prudente para
     * empezar. Se cambian después en el perfil físico.
     */
    public static final ActivityLevel DEFAULT_ACTIVITY_LEVEL = ActivityLevel.LIGHT;
    public static final List<Integer> DEFAULT_AVAILABLE_DAYS = List.of(1, 3, 5);
    public static final int DEFAULT_MINUTES = 50;
    private static final int MAX_GOALS = 10;
    private static final int MAX_EQUIPMENT = 30;

    private final UUID id;
    private final UUID userId;
    private Integer age;
    private Sex sex;
    private String city;
    private BodyMeasurement measurement;
    private ActivityLevel activityLevel;
    private TrainingGoal primaryGoal;
    private List<String> goals;
    private List<String> equipment;
    private List<Integer> availableDays;
    private int minutesPerSession;
    private boolean onboardingCompleted;
    private final Instant createdAt;
    private Instant updatedAt;

    private WellnessProfile(Builder b) {
        this.id = Objects.requireNonNull(b.id, "id");
        this.userId = Objects.requireNonNull(b.userId, "userId");
        this.createdAt = Objects.requireNonNull(b.createdAt, "createdAt");
        this.updatedAt = b.updatedAt == null ? b.createdAt : b.updatedAt;
        changeAge(b.age);
        changeSex(b.sex);
        changeCity(b.city);
        this.measurement = Guard.notNull(b.measurement, "measurement");
        changeActivityLevel(b.activityLevel);
        this.primaryGoal = Guard.notNull(b.primaryGoal, "primaryGoal");
        replaceGoals(b.goals);
        replaceEquipment(b.equipment);
        changeAvailableDays(b.availableDays);
        changeMinutesPerSession(b.minutesPerSession);
        this.onboardingCompleted = b.onboardingCompleted;
    }

    public static Builder builder() {
        return new Builder();
    }

    /** Edad declarada; {@code null} la deja sin dar (se usa la fecha de nacimiento). */
    public void changeAge(Integer newAge) {
        this.age = newAge == null ? null : Guard.range(newAge, "age", MIN_AGE, MAX_AGE);
    }

    public void changeSex(Sex newSex) {
        this.sex = Guard.notNull(newSex, "sex");
    }

    public void changeCity(String newCity) {
        if (newCity == null || newCity.isBlank()) {
            this.city = null;
            return;
        }
        this.city = Guard.length(newCity, "city", 1, 100);
    }

    /** Cambia peso y altura. Devuelve {@code true} si algo cambió (hay que registrarlo en el historial). */
    public boolean changeMeasurement(BodyMeasurement newMeasurement) {
        Guard.notNull(newMeasurement, "measurement");
        boolean changed = !newMeasurement.equals(measurement);
        this.measurement = newMeasurement;
        return changed;
    }

    public void changeActivityLevel(ActivityLevel level) {
        this.activityLevel = Guard.notNull(level, "activityLevel");
    }

    /**
     * Cambia el objetivo principal. Devuelve {@code true} si cambió (hay que cerrar el periodo del
     * historial de objetivos y abrir otro). Si la lista de objetivos solo contenía el objetivo
     * anterior, se sustituye por el nuevo para que no quede incoherente.
     */
    public boolean changePrimaryGoal(TrainingGoal newGoal) {
        Guard.notNull(newGoal, "primaryGoal");
        if (newGoal == primaryGoal) {
            return false;
        }
        TrainingGoal previous = primaryGoal;
        this.primaryGoal = newGoal;
        if (goals != null && goals.size() == 1 && goals.get(0).equals(previous.label())) {
            this.goals = List.of(newGoal.label());
        }
        return true;
    }

    /** Objetivos secundarios en texto libre. Vacía: se usa el objetivo principal. */
    public void replaceGoals(List<String> newGoals) {
        List<String> cleaned = cleanTexts(newGoals, "goals", MAX_GOALS, 100, false);
        this.goals = cleaned.isEmpty() ? List.of(primaryGoal.label()) : cleaned;
    }

    /** Equipamiento disponible (identificadores en minúsculas, p. ej. {@code mancuerna}). */
    public void replaceEquipment(List<String> newEquipment) {
        this.equipment = cleanTexts(newEquipment, "equipment", MAX_EQUIPMENT, 50, true);
    }

    public void changeAvailableDays(List<Integer> days) {
        if (days == null || days.isEmpty()) {
            throw new FieldValidationException("availableDays", "REQUIRED", "at least one available day is required");
        }
        Set<Integer> sorted = new TreeSet<>();
        for (Integer day : days) {
            if (day == null || day < 1 || day > 7) {
                throw new FieldValidationException("availableDays", "OUT_OF_RANGE",
                        "available days must be between 1 (Monday) and 7 (Sunday)");
            }
            sorted.add(day);
        }
        this.availableDays = List.copyOf(sorted);
    }

    public void changeMinutesPerSession(int minutes) {
        this.minutesPerSession = Guard.range(minutes, "minutesPerSession", MIN_MINUTES, MAX_MINUTES);
    }

    public void completeOnboarding() {
        this.onboardingCompleted = true;
    }

    public void touch(Instant when) {
        this.updatedAt = Objects.requireNonNull(when);
    }

    private static List<String> cleanTexts(List<String> values, String field, int maxItems, int maxLength,
                                           boolean lowercase) {
        if (values == null) {
            return List.of();
        }
        Set<String> result = new LinkedHashSet<>();
        for (String value : values) {
            if (value == null || value.isBlank()) {
                continue;
            }
            String v = value.strip();
            if (lowercase) {
                v = v.toLowerCase(Locale.ROOT);
            }
            if (v.length() > maxLength) {
                throw new FieldValidationException(field, "INVALID_LENGTH",
                        field + " items must have at most " + maxLength + " characters");
            }
            result.add(v);
        }
        if (result.size() > maxItems) {
            throw new FieldValidationException(field, "TOO_MANY_ITEMS",
                    field + " allows at most " + maxItems + " items");
        }
        return List.copyOf(result);
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public Integer age() { return age; }
    public Sex sex() { return sex; }
    public String city() { return city; }
    public BodyMeasurement measurement() { return measurement; }
    public double weightKg() { return measurement.weightKg(); }
    public double heightCm() { return measurement.heightCm(); }
    public double bmi() { return measurement.bmi(); }
    public ActivityLevel activityLevel() { return activityLevel; }
    public TrainingGoal primaryGoal() { return primaryGoal; }
    public List<String> goals() { return goals; }
    public List<String> equipment() { return equipment; }
    public List<Integer> availableDays() { return availableDays; }
    public int daysPerWeek() { return availableDays.size(); }
    public int minutesPerSession() { return minutesPerSession; }
    public boolean onboardingCompleted() { return onboardingCompleted; }
    public Instant createdAt() { return createdAt; }
    public Instant updatedAt() { return updatedAt; }

    /** Constructor fluido para crear o reconstruir el perfil. */
    public static final class Builder {
        private UUID id;
        private UUID userId;
        private Integer age;
        private Sex sex;
        private String city;
        private BodyMeasurement measurement;
        private ActivityLevel activityLevel;
        private TrainingGoal primaryGoal;
        private List<String> goals;
        private List<String> equipment;
        private List<Integer> availableDays;
        private int minutesPerSession;
        private boolean onboardingCompleted;
        private Instant createdAt;
        private Instant updatedAt;

        public Builder id(UUID v) { this.id = v; return this; }
        public Builder userId(UUID v) { this.userId = v; return this; }
        public Builder age(Integer v) { this.age = v; return this; }
        public Builder sex(Sex v) { this.sex = v; return this; }
        public Builder city(String v) { this.city = v; return this; }
        public Builder measurement(BodyMeasurement v) { this.measurement = v; return this; }
        public Builder activityLevel(ActivityLevel v) { this.activityLevel = v; return this; }
        public Builder primaryGoal(TrainingGoal v) { this.primaryGoal = v; return this; }
        public Builder goals(List<String> v) { this.goals = v; return this; }
        public Builder equipment(List<String> v) { this.equipment = v; return this; }
        public Builder availableDays(List<Integer> v) { this.availableDays = v; return this; }
        public Builder minutesPerSession(int v) { this.minutesPerSession = v; return this; }
        public Builder onboardingCompleted(boolean v) { this.onboardingCompleted = v; return this; }
        public Builder createdAt(Instant v) { this.createdAt = v; return this; }
        public Builder updatedAt(Instant v) { this.updatedAt = v; return this; }

        public WellnessProfile build() {
            return new WellnessProfile(this);
        }
    }
}
