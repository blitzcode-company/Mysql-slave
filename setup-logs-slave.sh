#!/bin/bash
set -e

PROJECT_DIR="/home/Mysql-slave"
LOGS_DIR="${PROJECT_DIR}/mysql-logs"
COMPOSE_FILE="${PROJECT_DIR}/docker-compose.yml"
MYCNF_FILE="${PROJECT_DIR}/my.cnf"

echo "== 1. Creando carpeta de logs =="
mkdir -p "${LOGS_DIR}"

echo "== 2. Ajustando permisos (750, dueno uid 999) =="
chmod 750 "${LOGS_DIR}"
if chown -R 999:999 "${LOGS_DIR}" 2>/dev/null; then
  echo "chown a 999:999 aplicado correctamente."
else
  echo "No se pudo hacer chown (¿no sos root?). La carpeta va a quedar con el dueño actual."
fi

echo "== 3. Verificando volumen de logs en docker-compose.yml =="
if grep -q "mysql-logs:/var/log/mysql" "${COMPOSE_FILE}"; then
  echo "El volumen de logs ya está en ${COMPOSE_FILE}, no se toca."
else
  echo ""
  echo "ATENCION: agregá manualmente esta línea dentro de 'volumes:' del servicio en ${COMPOSE_FILE}:"
  echo "      - ./mysql-logs:/var/log/mysql"
  echo ""
fi

echo "== 4. Verificando my.cnf =="
if grep -q "log-error=/var/log/mysql/error.log" "${MYCNF_FILE}"; then
  echo "my.cnf ya tiene la config de logs, no se toca."
else
  cat >> "${MYCNF_FILE}" << 'INNEREOF'

# Logs persistentes
log-error=/var/log/mysql/error.log
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=2
general_log=0
general_log_file=/var/log/mysql/general.log
INNEREOF
  echo "Se agregaron las líneas de logging a ${MYCNF_FILE}"
fi

echo ""
echo "== LISTO =="
echo "Ahora tenés que:"
echo "1. Confirmar el volumen de logs en tu docker-compose.yml (ver arriba si hizo falta)."
echo "2. Reiniciar el slave:"
echo "     cd ${PROJECT_DIR} && docker compose down && docker compose up -d"
echo "3. Verificar:"
echo "     ls -la ${LOGS_DIR}"
echo "     docker exec -it mysql-slave mysql -uroot -pBlitzcode1. -e \"SHOW VARIABLES LIKE 'log_error';\""
