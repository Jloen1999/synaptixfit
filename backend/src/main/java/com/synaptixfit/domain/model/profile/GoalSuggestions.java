package com.synaptixfit.domain.model.profile;

import java.util.List;

/** Recomendaciones de objetivo principal, ordenadas de más a menos adecuada. */
public record GoalSuggestions(GoalSuggestionSource source, List<GoalSuggestion> suggestions) {

    public GoalSuggestions {
        suggestions = List.copyOf(suggestions);
    }
}
