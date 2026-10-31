package com.synaptixfit.infrastructure.adapter.output.external.mail;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.after;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.timeout;
import static org.mockito.Mockito.verify;

import com.synaptixfit.infrastructure.config.AppProperties;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/** El correo sale solo si la transacción se confirma, con el enlace a la app y los minutos redondeados. */
class PasswordResetEmailAdapterTest {

    private static final Instant NOW = Instant.parse("2026-10-31T10:00:00.250Z");

    private final ResendEmailClient client = mock(ResendEmailClient.class);
    private final PasswordResetEmailAdapter adapter = new PasswordResetEmailAdapter(client,
            new AppProperties(null, null, null, null, null,
                    new AppProperties.Mail("clave", "SynaptixFit <no-reply@example.com>", "https://app.example/")),
            Clock.fixed(NOW, ZoneOffset.UTC));

    @AfterEach
    void clean() {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.clearSynchronization();
        }
        adapter.destroy();
    }

    @Test
    void itWaitsForTheCommitAndLinksToTheApp() {
        TransactionSynchronizationManager.initSynchronization();

        adapter.sendPasswordReset("ana@example.com", "tok", NOW.plusSeconds(30 * 60 - 1));
        verify(client, after(200).never()).send(any());
        TransactionSynchronizationManager.getSynchronizations().forEach(TransactionSynchronization::afterCommit);

        ArgumentCaptor<ResendEmailClient.Message> sent = ArgumentCaptor.forClass(ResendEmailClient.Message.class);
        verify(client, timeout(2000)).send(sent.capture());
        assertThat(sent.getValue().text()).contains("https://app.example/#/reset-password?token=tok", "30 minutos");
    }

    @Test
    void nothingIsSentIfTheTransactionRollsBack() {
        TransactionSynchronizationManager.initSynchronization();

        adapter.sendPasswordReset("ana@example.com", "tok", NOW.plusSeconds(1800));
        TransactionSynchronizationManager.getSynchronizations()
                .forEach(s -> s.afterCompletion(TransactionSynchronization.STATUS_ROLLED_BACK));

        verify(client, after(300).never()).send(any());
    }

    @Test
    void outsideATransactionItSendsRightAway() {
        adapter.sendPasswordReset("ana@example.com", "tok", NOW.plusSeconds(1800));

        verify(client, timeout(2000)).send(any());
    }
}
