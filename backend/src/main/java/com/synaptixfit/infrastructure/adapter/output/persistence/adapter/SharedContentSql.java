package com.synaptixfit.infrastructure.adapter.output.persistence.adapter;

import com.synaptixfit.domain.model.shared.AudienceScope;
import com.synaptixfit.domain.model.shared.AuthorAudience;
import com.synaptixfit.domain.model.shared.EffectiveVisibility;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.VisibilityDbMapper;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Filtro SQL estándar del contenido compartido de otros usuarios (apuntes, rutinas y retos) para las
 * consultas paginadas, que tienen que filtrar antes de paginar. La regla vive en
 * {@link EffectiveVisibility}: aquí solo se comparan columnas con los niveles que ella devuelve, que
 * llegan como parámetros. Lee {@code usuarios} (Núcleo) y {@code amistades} (Social).
 *
 * <p>Todas las condiciones usan el parámetro {@code :viewer}, que pone quien llama.
 */
public final class SharedContentSql {

    private static final String FRIEND_LEVELS = "sharedFriendLevels";
    private static final String ANYONE_LEVELS = "sharedAnyoneLevels";

    private SharedContentSql() {
    }

    /**
     * Contenido de otro autor visible para {@code :viewer} en el ámbito.
     *
     * @param visibilityColumn columna con la visibilidad del contenido
     * @param ownerColumn      columna con el id del autor
     * @param userAlias        alias de {@code usuarios} unido al autor
     */
    public static String visible(AudienceScope scope, String visibilityColumn, String ownerColumn, String userAlias) {
        List<String> branches = new ArrayList<>();
        if (!EffectiveVisibility.levelsForFriends(scope).isEmpty()) {
            branches.add("(%s AND %s IN (:%s) AND %s.nivel_privacidad IN (:%s))".formatted(
                    relation(ownerColumn, "aceptada"), visibilityColumn, FRIEND_LEVELS, userAlias, FRIEND_LEVELS));
        }
        if (!EffectiveVisibility.levelsForAnyone(scope).isEmpty()) {
            branches.add("(%s IN (:%s) AND %s.nivel_privacidad IN (:%s))".formatted(
                    visibilityColumn, ANYONE_LEVELS, userAlias, ANYONE_LEVELS));
        }
        return "(%1$s.eliminado_en IS NULL AND %1$s.is_shadowbanned = false AND NOT %2$s AND (%3$s))".formatted(
                userAlias, relation(ownerColumn, "bloqueada"),
                branches.isEmpty() ? "1 = 0" : String.join(" OR ", branches));
    }

    /** Parámetros de {@link #visible} (solo los que usa el ámbito: un {@code IN ()} vacío no es SQL válido). */
    public static Map<String, Object> params(AudienceScope scope) {
        Map<String, Object> params = new HashMap<>();
        Set<Visibility> friends = EffectiveVisibility.levelsForFriends(scope);
        if (!friends.isEmpty()) {
            params.put(FRIEND_LEVELS, toDb(friends));
        }
        Set<Visibility> anyone = EffectiveVisibility.levelsForAnyone(scope);
        if (!anyone.isEmpty()) {
            params.put(ANYONE_LEVELS, toDb(anyone));
        }
        return params;
    }

    /** Valores de BD de unos niveles de visibilidad (para comparar con {@code IN}). */
    public static List<String> toDb(Collection<Visibility> levels) {
        return levels.stream().map(VisibilityDbMapper::toDb).toList();
    }

    /**
     * Columnas que describen al autor visto por {@code :viewer}, para {@link #audience(ResultSet)}:
     * cuenta activa, shadowban, privacidad, amistad aceptada y bloqueo.
     */
    public static String audienceColumns(String ownerColumn, String userAlias) {
        return ("(CASE WHEN %1$s.eliminado_en IS NULL THEN 1 ELSE 0 END) AS autor_activo,"
                + " %1$s.is_shadowbanned AS autor_silenciado, %1$s.nivel_privacidad AS autor_privacidad,"
                + " (CASE WHEN %2$s THEN 1 ELSE 0 END) AS autor_amigo,"
                + " (CASE WHEN %3$s THEN 1 ELSE 0 END) AS autor_bloqueo")
                .formatted(userAlias, relation(ownerColumn, "aceptada"), relation(ownerColumn, "bloqueada"));
    }

    /** Lee las columnas de {@link #audienceColumns}. */
    public static AuthorAudience audience(ResultSet rs) throws SQLException {
        return new AuthorAudience(rs.getInt("autor_activo") == 1, rs.getBoolean("autor_silenciado"),
                VisibilityDbMapper.toDomain(rs.getString("autor_privacidad")), rs.getInt("autor_amigo") == 1,
                rs.getInt("autor_bloqueo") == 1);
    }

    private static String relation(String ownerColumn, String estado) {
        return ("EXISTS (SELECT 1 FROM amistades sc_%2$s WHERE sc_%2$s.estado = '%2$s'"
                + " AND ((sc_%2$s.solicitante_id = :viewer AND sc_%2$s.receptor_id = %1$s)"
                + " OR (sc_%2$s.solicitante_id = %1$s AND sc_%2$s.receptor_id = :viewer)))")
                .formatted(ownerColumn, estado);
    }
}
