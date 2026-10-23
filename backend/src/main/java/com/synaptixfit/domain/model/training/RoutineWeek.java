package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.training.RoutineDayDuplicatedException;
import com.synaptixfit.domain.exception.training.RoutineDayNotFoundException;
import com.synaptixfit.domain.model.shared.Guard;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * Semana de una rutina. Su estado se deriva de sus días (regla única que sustituye a los dos
 * triggers heredados contradictorios): completada si todos sus días lo están, en progreso si
 * alguno está empezado o completado, pendiente en otro caso (también si no tiene días).
 */
public final class RoutineWeek {

    private final UUID id;
    private int number;
    private String name;
    private WeekType type;
    private ProgressStatus status;
    private final List<RoutineDay> days;

    public RoutineWeek(UUID id, int number, String name, WeekType type, ProgressStatus status, List<RoutineDay> days) {
        this.id = Objects.requireNonNull(id, "id");
        this.number = Guard.range(number, "weekNumber", 1, Routine.MAX_WEEKS);
        this.name = normalizeName(name, number);
        this.type = type == null ? WeekType.LOAD : type;
        this.status = status == null ? ProgressStatus.PENDING : status;
        this.days = new ArrayList<>(days == null ? List.of() : days);
        this.days.sort(Comparator.comparingInt(RoutineDay::number));
        long distinct = this.days.stream().mapToInt(RoutineDay::number).distinct().count();
        if (distinct != this.days.size()) {
            throw new RoutineDayDuplicatedException();
        }
    }

    public static RoutineWeek create(int number, String name, WeekType type, List<RoutineDay> days) {
        RoutineWeek week = new RoutineWeek(UUID.randomUUID(), number, name, type, ProgressStatus.PENDING, days);
        week.recomputeStatus();
        return week;
    }

    private static String normalizeName(String name, int number) {
        if (name == null || name.isBlank()) {
            return "Semana " + number;
        }
        return Guard.length(name, "weekName", 1, 120);
    }

    public void rename(String newName) {
        this.name = normalizeName(newName, number);
    }

    public void changeType(WeekType newType) {
        this.type = Guard.notNull(newType, "type");
    }

    /** Cambia el número (al borrar una semana anterior). Un nombre por defecto se actualiza con él. */
    void renumber(int newNumber) {
        boolean defaultName = name.equals("Semana " + number);
        this.number = newNumber;
        if (defaultName) {
            this.name = "Semana " + newNumber;
        }
    }

    public RoutineDay addDay(int dayNumber, String dayName) {
        if (days.stream().anyMatch(d -> d.number() == dayNumber)) {
            throw new RoutineDayDuplicatedException();
        }
        RoutineDay day = RoutineDay.create(dayNumber, dayName);
        days.add(day);
        days.sort(Comparator.comparingInt(RoutineDay::number));
        recomputeStatus();
        return day;
    }

    public void removeDay(UUID dayId) {
        RoutineDay day = findDay(dayId).orElseThrow(() -> new RoutineDayNotFoundException(dayId));
        days.remove(day);
        recomputeStatus();
    }

    public Optional<RoutineDay> findDay(UUID dayId) {
        return days.stream().filter(d -> d.id().equals(dayId)).findFirst();
    }

    public void recomputeStatus() {
        if (days.isEmpty()) {
            status = ProgressStatus.PENDING;
        } else if (days.stream().allMatch(d -> d.status() == ProgressStatus.COMPLETED)) {
            status = ProgressStatus.COMPLETED;
        } else if (days.stream().anyMatch(d -> d.status() != ProgressStatus.PENDING)) {
            status = ProgressStatus.IN_PROGRESS;
        } else {
            status = ProgressStatus.PENDING;
        }
    }

    RoutineWeek copyReset() {
        return new RoutineWeek(UUID.randomUUID(), number, name, type, ProgressStatus.PENDING,
                days.stream().map(RoutineDay::copyReset).toList());
    }

    public UUID id() { return id; }
    public int number() { return number; }
    public String name() { return name; }
    public WeekType type() { return type; }
    public ProgressStatus status() { return status; }
    public List<RoutineDay> days() { return List.copyOf(days); }
}
