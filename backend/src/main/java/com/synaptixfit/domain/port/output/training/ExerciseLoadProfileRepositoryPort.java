package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.load.LoadProfile;
import java.util.Collection;
import java.util.Map;
import java.util.UUID;

/** Cómo se carga cada ejercicio y su peso de partida (catálogo de solo lectura, ADR 0054). */
public interface ExerciseLoadProfileRepositoryPort {

    /** Perfiles de los ejercicios pedidos que tienen uno; los que no, no aparecen. */
    Map<UUID, LoadProfile> findByExerciseIds(Collection<UUID> exerciseIds);
}
