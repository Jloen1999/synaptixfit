package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.challenge;

import com.synaptixfit.domain.model.challenge.ChallengeRule;
import com.synaptixfit.domain.model.challenge.ChallengeTemplate;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.RuleMetric;
import com.synaptixfit.domain.model.challenge.RuleUnit;
import com.synaptixfit.domain.port.output.challenge.ChallengeTemplateRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.challenge.ChallengePersistenceMapper;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link ChallengeTemplateRepositoryPort} sobre {@code plantillas_reto} y sus textos (V1062; retiradas con
 * {@code activa}, V1072). Los textos se toman en el idioma pedido y, si faltan, en español.
 */
@Component
public class ChallengeTemplateJdbcAdapter implements ChallengeTemplateRepositoryPort {

    private static final String FALLBACK = "es";

    private final JdbcClient jdbc;

    public ChallengeTemplateJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    private record Head(UUID id, String code, ChallengeType type, Difficulty difficulty, int days, ChallengeRule rule,
                        boolean active) {
    }

    @Override
    public List<ChallengeTemplate> findAll(String language) {
        List<Head> heads = jdbc.sql("SELECT id, codigo, tipo, dificultad, dias, metrica, unidad, por_unidad, objetivo,"
                        + " solo_laborables, activa FROM plantillas_reto ORDER BY orden, codigo")
                .query((rs, n) -> new Head(rs.getObject("id", UUID.class), rs.getString("codigo"),
                        ChallengeType.valueOf(rs.getString("tipo").toUpperCase(Locale.ROOT)),
                        ChallengePersistenceMapper.difficultyToDomain(rs.getString("dificultad")), rs.getInt("dias"),
                        new ChallengeRule(RuleMetric.valueOf(rs.getString("metrica")),
                                RuleUnit.valueOf(rs.getString("unidad")), rs.getInt("por_unidad"),
                                rs.getInt("objetivo"), rs.getBoolean("solo_laborables")), rs.getBoolean("activa")))
                .list();
        if (heads.isEmpty()) {
            return List.of();
        }
        Map<UUID, String[]> texts = new LinkedHashMap<>();
        jdbc.sql("SELECT plantilla_id, idioma, titulo, meta FROM plantillas_reto_textos"
                        + " WHERE idioma IN (:lang, :fallback)")
                .param("lang", language)
                .param("fallback", FALLBACK)
                .query((rs, n) -> {
                    UUID id = rs.getObject("plantilla_id", UUID.class);
                    if (language.equals(rs.getString("idioma")) || !texts.containsKey(id)) {
                        texts.put(id, new String[] {rs.getString("titulo"), rs.getString("meta")});
                    }
                    return null;
                })
                .list();
        return heads.stream()
                .filter(h -> texts.containsKey(h.id()))
                .map(h -> new ChallengeTemplate(h.id(), h.code(), h.type(), h.difficulty(), h.days(), h.rule(),
                        texts.get(h.id())[0], texts.get(h.id())[1], h.active()))
                .toList();
    }

    @Override
    public Optional<ChallengeTemplate> findById(UUID templateId, String language) {
        return findAll(language).stream().filter(t -> t.id().equals(templateId)).findFirst();
    }
}
