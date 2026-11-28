package com.synaptixfit.domain.port.output.wod;

import com.synaptixfit.domain.model.wod.Wod;
import com.synaptixfit.domain.model.wod.WodMark;
import com.synaptixfit.domain.model.wod.WodResult;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Los WOD de cada persona ({@code wods}) y sus marcas ({@code resultados_wod}). */
public interface WodRepositoryPort {

    Wod save(Wod wod);

    Optional<Wod> findOwned(UUID userId, UUID wodId);

    /** El WOD de ese día; si hay varios, el último que se tocó. */
    Optional<Wod> findOfDay(UUID userId, LocalDate date);

    /** Borra el WOD con sus marcas (las actividades apuntadas se quedan). */
    void delete(UUID userId, UUID wodId);

    WodResult saveResult(WodResult result);

    /** Todas las marcas de la persona con su WOD, de la más reciente a la más antigua. */
    List<WodMark> findMarks(UUID userId);
}
