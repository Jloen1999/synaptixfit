package com.synaptixfit.infrastructure.adapter.input.rest.profile.dto;

import com.synaptixfit.domain.model.profile.GoalSuggestionSource;
import com.synaptixfit.domain.model.profile.GoalSuggestions;
import com.synaptixfit.domain.model.profile.TrainingGoal;
import java.util.List;

/** Objetivos recomendados (de más a menos adecuado) y su origen: IA o reglas de respaldo. */
public record GoalSuggestionsResponse(GoalSuggestionSource source, List<Item> suggestions) {

    /** Un objetivo recomendado. */
    public record Item(TrainingGoal goal, String label, String reason) {}

    public static GoalSuggestionsResponse from(GoalSuggestions s) {
        return new GoalSuggestionsResponse(s.source(), s.suggestions().stream()
                .map(g -> new Item(g.goal(), g.goal().label(), g.reason())).toList());
    }
}
