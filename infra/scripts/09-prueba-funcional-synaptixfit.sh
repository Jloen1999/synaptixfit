#!/usr/bin/env bash
# Prueba funcional de producción a través de Traefik (como llegaría Cloudflare): registra una
# cuenta de prueba, completa el perfil, registra un Pomodoro, lee el inicio y BORRA la cuenta con
# la propia función RGPD de la app, para no dejar datos de prueba.
#
#   sudo bash 09-prueba-funcional-synaptixfit.sh
set -euo pipefail
HOST=synaptixfit.jloenit.dev
BASE="https://$HOST/api/v1"
C=(curl -sk --resolve "$HOST:443:127.0.0.1" -H 'Content-Type: application/json')
EMAIL="prueba-$(date +%s)@example.com"
PASS="Prueba$(openssl rand -hex 6)1"

json() { python3 -c "import sys,json; d=json.load(sys.stdin); print(eval(sys.argv[1]))" "$1"; }

TOKEN=$("${C[@]}" -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\",\"fullName\":\"Prueba Producción\"}" \
    "$BASE/auth/register" | json 'd["accessToken"]')
AUTH=(-H "Authorization: Bearer $TOKEN")
echo "  OK    registro"
"${C[@]}" "${AUTH[@]}" -X PUT -o /dev/null -w '  %{http_code}   perfil físico\n' "$BASE/profile/wellness" \
    -d '{"age":22,"sex":"FEMALE","weightKg":61,"heightCm":168,"activityLevel":"MODERATE","primaryGoal":"HYPERTROPHY","goals":[],"equipment":[],"availableDays":[1,3,5],"minutesPerSession":45}'
XP=$("${C[@]}" "${AUTH[@]}" -d '{"phase":"FOCUS","durationMinutes":25,"completed":true}' "$BASE/planner/focus-sessions" \
    | json 'd["xpAwarded"]')
echo "  OK    Pomodoro (+$XP XP)"
"${C[@]}" "${AUTH[@]}" "$BASE/dashboard" | json \
    '"  OK    inicio: carga cognitiva %.2f · %d min de estudio · racha %d" % (d["cognitive"]["cognitiveLoad"], d["today"]["studyMinutesCompleted"], d["greeting"]["streak"])'
CODE=$("${C[@]}" "${AUTH[@]}" -X DELETE -o /dev/null -w '%{http_code}' -d "{\"password\":\"$PASS\",\"confirm\":true}" "$BASE/me")
echo "  $CODE   cuenta de prueba borrada (RGPD)"
