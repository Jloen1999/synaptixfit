package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.together;

import com.synaptixfit.domain.model.together.MemberStatus;
import java.util.Arrays;
import java.util.List;

/** Valores que las consultas de «Con amigos» reciben como parámetro (la regla vive en el dominio). */
final class TogetherSql {

    /** Estados de quien todavía ve algo compartido ({@link MemberStatus#canView}). */
    static final List<String> VISIBLE = Arrays.stream(MemberStatus.values())
            .filter(MemberStatus::canView).map(Enum::name).toList();

    private TogetherSql() {
    }
}
