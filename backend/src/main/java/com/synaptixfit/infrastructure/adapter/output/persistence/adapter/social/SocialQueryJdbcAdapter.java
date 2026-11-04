package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.social;

import com.synaptixfit.domain.model.shared.AudienceScope;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.AuthorSummary;
import com.synaptixfit.domain.model.social.CommentView;
import com.synaptixfit.domain.model.social.FeedQuery;
import com.synaptixfit.domain.model.social.FriendshipListKind;
import com.synaptixfit.domain.model.social.FriendshipRelation;
import com.synaptixfit.domain.model.social.FriendshipStatus;
import com.synaptixfit.domain.model.social.FriendshipView;
import com.synaptixfit.domain.model.social.PostView;
import com.synaptixfit.domain.model.social.PublicBadge;
import com.synaptixfit.domain.model.social.ReportedContent;
import com.synaptixfit.domain.model.social.ReportedContentType;
import com.synaptixfit.domain.model.social.UserCard;
import com.synaptixfit.domain.port.output.social.ReportedContentQueryPort;
import com.synaptixfit.domain.port.output.social.SocialQueryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.SharedContentSql;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.SqlLike;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.VisibilityDbMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.social.SocialPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.badge.BadgePersistenceMapper;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Lecturas compuestas del módulo social con SQL directo: cada página se resuelve en una consulta
 * (contadores y «me gusta» propio como subconsultas correlacionadas, sin N+1). Lee
 * {@code usuarios} (núcleo) solo para nombre, avatar, privacidad y shadowban.
 *
 * <p>La visibilidad del muro usa {@link SharedContentSql} con los niveles de {@code EffectiveVisibility}.
 */
@Repository
public class SocialQueryJdbcAdapter implements SocialQueryPort, ReportedContentQueryPort {

    private static final String POST_COLUMNS = """
            SELECT a.id, a.usuario_id, a.tipo, a.descripcion, a.url_imagen, a.metadata, a.creado_en, a.editado_en,
                   u.nombre_completo, u.url_avatar,
                   (SELECT count(*) FROM interacciones_sociales l WHERE l.actividad_id = a.id) AS likes,
                   (SELECT count(*) FROM comentarios_feed c JOIN usuarios cu ON cu.id = c.usuario_id
                     WHERE c.actividad_id = a.id AND c.eliminado = false AND %s) AS comments,
                   EXISTS (SELECT 1 FROM interacciones_sociales l
                            WHERE l.actividad_id = a.id AND l.usuario_id = :viewer) AS liked
            """.formatted(interactionVisible("c.usuario_id", "cu"));

    private static final String POST_FROM = " FROM actividades_sociales a JOIN usuarios u ON u.id = a.usuario_id ";

    /**
     * Visibilidad de una publicación para :viewer: la regla única de contenido compartido
     * ({@code EffectiveVisibility}) tomando la publicación como contenido público, así que decide la
     * privacidad del perfil del autor (más amistad, shadowban, cuenta eliminada y bloqueo).
     */
    private static final String POST_VISIBLE = "(a.usuario_id = :viewer OR "
            + SharedContentSql.visible(AudienceScope.ALL, ":postVisibility", "a.usuario_id", "u") + ")";

    private static final String COMMENT_COLUMNS = """
            SELECT c.id, c.actividad_id, c.usuario_id, c.texto, c.creado_en, c.editado_en,
                   cu.nombre_completo, cu.url_avatar
              FROM comentarios_feed c JOIN usuarios cu ON cu.id = c.usuario_id
            """;

    private final JdbcClient jdbc;

    public SocialQueryJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    // ---------------------------------------------------------------- muro

    @Override
    public PageResult<PostView> feed(FeedQuery query) {
        Map<String, Object> params = new HashMap<>(SharedContentSql.params(AudienceScope.ALL));
        params.put("viewer", query.viewerId());
        params.put("postVisibility", VisibilityDbMapper.toDb(Visibility.PUBLIC));
        StringBuilder where = new StringBuilder(" WHERE ").append(POST_VISIBLE);
        if (query.authorId() != null) {
            where.append(" AND a.usuario_id = :author");
            params.put("author", query.authorId());
        }
        if (query.from() != null) {
            where.append(" AND a.creado_en >= :from");
            params.put("from", ts(query.from()));
        }
        if (query.since() != null) {
            where.append(" AND a.creado_en > :since");
            params.put("since", ts(query.since()));
        }
        PageRequest page = query.page();
        long total = jdbc.sql("SELECT count(*)" + POST_FROM + where).params(params).query(Long.class).single();
        params.put("limit", page.size());
        params.put("offset", page.offset());
        List<PostView> items = jdbc.sql(POST_COLUMNS + POST_FROM + where
                        + " ORDER BY a.creado_en DESC, a.id DESC LIMIT :limit OFFSET :offset")
                .params(params)
                .query(this::post)
                .list();
        return new PageResult<>(items, page.page(), page.size(), total);
    }

    @Override
    public Optional<PostView> findPost(UUID viewerId, UUID postId) {
        return jdbc.sql(POST_COLUMNS + POST_FROM + " WHERE a.id = :id")
                .param("viewer", viewerId)
                .param("id", postId)
                .query(this::post)
                .optional();
    }

    // ---------------------------------------------------------------- comentarios

    @Override
    public PageResult<CommentView> comments(UUID viewerId, UUID postId, PageRequest page) {
        String where = " WHERE c.actividad_id = :post AND c.eliminado = false AND "
                + interactionVisible("c.usuario_id", "cu");
        long total = jdbc.sql("SELECT count(*) FROM comentarios_feed c JOIN usuarios cu ON cu.id = c.usuario_id"
                        + where)
                .param("viewer", viewerId)
                .param("post", postId)
                .query(Long.class)
                .single();
        List<CommentView> items = jdbc.sql(COMMENT_COLUMNS + where
                        + " ORDER BY c.creado_en ASC, c.id ASC LIMIT :limit OFFSET :offset")
                .param("viewer", viewerId)
                .param("post", postId)
                .param("limit", page.size())
                .param("offset", page.offset())
                .query(this::comment)
                .list();
        return new PageResult<>(items, page.page(), page.size(), total);
    }

    @Override
    public Optional<CommentView> findComment(UUID commentId) {
        return jdbc.sql(COMMENT_COLUMNS + " WHERE c.id = :id AND c.eliminado = false")
                .param("id", commentId)
                .query(this::comment)
                .optional();
    }

    // ---------------------------------------------------------------- usuarios y amistades

    /**
     * Excluye: a uno mismo, cuentas eliminadas, shadowban, cualquier bloqueo entre ambos y perfiles
     * privados (salvo que ya exista una solicitud o amistad).
     */
    @Override
    public PageResult<UserCard> searchUsers(UUID viewerId, String term, PageRequest page) {
        String from = """
                 FROM usuarios u
                 LEFT JOIN LATERAL (
                     SELECT x.id, x.estado, x.solicitante_id FROM amistades x
                      WHERE (x.solicitante_id = :viewer AND x.receptor_id = u.id)
                         OR (x.solicitante_id = u.id AND x.receptor_id = :viewer)
                      ORDER BY x.actualizado_en DESC LIMIT 1) f ON true
                WHERE u.id <> :viewer AND u.eliminado_en IS NULL AND u.is_shadowbanned = false
                  AND %s
                  AND (f.estado IS NULL OR f.estado <> 'bloqueada')
                  AND (u.nivel_privacidad <> 'private' OR f.estado IN ('pendiente', 'aceptada'))
                """.formatted(SqlLike.containsIgnoreCase("u.nombre_completo", "pattern"));
        String pattern = SqlLike.contains(term);
        long total = jdbc.sql("SELECT count(*)" + from)
                .param("viewer", viewerId)
                .param("pattern", pattern)
                .query(Long.class)
                .single();
        List<UserCard> items = jdbc.sql("SELECT u.id, u.nombre_completo, u.url_avatar, u.nivel,"
                        + " f.id AS fid, f.estado, f.solicitante_id" + from
                        + " ORDER BY lower(u.nombre_completo), u.id LIMIT :limit OFFSET :offset")
                .param("viewer", viewerId)
                .param("pattern", pattern)
                .param("limit", page.size())
                .param("offset", page.offset())
                .query((rs, n) -> {
                    String estado = rs.getString("estado");
                    FriendshipRelation relation = FriendshipRelation.of(viewerId,
                            estado == null ? null : SocialPersistenceMapper.statusFromDb(estado),
                            rs.getObject("solicitante_id", UUID.class));
                    UUID friendshipId = relation == FriendshipRelation.NONE ? null : rs.getObject("fid", UUID.class);
                    return new UserCard(rs.getObject("id", UUID.class), rs.getString("nombre_completo"),
                            rs.getString("url_avatar"), rs.getInt("nivel"), relation, friendshipId);
                })
                .list();
        return new PageResult<>(items, page.page(), page.size(), total);
    }

    @Override
    public PageResult<FriendshipView> friendships(UUID viewerId, FriendshipListKind kind, PageRequest page) {
        String condition = switch (kind) {
            case FRIENDS -> "f.estado = 'aceptada' AND (f.solicitante_id = :viewer OR f.receptor_id = :viewer)";
            case RECEIVED -> "f.estado = 'pendiente' AND f.receptor_id = :viewer AND u.is_shadowbanned = false";
            case SENT -> "f.estado = 'pendiente' AND f.solicitante_id = :viewer";
            case BLOCKED -> "f.estado = 'bloqueada' AND f.solicitante_id = :viewer";
        };
        String from = """
                 FROM amistades f
                 JOIN usuarios u ON u.id = CASE WHEN f.solicitante_id = :viewer THEN f.receptor_id
                                                ELSE f.solicitante_id END
                WHERE u.eliminado_en IS NULL AND\s""" + condition;
        long total = jdbc.sql("SELECT count(*)" + from).param("viewer", viewerId).query(Long.class).single();
        List<FriendshipView> items = jdbc.sql("""
                        SELECT f.id, f.estado, f.solicitante_id, f.creado_en, f.actualizado_en,
                               u.id AS uid, u.nombre_completo, u.url_avatar, u.nivel""" + from
                        + " ORDER BY f.actualizado_en DESC, f.id LIMIT :limit OFFSET :offset")
                .param("viewer", viewerId)
                .param("limit", page.size())
                .param("offset", page.offset())
                .query((rs, n) -> {
                    FriendshipStatus status = SocialPersistenceMapper.statusFromDb(rs.getString("estado"));
                    return new FriendshipView(rs.getObject("id", UUID.class), status,
                            FriendshipRelation.of(viewerId, status, rs.getObject("solicitante_id", UUID.class)),
                            rs.getObject("uid", UUID.class), rs.getString("nombre_completo"),
                            rs.getString("url_avatar"), rs.getInt("nivel"), instant(rs, "creado_en"),
                            instant(rs, "actualizado_en"));
                })
                .list();
        return new PageResult<>(items, page.page(), page.size(), total);
    }

    @Override
    public long countPosts(UUID authorId) {
        return jdbc.sql("SELECT count(*) FROM actividades_sociales WHERE usuario_id = :author")
                .param("author", authorId)
                .query(Long.class)
                .single();
    }

    @Override
    public long countFriends(UUID userId) {
        return jdbc.sql("""
                        SELECT count(*) FROM amistades f
                          JOIN usuarios u ON u.id = CASE WHEN f.solicitante_id = :user THEN f.receptor_id
                                                         ELSE f.solicitante_id END
                         WHERE f.estado = 'aceptada' AND (f.solicitante_id = :user OR f.receptor_id = :user)
                           AND u.eliminado_en IS NULL
                        """)
                .param("user", userId)
                .query(Long.class)
                .single();
    }

    /** Lee {@code usuario_insignias} e {@code insignias} (gamificación) solo para mostrarlas. */
    @Override
    public List<PublicBadge> visibleBadges(UUID userId) {
        return jdbc.sql("""
                        SELECT i.id, i.nombre, i.descripcion, i.icono, i.rareza, ui.obtenida_en
                          FROM usuario_insignias ui JOIN insignias i ON i.id = ui.insignia_id
                         WHERE ui.usuario_id = :user AND ui.visible = true
                        """)
                .param("user", userId)
                .query((rs, n) -> new PublicBadge(rs.getObject("id", UUID.class), rs.getString("nombre"),
                        rs.getString("descripcion"), rs.getString("icono"), BadgePersistenceMapper.rarity(rs.getString("rareza")),
                        rs.getTimestamp("obtenida_en").toInstant()))
                .list();
    }

    // ---------------------------------------------------------------- moderación

    @Override
    public PageResult<ReportedContent> findReported(ReportedContentType type, PageRequest page) {
        List<String> branches = new ArrayList<>();
        if (type == null || type == ReportedContentType.POST) {
            branches.add("""
                    SELECT 'POST' AS kind, a.id, a.id AS post_id, a.usuario_id, u.nombre_completo,
                           a.descripcion AS contenido, a.reportado_por, a.creado_en
                      FROM actividades_sociales a JOIN usuarios u ON u.id = a.usuario_id
                     WHERE a.reportado = true
                    """);
        }
        if (type == null || type == ReportedContentType.COMMENT) {
            branches.add("""
                    SELECT 'COMMENT' AS kind, c.id, c.actividad_id AS post_id, c.usuario_id, u.nombre_completo,
                           c.texto AS contenido, c.reportado_por, c.creado_en
                      FROM comentarios_feed c JOIN usuarios u ON u.id = c.usuario_id
                     WHERE c.reportado = true AND c.eliminado = false
                    """);
        }
        String union = "(" + String.join(" UNION ALL ", branches) + ") r";
        long total = jdbc.sql("SELECT count(*) FROM " + union).query(Long.class).single();
        List<ReportedContent> items = jdbc.sql("SELECT * FROM " + union
                        + " ORDER BY r.creado_en DESC, r.id LIMIT :limit OFFSET :offset")
                .param("limit", page.size())
                .param("offset", page.offset())
                .query((rs, n) -> new ReportedContent(ReportedContentType.valueOf(rs.getString("kind")),
                        rs.getObject("id", UUID.class), rs.getObject("post_id", UUID.class),
                        rs.getObject("usuario_id", UUID.class), rs.getString("nombre_completo"),
                        rs.getString("contenido"), rs.getObject("reportado_por", UUID.class),
                        instant(rs, "creado_en")))
                .list();
        return new PageResult<>(items, page.page(), page.size(), total);
    }

    // ---------------------------------------------------------------- utilidades

    private PostView post(ResultSet rs, int rowNum) throws SQLException {
        return new PostView(rs.getObject("id", UUID.class),
                new AuthorSummary(rs.getObject("usuario_id", UUID.class), rs.getString("nombre_completo"),
                        rs.getString("url_avatar")),
                SocialPersistenceMapper.postTypeFromDb(rs.getString("tipo")), rs.getString("descripcion"),
                rs.getString("url_imagen"), rs.getString("metadata"), instant(rs, "creado_en"),
                instant(rs, "editado_en"), rs.getLong("likes"), rs.getLong("comments"), rs.getBoolean("liked"));
    }

    private CommentView comment(ResultSet rs, int rowNum) throws SQLException {
        return new CommentView(rs.getObject("id", UUID.class), rs.getObject("actividad_id", UUID.class),
                new AuthorSummary(rs.getObject("usuario_id", UUID.class), rs.getString("nombre_completo"),
                        rs.getString("url_avatar")),
                rs.getString("texto"), instant(rs, "creado_en"), instant(rs, "editado_en"));
    }

    /** Existe una relación con el estado dado entre :viewer y {@code otherColumn} (en cualquier sentido). */
    private static String relation(String otherColumn, String estado) {
        return """
                EXISTS (SELECT 1 FROM amistades r WHERE r.estado = '%2$s'
                         AND ((r.solicitante_id = :viewer AND r.receptor_id = %1$s)
                           OR (r.solicitante_id = %1$s AND r.receptor_id = :viewer)))
                """.formatted(otherColumn, estado);
    }

    /** Interacciones visibles: propias, o de usuarios activos sin shadowban y sin bloqueo con :viewer. */
    private static String interactionVisible(String userColumn, String userAlias) {
        return "(%1$s = :viewer OR (%2$s.eliminado_en IS NULL AND %2$s.is_shadowbanned = false AND NOT %3$s))"
                .formatted(userColumn, userAlias, relation(userColumn, "bloqueada"));
    }


    private static Timestamp ts(Instant instant) {
        return Timestamp.from(instant);
    }

    private static Instant instant(ResultSet rs, String column) throws SQLException {
        Timestamp value = rs.getTimestamp(column);
        return value == null ? null : value.toInstant();
    }
}
