package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training;

import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.ExerciseRef;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineOrigin;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.ExerciseSelectionEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.RoutineDayEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.RoutineEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.RoutineWeekEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.VisibilityDbMapper;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Agregado rutina ↔ entidades {@code rutinas}, {@code semanas_rutina}, {@code dias_rutina} y {@code seleccion_de_ejercicios}. */
public final class RoutinePersistenceMapper {

    private RoutinePersistenceMapper() {
    }

    public static Routine toDomain(RoutineEntity e, List<RoutineWeek> weeks) {
        RoutineOrigin origin = e.getOrigenId() == null && e.getOrigenPropietarioId() == null ? null
                : new RoutineOrigin(e.getOrigenId(), e.getOrigenPropietarioId(), e.getOrigenPropietarioNombre());
        return new Routine(e.getId(), e.getUsuarioId(), e.getNombre(), e.getDescripcion(),
                VisibilityDbMapper.toDomain(e.getVisibilidad()), TrainingDbValues.routineStatus(e.getEstado()),
                TrainingGoal.fromLabelOrDefault(e.getObjetivo()), e.getFechaInicio(), origin, e.getCreadoEn(),
                e.getEliminadoEn(), weeks);
    }

    public static RoutineWeek toDomain(RoutineWeekEntity e, List<RoutineDay> days) {
        return new RoutineWeek(e.getId(), e.getNumeroSemana(), e.getNombre(), TrainingDbValues.weekType(e.getTipoSemana()),
                TrainingDbValues.weekStatus(e.getEstado()), days);
    }

    public static RoutineDay toDomain(RoutineDayEntity e, List<PlannedExercise> exercises) {
        return new RoutineDay(e.getId(), e.getNumeroDia(), e.getNombre(), TrainingDbValues.dayStatus(e.getEstado()),
                e.getCerradoEn(), exercises);
    }

    public static PlannedExercise toDomain(ExerciseSelectionEntity e, Map<UUID, ExerciseRef> refs) {
        ExerciseRef ref = refs.getOrDefault(e.getEjercicioId(), ExerciseRef.unknown(e.getEjercicioId()));
        // Los datos heredados pueden estar fuera de rango: se ajustan en lugar de romper la lectura.
        ExerciseParameters params = ExerciseParameters.clamped(e.getSeries(), e.getRepeticiones(),
                e.getSegundosDescanso(), e.getPesoKg(), e.getPesosKg(), e.getDuracionObjetivoSegundos(),
                e.getDistanciaMetros(), e.getTiempoIsometricoSegundos(), e.getRepeticionesPorSerie(),
                e.getSegundosIsometricosPorSerie());
        return new PlannedExercise(e.getId(), ref, params, e.getIndiceOrden(), e.getDuracionRealSegundos());
    }

    public static void copy(Routine r, RoutineEntity e) {
        e.setId(r.id());
        e.setUsuarioId(r.ownerId());
        e.setNombre(r.name());
        e.setDescripcion(r.description());
        e.setVisibilidad(VisibilityDbMapper.toDb(r.visibility()));
        e.setEstado(TrainingDbValues.toDb(r.status()));
        e.setObjetivo(r.goal().label());
        e.setFechaInicio(r.startDate());
        e.setCantidadEjercicios(r.exerciseCount());
        e.setDuracionSemanas(Math.max(1, r.durationWeeks()));
        e.setEliminadoEn(r.deletedAt());
        if (r.origin() != null) {
            e.setOrigenId(r.origin().routineId());
            e.setOrigenPropietarioId(r.origin().ownerId());
            e.setOrigenPropietarioNombre(r.origin().ownerName());
        } else {
            e.setOrigenId(null);
            e.setOrigenPropietarioId(null);
            e.setOrigenPropietarioNombre(null);
        }
        if (e.getCreadoEn() == null) {
            e.setCreadoEn(r.createdAt());
        }
    }

    public static void copy(RoutineWeek w, UUID routineId, RoutineWeekEntity e) {
        e.setId(w.id());
        e.setRutinaId(routineId);
        e.setNumeroSemana(w.number());
        e.setNombre(w.name());
        e.setTipoSemana(TrainingDbValues.toDb(w.type()));
        e.setEstado(TrainingDbValues.weekStatusToDb(w.status()));
    }

    public static void copy(RoutineDay d, UUID weekId, RoutineDayEntity e) {
        e.setId(d.id());
        e.setSemanaId(weekId);
        e.setNumeroDia(d.number());
        // La columna no admite nulos: un día sin nombre propio se guarda vacío.
        e.setNombre(d.name() == null ? "" : d.name());
        e.setEstado(TrainingDbValues.dayStatusToDb(d.status()));
        e.setCerradoEn(d.closedOn());
    }

    public static void copy(PlannedExercise p, UUID routineId, UUID dayId, ExerciseSelectionEntity e) {
        ExerciseParameters x = p.parameters();
        e.setId(p.id());
        e.setRutinaId(routineId);
        e.setDiaId(dayId);
        e.setEjercicioId(p.exerciseId());
        e.setSeries(x.sets());
        e.setRepeticiones(x.reps());
        e.setSegundosDescanso(x.restSeconds());
        e.setIndiceOrden(p.order());
        e.setPesoKg(x.weightKg());
        e.setPesosKg(x.weightsKg());
        e.setRepeticionesPorSerie(x.repsPerSet());
        e.setSegundosIsometricosPorSerie(x.isometricSecondsPerSet());
        e.setDuracionObjetivoSegundos(x.targetDurationSeconds());
        e.setDistanciaMetros(x.distanceMeters());
        e.setTiempoIsometricoSegundos(x.isometricSeconds());
        e.setDuracionRealSegundos(p.realDurationSeconds());
    }
}
