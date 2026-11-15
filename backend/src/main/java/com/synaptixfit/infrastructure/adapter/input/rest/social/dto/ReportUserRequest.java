package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import com.synaptixfit.domain.model.social.UserReportContext;
import jakarta.validation.constraints.NotNull;

/** Denuncia de una persona: solo dónde pasó (sin texto libre, ADR 0044). */
public record ReportUserRequest(@NotNull UserReportContext context) {
}
