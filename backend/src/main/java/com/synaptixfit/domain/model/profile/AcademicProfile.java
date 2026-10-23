package com.synaptixfit.domain.model.profile;

import com.synaptixfit.domain.exception.profile.InvalidClassDatesException;
import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * Perfil académico del usuario: universidad y carrera (texto libre, opcionalmente resuelto desde
 * el catálogo), semestre, modalidad, carga y objetivos, y las fechas del semestre que usa el
 * escaneo de horarios para materializar las clases.
 *
 * <p>Reglas: semestre 1-20, créditos 1-60, horas objetivo 0-80, promedio objetivo 0-5 (opcional)
 * y fecha de fin de clases nunca anterior a la de inicio.
 */
public final class AcademicProfile {

    public static final int DEFAULT_SEMESTER = 1;
    public static final int DEFAULT_CREDITS = 20;
    public static final int DEFAULT_WEEKLY_HOURS = 14;

    private final UUID id;
    private final UUID userId;
    private String university;
    private String degree;
    private int semester;
    private StudyModality modality;
    private int semesterCredits;
    private int weeklyStudyHoursGoal;
    private Double targetGpa;
    private LocalDate classesStartDate;
    private LocalDate classesEndDate;
    private final Instant createdAt;
    private Instant updatedAt;

    public AcademicProfile(UUID id, UUID userId, String university, String degree, int semester,
                           StudyModality modality, int semesterCredits, int weeklyStudyHoursGoal, Double targetGpa,
                           LocalDate classesStartDate, LocalDate classesEndDate, Instant createdAt,
                           Instant updatedAt) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = Objects.requireNonNull(userId, "userId");
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
        this.updatedAt = updatedAt == null ? createdAt : updatedAt;
        changeUniversity(university);
        changeDegree(degree);
        changeSemester(semester);
        changeModality(modality);
        changeSemesterCredits(semesterCredits);
        changeWeeklyStudyHoursGoal(weeklyStudyHoursGoal);
        changeTargetGpa(targetGpa);
        changeClassDates(classesStartDate, classesEndDate);
    }

    /** Perfil nuevo con los valores por defecto. */
    public static AcademicProfile createDefault(UUID userId, Instant now) {
        return new AcademicProfile(UUID.randomUUID(), userId, null, null, DEFAULT_SEMESTER, StudyModality.IN_PERSON,
                DEFAULT_CREDITS, DEFAULT_WEEKLY_HOURS, null, null, null, now, now);
    }

    public void changeUniversity(String value) {
        this.university = optionalText(value, "university", 200);
    }

    public void changeDegree(String value) {
        this.degree = optionalText(value, "degree", 200);
    }

    public void changeSemester(int value) {
        this.semester = Guard.range(value, "semester", 1, 20);
    }

    public void changeModality(StudyModality value) {
        this.modality = Guard.notNull(value, "modality");
    }

    public void changeSemesterCredits(int value) {
        this.semesterCredits = Guard.range(value, "semesterCredits", 1, 60);
    }

    public void changeWeeklyStudyHoursGoal(int value) {
        this.weeklyStudyHoursGoal = Guard.range(value, "weeklyStudyHoursGoal", 0, 80);
    }

    public void changeTargetGpa(Double value) {
        this.targetGpa = value == null ? null : Guard.range(value, "targetGpa", 0.0, 5.0);
    }

    /** Fija las fechas del semestre (ambas opcionales). Fin anterior a inicio: error. */
    public void changeClassDates(LocalDate start, LocalDate end) {
        if (start != null && end != null && end.isBefore(start)) {
            throw new InvalidClassDatesException(start, end);
        }
        this.classesStartDate = start;
        this.classesEndDate = end;
    }

    public boolean hasSemesterDates() {
        return classesStartDate != null && classesEndDate != null;
    }

    public void touch(Instant when) {
        this.updatedAt = Objects.requireNonNull(when);
    }

    private static String optionalText(String value, String field, int max) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return Guard.length(value, field, 1, max);
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public String university() { return university; }
    public String degree() { return degree; }
    public int semester() { return semester; }
    public StudyModality modality() { return modality; }
    public int semesterCredits() { return semesterCredits; }
    public int weeklyStudyHoursGoal() { return weeklyStudyHoursGoal; }
    public Double targetGpa() { return targetGpa; }
    public LocalDate classesStartDate() { return classesStartDate; }
    public LocalDate classesEndDate() { return classesEndDate; }
    public Instant createdAt() { return createdAt; }
    public Instant updatedAt() { return updatedAt; }
}
