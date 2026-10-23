package com.synaptixfit.domain.model.training;

import java.util.List;

/** Valores disponibles para filtrar el catálogo de ejercicios. */
public record ExerciseFilterOptions(List<CatalogItem> bodyParts, List<CatalogItem> muscles,
                                    List<CatalogItem> equipment) {

    public ExerciseFilterOptions {
        bodyParts = List.copyOf(bodyParts);
        muscles = List.copyOf(muscles);
        equipment = List.copyOf(equipment);
    }
}
