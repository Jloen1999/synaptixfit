package com.synaptixfit.infrastructure.adapter.input.rest.run;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.run.RunRouteTooLargeException;
import java.io.ByteArrayInputStream;
import org.junit.jupiter.api.Test;

/** El límite de la subida de carreras vale aunque no llegue {@code Content-Length}: se cuenta lo leído. */
class RunBodyLimitAdviceTest {

    @Test
    void aBodyWithinTheLimitIsReadWhole() throws Exception {
        assertThat(RunBodyLimitAdvice.readAtMost(new ByteArrayInputStream(new byte[10]), 10)).hasSize(10);
    }

    @Test
    void aBodyOverTheLimitIsRejectedWithoutContentLength() {
        assertThatThrownBy(() -> RunBodyLimitAdvice.readAtMost(new ByteArrayInputStream(new byte[11]), 10))
                .isInstanceOf(RunRouteTooLargeException.class);
    }
}
