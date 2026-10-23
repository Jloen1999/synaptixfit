package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

/** Dos bloques que se solapan. */
public record ConflictResponse(CalendarBlockResponse first, CalendarBlockResponse second) {
}
