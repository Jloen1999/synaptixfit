package com.synaptixfit.infrastructure.config;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Proxy;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Envuelve un caso de uso en una transacción sin que la capa de aplicación conozca Spring.
 *
 * <p>Se usa desde las clases {@code *BeanConfiguration}: cada llamada a un método del contrato
 * se ejecuta dentro de una transacción; una excepción no comprobada provoca rollback.
 *
 * <p>Si otra transacción cambió a la vez una fila con versión (bloqueo optimista, p. ej. la sesión que pausó otra
 * persona del entreno juntos, ADR 0047), el caso de uso se repite entero hasta {@value #RETRIES} veces, solo en la
 * transacción de fuera: la nueva vuelta lee lo ya confirmado. Los casos de uso son idempotentes o leen de nuevo, y
 * los eventos de la vuelta fallida se deshicieron con ella.
 *
 * <pre>{@code
 * @Bean
 * GetRoutinesUseCase getRoutinesUseCase(RoutineRepositoryPort port) {
 *     return tx.wrap(GetRoutinesUseCase.class, new RoutineService(port));
 * }
 * }</pre>
 */
@Component
public class TransactionalUseCaseFactory {

    static final int RETRIES = 2;

    private final TransactionTemplate template;

    public TransactionalUseCaseFactory(PlatformTransactionManager transactionManager) {
        this.template = new TransactionTemplate(transactionManager);
    }

    @SuppressWarnings("unchecked")
    public <T> T wrap(Class<T> contract, T target) {
        InvocationHandler handler = (proxy, method, args) -> {
            if (method.getDeclaringClass() == Object.class) {
                return method.invoke(target, args);
            }
            boolean outermost = !TransactionSynchronizationManager.isActualTransactionActive();
            for (int attempt = 0; ; attempt++) {
                try {
                    return template.execute(status -> {
                        try {
                            return method.invoke(target, args);
                        } catch (InvocationTargetException e) {
                            throw new UnwrappedException(e.getCause());
                        } catch (IllegalAccessException e) {
                            throw new IllegalStateException(e);
                        }
                    });
                } catch (UnwrappedException e) {
                    if (!(outermost && attempt < RETRIES && e.getCause() instanceof OptimisticLockingFailureException)) {
                        throw e.getCause();
                    }
                } catch (OptimisticLockingFailureException e) {
                    // Al confirmar: la vuelta se deshizo entera.
                    if (!(outermost && attempt < RETRIES)) {
                        throw e;
                    }
                }
            }
        };
        return (T) Proxy.newProxyInstance(contract.getClassLoader(), new Class<?>[]{contract}, handler);
    }

    /** Transporta la excepción original a través de TransactionTemplate (que marca rollback). */
    private static final class UnwrappedException extends RuntimeException {
        UnwrappedException(Throwable cause) {
            super(null, cause, false, false);
        }
    }
}
