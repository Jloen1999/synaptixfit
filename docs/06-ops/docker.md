# Docker

`docker-compose.yml` (raíz) define:

| Servicio | Imagen | Puerto | Notas |
|---|---|---|---|
| `db` | `postgres:17-alpine` | 5432 | Volumen `pgdata`; usuario, contraseña y base `synaptixfit` |
| `backend` | `backend/Dockerfile` | 8080 | Lee `backend/.env`; espera a que `db` esté sana |

```bash
docker compose up -d db              # solo la base de datos (desarrollo con ./mvnw spring-boot:run)
docker compose up -d --build         # base de datos + backend
docker compose logs -f backend
docker compose down                  # añade -v para borrar los datos
```

El `Dockerfile` del backend compila con JDK 21 y ejecuta con JRE 21 como usuario sin privilegios.

## Producción

- Define todos los secretos como variables de entorno (`JWT_SECRET` obligatorio, `DEEPSEEK_API_KEY`, credenciales de R2, `GOOGLE_CLIENT_IDS`, `CORS_ALLOWED_ORIGINS` con el dominio real).
- Usa un PostgreSQL gestionado con copias de seguridad; Flyway migra al arrancar.
- Expón solo el puerto 8080 detrás de un proxy con TLS.
