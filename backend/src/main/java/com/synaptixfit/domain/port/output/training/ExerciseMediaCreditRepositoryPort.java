package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.MediaCredit;
import java.util.List;
import java.util.UUID;

/** Créditos de las fotos y vídeos de cada ejercicio ({@code creditos_medios_ejercicio}, ADR 0056). */
public interface ExerciseMediaCreditRepositoryPort {

    /** La foto primero y después el vídeo; vacía si sus medios no tienen crédito (los del catálogo original). */
    List<MediaCredit> findByExercise(UUID exerciseId);
}
