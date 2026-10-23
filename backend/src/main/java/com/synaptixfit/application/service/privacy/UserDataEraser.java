package com.synaptixfit.application.service.privacy;

import com.synaptixfit.domain.event.privacy.UserDataErased;
import com.synaptixfit.domain.model.privacy.ErasureMode;
import com.synaptixfit.domain.model.privacy.ErasureReport;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.privacy.UserDataErasurePort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import java.lang.System.Logger.Level;
import java.time.Clock;
import java.util.List;
import java.util.UUID;
import java.util.function.IntSupplier;

/**
 * Procedimiento común de borrado de datos de un usuario, compartido por el panel de
 * administración y la baja voluntaria.
 *
 * <p>Orden: se leen las claves de los archivos en R2, se borran los datos en la base de datos y,
 * por último, los objetos de R2 con mejor esfuerzo: un fallo del almacenamiento se registra y se
 * cuenta en el informe, pero no bloquea el borrado (los datos personales en la base de datos son
 * lo prioritario y los objetos huérfanos se pueden purgar después).
 */
public class UserDataEraser {

    private static final System.Logger LOG = System.getLogger(UserDataEraser.class.getName());

    private final UserDataErasurePort erasure;
    private final FileStoragePort storage;
    private final DomainEventPublisherPort events;
    private final Clock clock;

    public UserDataEraser(UserDataErasurePort erasure, FileStoragePort storage, DomainEventPublisherPort events,
                          Clock clock) {
        this.erasure = erasure;
        this.storage = storage;
        this.events = events;
        this.clock = clock;
    }

    public ErasureReport wipeContent(UUID userId) {
        return run(userId, ErasureMode.CONTENT_WIPED, () -> erasure.wipeContent(userId, clock.instant()));
    }

    public ErasureReport erasePersonalData(UUID userId) {
        return run(userId, ErasureMode.ANONYMIZED, () -> erasure.erasePersonalData(userId));
    }

    public ErasureReport deleteAccount(UUID userId) {
        return run(userId, ErasureMode.DELETED, () -> {
            erasure.deleteAccount(userId);
            return 1;
        });
    }

    private ErasureReport run(UUID userId, ErasureMode mode, IntSupplier eraseRows) {
        List<String> objectKeys = erasure.storedObjectKeys(userId);
        int deletedRows = eraseRows.getAsInt();
        int failed = deleteObjects(userId, objectKeys);
        events.publish(new UserDataErased(userId, mode, clock.instant()));
        return new ErasureReport(userId, mode, deletedRows, objectKeys.size(), failed);
    }

    private int deleteObjects(UUID userId, List<String> objectKeys) {
        int failed = 0;
        for (String key : objectKeys) {
            try {
                storage.delete(key);
            } catch (RuntimeException e) {
                failed++;
                LOG.log(Level.WARNING, "Could not delete stored object {0} of user {1}: {2}",
                        key, userId, e.getMessage());
            }
        }
        return failed;
    }
}
