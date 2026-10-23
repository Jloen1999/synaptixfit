# >>> volcados PostgreSQL de apps (Coolify standalone-postgresql)
# Un volcado por recurso (nombre = uuid del recurso). Usa el superusuario del propio
# contenedor (sus variables de entorno): ninguna contraseña en argv ni en el script.
for APP_PG in $(docker ps -q --filter "status=running" \
        --filter 'label=coolify.type=database' \
        --filter 'label=coolify.database.subType=standalone-postgresql'); do
    APP_PG_NOMBRE="$(docker inspect -f '{{.Name}}' "$APP_PG" | tr -d '/')"
    log "Volcando PostgreSQL de app ${APP_PG_NOMBRE}"
    docker exec "$APP_PG" sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists' \
        | gzip > "$STAGING/app-pg-${APP_PG_NOMBRE}-${FECHA}.sql.gz" \
        || morir "fallo el pg_dump de ${APP_PG_NOMBRE}"
    log "  $(du -h "$STAGING/app-pg-${APP_PG_NOMBRE}-${FECHA}.sql.gz" | cut -f1) comprimido"
done
# <<< volcados PostgreSQL de apps
