package com.synaptixfit.infrastructure.adapter.input.rest.planner.dto;

import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.SuggestedBlock;
import com.synaptixfit.domain.model.planner.WeekPlanSuggestions;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Propuesta semanal (no guardada). {@code source}: AI o HEURISTIC. */
public record SuggestionResponse(WeekPlanSuggestions.Source source, double studyHours, int sportSessions,
                                 List<Block> blocks) {

    /** Bloque propuesto; se acepta creándolo con POST /api/v1/planner/blocks. */
    public record Block(ActivityType type, Instant start, Instant end, UUID subjectId, String subjectName,
                        UUID routineId, String routineName, String topic) {

        static Block from(SuggestedBlock b) {
            return new Block(b.type(), b.start(), b.end(), b.subjectId(), b.subjectName(), b.routineId(),
                    b.routineName(), b.topic());
        }
    }

    public static SuggestionResponse from(WeekPlanSuggestions.Suggestion s) {
        return new SuggestionResponse(s.source(), Math.round(s.studyHours() * 100) / 100.0, s.sportSessions(),
                s.blocks().stream().map(Block::from).toList());
    }
}
