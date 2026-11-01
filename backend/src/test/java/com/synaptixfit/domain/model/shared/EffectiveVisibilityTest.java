package com.synaptixfit.domain.model.shared;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** Regla única de visibilidad del contenido compartido. */
class EffectiveVisibilityTest {

    private static AuthorAudience author(Visibility privacy, boolean friends, boolean blocked) {
        return new AuthorAudience(true, false, privacy, friends, blocked);
    }

    @Test
    void theMostRestrictiveOfContentAndProfileWins() {
        assertThat(EffectiveVisibility.of(Visibility.PUBLIC, Visibility.FRIENDS)).isEqualTo(Visibility.FRIENDS);
        assertThat(EffectiveVisibility.of(Visibility.FRIENDS, Visibility.PUBLIC)).isEqualTo(Visibility.FRIENDS);
        assertThat(EffectiveVisibility.of(Visibility.PUBLIC, Visibility.PRIVATE)).isEqualTo(Visibility.PRIVATE);
        assertThat(EffectiveVisibility.of(null, Visibility.PUBLIC)).isEqualTo(Visibility.PRIVATE);
    }

    @Test
    void friendsOnlyProfilesShareOnlyWithFriendsAndBlocksHideEverything() {
        assertThat(EffectiveVisibility.canView(Visibility.PUBLIC, author(Visibility.FRIENDS, false, false))).isFalse();
        assertThat(EffectiveVisibility.canView(Visibility.PUBLIC, author(Visibility.FRIENDS, true, false))).isTrue();
        assertThat(EffectiveVisibility.canView(Visibility.PUBLIC, author(Visibility.PUBLIC, false, false))).isTrue();
        assertThat(EffectiveVisibility.canView(Visibility.FRIENDS, author(Visibility.PUBLIC, false, false))).isFalse();
        assertThat(EffectiveVisibility.canView(Visibility.PUBLIC, author(Visibility.PUBLIC, true, true))).isFalse();
        assertThat(EffectiveVisibility.canView(Visibility.PUBLIC,
                new AuthorAudience(true, true, Visibility.PUBLIC, true, false))).isFalse();
        assertThat(EffectiveVisibility.canView(Visibility.PUBLIC, AuthorAudience.missing())).isFalse();
    }

    @Test
    void scopesSplitFriendsAndCommunity() {
        AuthorAudience friend = author(Visibility.PUBLIC, true, false);
        assertThat(EffectiveVisibility.canView(Visibility.FRIENDS, friend, AudienceScope.FRIENDS)).isTrue();
        assertThat(EffectiveVisibility.canView(Visibility.FRIENDS, friend, AudienceScope.PUBLIC)).isFalse();
        assertThat(EffectiveVisibility.canView(Visibility.PUBLIC, friend, AudienceScope.PUBLIC)).isTrue();
        assertThat(EffectiveVisibility.canView(Visibility.PUBLIC, author(Visibility.PUBLIC, false, false),
                AudienceScope.FRIENDS)).isFalse();
    }

    /** Lo que permite filtrar en SQL comparando las dos columnas por separado con los mismos niveles. */
    @Test
    void levelSetsAreUpwardClosedSoBothColumnsCanBeComparedApart() {
        for (AudienceScope scope : AudienceScope.values()) {
            for (Set<Visibility> levels : List.of(EffectiveVisibility.levelsForFriends(scope),
                    EffectiveVisibility.levelsForAnyone(scope), EffectiveVisibility.sharedLevels())) {
                for (Visibility content : Visibility.values()) {
                    for (Visibility profile : Visibility.values()) {
                        assertThat(levels.contains(EffectiveVisibility.of(content, profile)))
                                .isEqualTo(levels.contains(content) && levels.contains(profile));
                    }
                }
            }
        }
    }
}
