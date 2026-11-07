package com.synaptixfit.infrastructure.adapter.output.persistence.adapter;

import java.util.Locale;

/**
 * Búsqueda de texto con {@code LIKE} en SQL estándar, compartida por los adaptadores JdbcClient.
 * Sustituye a {@code ILIKE} (solo PostgreSQL) por {@code lower(col) LIKE :patron} y usa {@code '!'}
 * como carácter de escape explícito, porque la barra invertida se interpreta distinto en
 * PostgreSQL y en MySQL.
 */
public final class SqlLike {

    /** Cláusula de escape que acompaña a cada {@code LIKE} con un patrón de {@link #contains(String)}. */
    public static final String ESCAPE = "ESCAPE '!'";

    private SqlLike() {
    }

    /** Condición «la columna contiene el parámetro», sin distinguir mayúsculas. */
    public static String containsIgnoreCase(String column, String param) {
        return "lower(" + column + ") LIKE :" + param + " " + ESCAPE;
    }

    /**
     * Vocales con tilde o diéresis, eñe y cedilla (también en mayúscula, por si {@code lower} no las baja con el
     * locale de la base de datos) y su forma sin marca, en el mismo orden.
     */
    private static final String ACCENTED = "áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ";
    private static final String PLAIN = "aaaaaeeeeiiiiooooouuuuncaaaaaeeeeiiiiooooouuuunc";

    /**
     * Condición «la columna contiene el parámetro» sin distinguir mayúsculas ni tildes: el parámetro llega plegado
     * ({@code AcademicSearch.fold}) y la columna se pliega con {@code translate}, que tienen PostgreSQL y Oracle (ver
     * {@code docs/06-ops/database_portability.md}).
     */
    public static String containsFolded(String column, String param) {
        return "translate(lower(" + column + "), '" + ACCENTED + "', '" + PLAIN + "') LIKE :" + param + " " + ESCAPE;
    }

    /** Patrón «contiene» en minúsculas y con los comodines del texto escapados. */
    public static String contains(String text) {
        return "%" + escape(text.toLowerCase(Locale.ROOT)) + "%";
    }

    static String escape(String text) {
        return text.replace("!", "!!").replace("%", "!%").replace("_", "!_");
    }
}
