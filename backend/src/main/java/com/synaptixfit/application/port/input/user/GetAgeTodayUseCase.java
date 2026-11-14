package com.synaptixfit.application.port.input.user;

import com.synaptixfit.domain.model.user.User;

/**
 * Edad de la persona hoy, con «hoy» en la zona del móvil ({@code zone}, IANA o desfase como «+01:00»; ADR 0036):
 * así cambia el mismo día que sale la tarjeta de cumpleaños de Inicio. Sin zona, la de la app.
 */
public interface GetAgeTodayUseCase {

    /** Nula si no dio su fecha de nacimiento. */
    Integer ageToday(User user, String zone);
}
