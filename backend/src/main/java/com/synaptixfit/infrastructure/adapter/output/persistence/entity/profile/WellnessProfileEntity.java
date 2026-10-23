package com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** Tabla {@code perfil_bienestar_usuario}. */
@Entity
@Table(name = "perfil_bienestar_usuario")
public class WellnessProfileEntity {

    @Id
    private UUID id;
    @Column(name = "usuario_id", nullable = false, updatable = false)
    private UUID usuarioId;
    @Column(name = "edad", nullable = false)
    private int edad;
    @Column(name = "sexo", nullable = false)
    private String sexo;
    @Column(name = "ciudad")
    private String ciudad;
    @Column(name = "peso_kg", nullable = false)
    private double pesoKg;
    @Column(name = "altura_cm", nullable = false)
    private double alturaCm;
    @Column(name = "imc", nullable = false)
    private double imc;
    @Column(name = "nivel_actividad", nullable = false)
    private String nivelActividad;
    @Column(name = "objetivo_principal", nullable = false)
    private String objetivoPrincipal;
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "objetivos", nullable = false)
    private String[] objetivos;
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "equipamiento_disponible", nullable = false)
    private String[] equipamientoDisponible;
    @Column(name = "dias_disponibles_semana", nullable = false)
    private int diasDisponiblesSemana;
    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "dias_disponibles")
    private List<Integer> diasDisponibles;
    @Column(name = "minutos_por_sesion", nullable = false)
    private int minutosPorSesion;
    @Column(name = "onboarding_completado", nullable = false)
    private boolean onboardingCompletado;
    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;
    @Column(name = "actualizado_en", nullable = false)
    private Instant actualizadoEn;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getUsuarioId() { return usuarioId; }
    public void setUsuarioId(UUID usuarioId) { this.usuarioId = usuarioId; }
    public int getEdad() { return edad; }
    public void setEdad(int edad) { this.edad = edad; }
    public String getSexo() { return sexo; }
    public void setSexo(String sexo) { this.sexo = sexo; }
    public String getCiudad() { return ciudad; }
    public void setCiudad(String ciudad) { this.ciudad = ciudad; }
    public double getPesoKg() { return pesoKg; }
    public void setPesoKg(double pesoKg) { this.pesoKg = pesoKg; }
    public double getAlturaCm() { return alturaCm; }
    public void setAlturaCm(double alturaCm) { this.alturaCm = alturaCm; }
    public double getImc() { return imc; }
    public void setImc(double imc) { this.imc = imc; }
    public String getNivelActividad() { return nivelActividad; }
    public void setNivelActividad(String nivelActividad) { this.nivelActividad = nivelActividad; }
    public String getObjetivoPrincipal() { return objetivoPrincipal; }
    public void setObjetivoPrincipal(String objetivoPrincipal) { this.objetivoPrincipal = objetivoPrincipal; }
    public List<String> getObjetivos() { return objetivos == null ? null : List.of(objetivos); }
    public void setObjetivos(List<String> objetivos) { this.objetivos = objetivos == null ? null : objetivos.toArray(String[]::new); }
    public List<String> getEquipamientoDisponible() { return equipamientoDisponible == null ? null : List.of(equipamientoDisponible); }
    public void setEquipamientoDisponible(List<String> equipamientoDisponible) { this.equipamientoDisponible = equipamientoDisponible == null ? null : equipamientoDisponible.toArray(String[]::new); }
    public int getDiasDisponiblesSemana() { return diasDisponiblesSemana; }
    public void setDiasDisponiblesSemana(int diasDisponiblesSemana) { this.diasDisponiblesSemana = diasDisponiblesSemana; }
    public List<Integer> getDiasDisponibles() { return diasDisponibles; }
    public void setDiasDisponibles(List<Integer> diasDisponibles) { this.diasDisponibles = diasDisponibles; }
    public int getMinutosPorSesion() { return minutosPorSesion; }
    public void setMinutosPorSesion(int minutosPorSesion) { this.minutosPorSesion = minutosPorSesion; }
    public boolean isOnboardingCompletado() { return onboardingCompletado; }
    public void setOnboardingCompletado(boolean onboardingCompletado) { this.onboardingCompletado = onboardingCompletado; }
    public Instant getCreadoEn() { return creadoEn; }
    public void setCreadoEn(Instant creadoEn) { this.creadoEn = creadoEn; }
    public Instant getActualizadoEn() { return actualizadoEn; }
    public void setActualizadoEn(Instant actualizadoEn) { this.actualizadoEn = actualizadoEn; }
}
