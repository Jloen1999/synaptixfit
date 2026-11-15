package com.synaptixfit.infrastructure.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.support.SimpleTransactionStatus;

/**
 * La factoría transaccional repite el caso de uso cuando otra transacción cambió a la vez una fila con versión
 * (ADR 0047: la sesión que pausó otra persona del entreno juntos), y solo unas pocas veces.
 */
class TransactionalUseCaseFactoryTest {

    interface Action {
        String run();
    }

    /** Gestor de transacciones de mentira: cuenta cuántas se abren y cuántas se deshacen. */
    private static final class CountingTransactions implements PlatformTransactionManager {
        int begun;
        int rolledBack;

        @Override
        public TransactionStatus getTransaction(TransactionDefinition definition) {
            begun++;
            return new SimpleTransactionStatus();
        }

        @Override
        public void commit(TransactionStatus status) {
        }

        @Override
        public void rollback(TransactionStatus status) {
            rolledBack++;
        }
    }

    @Test
    void aConcurrentChangeRetriesTheWholeUseCaseInANewTransaction() {
        CountingTransactions tx = new CountingTransactions();
        AtomicInteger calls = new AtomicInteger();
        Action action = new TransactionalUseCaseFactory(tx).wrap(Action.class, () -> {
            if (calls.incrementAndGet() == 1) {
                throw new OptimisticLockingFailureException("changed by another transaction");
            }
            return "ok";
        });

        assertThat(action.run()).isEqualTo("ok");
        assertThat(calls).hasValue(2);
        assertThat(tx.begun).isEqualTo(2);
        assertThat(tx.rolledBack).isEqualTo(1);
    }

    @Test
    void itGivesUpAfterAFewTriesAndOtherErrorsAreNotRetried() {
        CountingTransactions tx = new CountingTransactions();
        AtomicInteger calls = new AtomicInteger();
        Action always = new TransactionalUseCaseFactory(tx).wrap(Action.class, () -> {
            calls.incrementAndGet();
            throw new OptimisticLockingFailureException("always");
        });
        assertThatThrownBy(always::run).isInstanceOf(OptimisticLockingFailureException.class);
        assertThat(calls).hasValue(TransactionalUseCaseFactory.RETRIES + 1);

        AtomicInteger other = new AtomicInteger();
        Action failing = new TransactionalUseCaseFactory(tx).wrap(Action.class, () -> {
            other.incrementAndGet();
            throw new IllegalStateException("not a conflict");
        });
        assertThatThrownBy(failing::run).isInstanceOf(IllegalStateException.class);
        assertThat(other).hasValue(1);
    }
}
