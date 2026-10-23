package com.synaptixfit.infrastructure.config;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Proxy;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Envuelve un caso de uso en una transacción sin que la capa de aplicación conozca Spring.
 *
 * <p>Se usa desde las clases {@code *BeanConfiguration}: cada llamada a un método del contrato
 * se ejecuta dentro de una transacción; una excepción no comprobada provoca rollback.
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
                throw e.getCause();
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
