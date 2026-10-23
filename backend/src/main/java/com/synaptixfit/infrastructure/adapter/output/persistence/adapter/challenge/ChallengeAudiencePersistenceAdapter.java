package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.challenge;

import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.OwnerAudience;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.challenge.ChallengeAudiencePort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.SqlLike;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Visibilidad de retos ajenos: lee {@code usuarios} (Núcleo) y {@code amistades} (Social). Para un reto
 * concreto solo trae los datos ({@link OwnerAudience}) y decide {@code Challenge.isVisibleTo}; el
 * listado paginado replica esa regla en SQL estándar porque hay que filtrar antes de paginar.
 */
@Repository
public class ChallengeAudiencePersistenceAdapter implements ChallengeAudiencePort {

    /** Autor visible (no silenciado ni eliminado) y reto público o de un amigo con amistad aceptada. */
    private static final String VISIBLE = """
             u.is_shadowbanned = false and u.eliminado_en is null
             and (r.visibilidad = 'public'
                  or (r.visibilidad = 'friends' and exists (
                        select 1 from amistades a where a.estado = 'aceptada'
                          and ((a.solicitante_id = :viewer and a.receptor_id = r.usuario_id)
                               or (a.receptor_id = :viewer and a.solicitante_id = r.usuario_id)))))
            """;

    private final JdbcClient jdbc;

    public ChallengeAudiencePersistenceAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public PageResult<CommunityEntry> findCommunity(UUID viewerId, ChallengeType type, String text, PageRequest page,
                                                    Instant now) {
        StringBuilder where = new StringBuilder("""
                 from retos r join usuarios u on u.id = r.usuario_id
                 where r.usuario_id <> :viewer and r.esta_completado = false and r.fecha_fin >= :now and
                """).append(VISIBLE);
        Map<String, Object> params = new HashMap<>();
        params.put("viewer", viewerId);
        params.put("now", OffsetDateTime.ofInstant(now, ZoneOffset.UTC));
        if (type != null) {
            where.append(" and r.tipo = :type");
            params.put("type", type.name().toLowerCase(Locale.ROOT));
        }
        if (text != null) {
            where.append(" and ").append(SqlLike.containsIgnoreCase("r.titulo", "text"));
            params.put("text", SqlLike.contains(text));
        }
        long total = jdbc.sql("select count(*)" + where).params(params).query(Long.class).single();
        params.put("limit", page.size());
        params.put("offset", page.offset());
        List<CommunityEntry> items = jdbc.sql("select r.id, u.nombre_completo" + where
                        + " order by r.fecha_fin asc, r.id limit :limit offset :offset")
                .params(params)
                .query((rs, n) -> new CommunityEntry(rs.getObject("id", UUID.class), rs.getString("nombre_completo")))
                .list();
        return new PageResult<>(items, page.page(), page.size(), total);
    }

    @Override
    public OwnerAudience audienceOf(UUID viewerId, UUID ownerId) {
        boolean friends = jdbc.sql("""
                        select count(*) from amistades a where a.estado = 'aceptada'
                          and ((a.solicitante_id = :viewer and a.receptor_id = :owner)
                               or (a.receptor_id = :viewer and a.solicitante_id = :owner))
                        """)
                .param("viewer", viewerId)
                .param("owner", ownerId)
                .query(Long.class).single() > 0;
        return jdbc.sql("select eliminado_en, is_shadowbanned from usuarios where id = :owner")
                .param("owner", ownerId)
                .query((rs, n) -> new OwnerAudience(rs.getObject("eliminado_en") == null,
                        rs.getBoolean("is_shadowbanned"), friends))
                .optional()
                .orElse(new OwnerAudience(false, false, friends));
    }
}
