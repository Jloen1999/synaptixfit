package com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Tabla {@code historial_peso}. */
@Entity
@Table(name = "historial_peso")
public class WeightHistoryEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID usuarioId;
    @Column(name = "peso_kg", nullable = false)
    private double pesoKg;
    @Column(name = "altura_cm", nullable = false)
    private double alturaCm;
    @Column(name = "imc", nullable = false)
    private double imc;
    @Column(name = "registrado_en", nullable = false)
    private Instant registradoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public double getPesoKg() { return pesoKg; }
    public void setPesoKg(double pesoKg) { this.pesoKg = pesoKg; }
    public double getAlturaCm() { return alturaCm; }
    public void setAlturaCm(double alturaCm) { this.alturaCm = alturaCm; }
    public double getImc() { return imc; }
    public void setImc(double imc) { this.imc = imc; }
    public Instant getRegistradoEn() { return registradoEn; }
    public void setRegistradoEn(Instant registradoEn) { this.registradoEn = registradoEn; }
}
