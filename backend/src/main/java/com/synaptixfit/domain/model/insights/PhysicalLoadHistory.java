package com.synaptixfit.domain.model.insights;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Agregados de la carga física (sumas por día y máximo diario) calculados en Java con la fórmula de
 * {@link PhysicalLoadRecord#load(int, int)}. Los puertos solo devuelven las filas ({@link Entry}) y los
 * casos de uso aplican estas reglas: la columna generada {@code carga_diaria} queda como copia
 * informativa y la aplicación no depende de que el motor la calcule (ADR 0012).
 */
public final class PhysicalLoadHistory {

    private PhysicalLoadHistory() {
    }

    /** Fila de carga tal como está guardada (sin validar: el histórico puede traer valores heredados). */
    public record Entry(LocalDate date, int rpe, int durationMinutes) {

        public double load() {
            return PhysicalLoadRecord.load(rpe, durationMinutes);
        }
    }

    /** Carga total por día (solo los días con registros), en orden ascendente de fecha. */
    public static List<DailyLoad> dailyLoads(Collection<Entry> entries) {
        Map<LocalDate, Double> byDay = new TreeMap<>();
        for (Entry e : entries) {
            byDay.merge(e.date(), e.load(), Double::sum);
        }
        return byDay.entrySet().stream().map(e -> new DailyLoad(e.getKey(), e.getValue())).toList();
    }

    /** Suma de la carga de todas las filas. */
    public static double total(Collection<Entry> entries) {
        return entries.stream().mapToDouble(Entry::load).sum();
    }

    /** Suma de la carga entre dos fechas, ambas incluidas. */
    public static double total(Collection<Entry> entries, LocalDate from, LocalDate to) {
        return entries.stream().filter(e -> !e.date().isBefore(from) && !e.date().isAfter(to))
                .mapToDouble(Entry::load).sum();
    }

    /** Máxima carga diaria (suma de un día); 0 si no hay filas. */
    public static double maxDailyLoad(Collection<Entry> entries) {
        return dailyLoads(entries).stream().mapToDouble(DailyLoad::load).max().orElse(0);
    }
}
