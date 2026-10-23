package com.synaptixfit.infrastructure.adapter.input.rest.support;

import com.synaptixfit.domain.model.shared.PageResult;
import java.util.List;
import java.util.function.Function;

/** Página de resultados en la API ({@code ?page=0&size=20}). */
public record PageResponse<T>(List<T> items, int page, int size, long totalItems, int totalPages) {

    public static <D, T> PageResponse<T> from(PageResult<D> result, Function<D, T> mapper) {
        return new PageResponse<>(result.items().stream().map(mapper).toList(), result.page(), result.size(),
                result.totalItems(), result.totalPages());
    }
}
