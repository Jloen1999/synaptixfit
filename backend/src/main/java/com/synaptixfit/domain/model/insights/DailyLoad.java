package com.synaptixfit.domain.model.insights;

import java.time.LocalDate;

/** Carga física total (AU) de un día. */
public record DailyLoad(LocalDate date, double load) {
}
