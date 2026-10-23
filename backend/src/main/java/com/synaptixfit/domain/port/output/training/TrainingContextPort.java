package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.generation.AcademicContext;
import com.synaptixfit.domain.model.training.generation.PhysiologicalContext;
import com.synaptixfit.domain.model.training.generation.TrainingProfile;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

/**
 * Lecturas de datos de otros módulos (perfil, planificador, indicadores, cuenta) que necesita el
 * entrenamiento. Solo lectura.
 */
public interface TrainingContextPort {

    /** Peso corporal del perfil de bienestar. */
    Optional<Double> bodyWeightKg(UUID userId);

    Optional<TrainingProfile> profile(UUID userId);

    /**
     * Situación académica de la semana de {@code today}, sin carga cognitiva ni ACWR (nulos): esos
     * valores los recalculan los indicadores y el servicio los añade con {@code withInsights}.
     */
    AcademicContext academicContext(UUID userId, LocalDate today);

    /** Tendencia de peso (actual y de hace una semana), racha y nivel. */
    PhysiologicalContext physiologicalContext(UUID userId, LocalDate today);

    /** Último cambio de objetivo registrado en el historial de objetivos. */
    Optional<GoalChange> latestGoalChange(UUID userId);

    /** Cambio de objetivo: anterior, actual y desde cuándo. */
    record GoalChange(TrainingGoal previous, TrainingGoal current, LocalDate since) {
    }
}
