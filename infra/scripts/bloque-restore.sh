# >>> volcados PostgreSQL de apps (Coolify standalone-postgresql)
# Restaura cada volcado app-pg-<uuid> en un PostgreSQL 17 desechable y compara
# conteos con producción (historial de Flyway y tablas principales).
for VOLCADO in "$TMP"/volcados/app-pg-*.sql.gz; do
    [[ -e "$VOLCADO" ]] || { echo "Sin volcados PostgreSQL de apps"; break; }
    NOMBRE="$(basename "$VOLCADO" | sed -E 's/^app-pg-(.*)-[0-9]{4}-[0-9]{2}-[0-9]{2}\.sql\.gz$/\1/')"
    echo "== Restaurando PostgreSQL de app ${NOMBRE}"
    docker rm -f im-restore-apppg >/dev/null 2>&1 || true
    docker run --rm -d --name im-restore-apppg \
        -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=prueba -e POSTGRES_DB=app postgres:17-alpine >/dev/null
    for _ in $(seq 1 30); do
        docker exec im-restore-apppg pg_isready -U postgres -d app >/dev/null 2>&1 && break
        sleep 2
    done
    sleep 2
    # El volcado asigna dueños (ALTER ... OWNER TO) a roles que aquí no existen: se crean antes.
    ROLES="$(gunzip -c "$VOLCADO" | { grep -oE 'OWNER TO [a-z_][a-z0-9_]*' || true; } | awk '{print $3}' | sort -u)"
    for ROL in $ROLES; do
        docker exec im-restore-apppg psql -U postgres -d app -q \
            -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='${ROL}') THEN CREATE ROLE ${ROL}; END IF; END \$\$;"
    done
    gunzip -c "$VOLCADO" | docker exec -i im-restore-apppg psql -U postgres -d app -q >/dev/null 2>&1 || true
    CONSULTA="SELECT (SELECT count(*) FROM flyway_schema_history), (SELECT count(*) FROM usuarios), (SELECT count(*) FROM ejercicios), (SELECT count(*) FROM rutinas), (SELECT count(*) FROM asignaturas);"
    RESTAURADO="$(docker exec im-restore-apppg psql -U postgres -d app -At -c "$CONSULTA" 2>&1 | sed 's/ *$//')"
    PRODUCCION="$(docker exec "$NOMBRE" sh -c "psql -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -At -c \"$CONSULTA\"" 2>&1 | sed 's/ *$//')"
    echo "Conteos restaurados ${NOMBRE} (flyway / usuarios / ejercicios / rutinas / asignaturas): $RESTAURADO"
    echo "Conteos produccion  ${NOMBRE}: $PRODUCCION"
    if [[ "$RESTAURADO" == "$PRODUCCION" ]]; then
        echo "  OK: conteos identicos"
    else
        echo "  AVISO: conteos distintos (normal si hubo escrituras desde la copia)"
    fi
    docker rm -f im-restore-apppg >/dev/null 2>&1 || true
done
# <<< volcados PostgreSQL de apps
