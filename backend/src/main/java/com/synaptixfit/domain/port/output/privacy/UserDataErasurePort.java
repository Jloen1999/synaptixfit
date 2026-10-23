package com.synaptixfit.domain.port.output.privacy;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Borrado de los datos de un usuario en todas las tablas (sustituye a las funciones SQL
 * {@code wipe_user_data}, {@code anonymize_user} y {@code delete_user}).
 *
 * <p>Es la única excepción a la regla «cada módulo escribe solo sus tablas»: el derecho de
 * supresión es transversal y debe ser atómico. Todas las operaciones son idempotentes.
 */
public interface UserDataErasurePort {

    /** Claves en el almacenamiento de objetos de los archivos subidos por el usuario. */
    List<String> storedObjectKeys(UUID userId);

    /**
     * Borra el contenido generado por el usuario (entrenamiento, académico, planificador, retos,
     * insignias, social, notificaciones, historiales) y reinicia su estado cognitivo. Conserva la
     * cuenta, los perfiles, las titulaciones y las preferencias.
     *
     * @param at instante del reinicio (fecha de actualización del estado cognitivo); lo pone la
     *           aplicación, no la base de datos
     * @return filas borradas directamente
     */
    int wipeContent(UUID userId, Instant at);

    /**
     * Borra los datos personales y el contenido del usuario. Conserva, asociados a la cuenta ya
     * anónima, los registros estadísticos sin texto libre (sesiones, carga física y académica,
     * bloques, estados neurofisiológicos y check-ins), con sus notas vaciadas.
     *
     * @return filas borradas directamente
     */
    int erasePersonalData(UUID userId);

    /** Elimina la cuenta; el resto de datos se borra en cascada. */
    void deleteAccount(UUID userId);
}
