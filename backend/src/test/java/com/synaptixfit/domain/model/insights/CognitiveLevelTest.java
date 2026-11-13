package com.synaptixfit.domain.model.insights;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

/** Umbrales de «Tu equilibrio» (formulas.md, fórmula 2): ahora los decide el servidor (ADR 0039). */
class CognitiveLevelTest {

    @Test
    void loadZonesFollowTheDocumentedThresholds() {
        assertThat(CognitiveLevel.ofLoad(0.29)).isEqualTo(CognitiveLevel.LOW);
        assertThat(CognitiveLevel.ofLoad(0.3)).isEqualTo(CognitiveLevel.MODERATE);
        assertThat(CognitiveLevel.ofLoad(0.6)).isEqualTo(CognitiveLevel.HIGH);
        assertThat(CognitiveLevel.ofLoad(0.8)).isEqualTo(CognitiveLevel.CRITICAL);
    }

    @Test
    void attentionHasNoCriticalLevel() {
        assertThat(CognitiveLevel.ofAttention(0.39)).isEqualTo(CognitiveLevel.LOW);
        assertThat(CognitiveLevel.ofAttention(0.4)).isEqualTo(CognitiveLevel.MODERATE);
        assertThat(CognitiveLevel.ofAttention(0.7)).isEqualTo(CognitiveLevel.HIGH);
        assertThat(CognitiveLevel.ofAttention(1)).isEqualTo(CognitiveLevel.HIGH);
    }
}
