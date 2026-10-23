package com.synaptixfit.domain.model.training;

import java.util.List;

/** Sesión del historial con su nombre (rutina y día) y los récords que se batieron en ella. */
public record SessionHistoryEntry(TrainingSession session, SessionLabel label, List<PersonalRecord> records) {

    public SessionHistoryEntry {
        records = List.copyOf(records == null ? List.of() : records);
    }
}
