package com.synaptixfit.domain.model.training;

import java.util.List;

/**
 * Sesión del historial con su nombre (rutina y día), los récords que se batieron en ella y si aún se
 * puede desmarcar (solo el mismo día; si no, se corrige o se elimina).
 */
public record SessionHistoryEntry(TrainingSession session, SessionLabel label, List<PersonalRecord> records,
                                  boolean unmarkable) {

    public SessionHistoryEntry {
        records = List.copyOf(records == null ? List.of() : records);
    }

    public SessionHistoryEntry(TrainingSession session, SessionLabel label, List<PersonalRecord> records) {
        this(session, label, records, false);
    }
}
