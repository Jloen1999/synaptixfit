# Contexto del sistema

> Vista C4 de niveles 1 y 2: quién usa SynaptixFit y de qué piezas se compone.

```mermaid
flowchart TB
    U(["Estudiante"]) -->|usa| APP["App SynaptixFit<br/><small>Flutter: Android, iOS, web, escritorio</small>"]
    A(["Administrador"]) -->|panel de administración| APP
    APP -->|"REST /api/v1 · JWT"| API["API SynaptixFit<br/><small>Spring Boot</small>"]
    API -->|JDBC| DB[("PostgreSQL 17")]
    API -->|"chat/completions"| G["DeepSeek<br/><small>resúmenes, tests, rutinas, horarios (solo texto)</small>"]
    API -->|"S3 API, URLs prefirmadas"| R2["Cloudflare R2<br/><small>apuntes en PDF/imagen, vídeos</small>"]
    API -->|"verifica ID token (JWKS)"| GG["Google Identity"]
    APP -->|"sube/descarga con URL prefirmada"| R2
    APP -->|"Google Sign-In"| GG
```

- El cliente **nunca** habla con la base de datos ni con la IA. Con R2 solo usa URLs firmadas por la API y de corta duración.
- La API es la única que conoce secretos (JWT, DeepSeek, R2).
