#!/bin/bash
set -e

# CORRER EN EL SLAVE (192.168.1.106)
PROJECT_DIR="/home/mysql-slave"
SSL_DIR="${PROJECT_DIR}/mysql/ssl"
COMPOSE_FILE="${PROJECT_DIR}/docker-compose.yml"
MYCNF_FILE="${PROJECT_DIR}/my.cnf"

if [ ! -f "${SSL_DIR}/ca.pem" ] || [ ! -f "${SSL_DIR}/ca-key.pem" ]; then
  echo "ERROR: no encuentro ca.pem / ca-key.pem en ${SSL_DIR}."
  echo "Corré primero 02-copy-certs-to-slave.sh desde el master."
  exit 1
fi

echo "== 1. Generando certificado de servidor del SLAVE =="
cd "${SSL_DIR}"

if [ -f server-cert.pem ]; then
  echo "Ya existe server-cert.pem del slave, se omite."
else
  openssl req -newkey rsa:2048 -days 3650 -nodes -keyout server-key.pem -out server-req.pem -subj "/CN=mysql-slave"
  openssl rsa -in server-key.pem -out server-key.pem
  openssl x509 -req -in server-req.pem -days 3650 -CA ca.pem -CAkey ca-key.pem -set_serial 03 -out server-cert.pem
fi

echo "== 2. Ajustando permisos =="
chmod 644 *.pem
chmod 640 *-key.pem
cd - > /dev/null

echo "== 3. Verificando volumen SSL en docker-compose.yml =="
if grep -q "mysql/ssl:/etc/mysql/ssl" "${COMPOSE_FILE}"; then
  echo "El volumen SSL ya está en ${COMPOSE_FILE}, no se toca."
else
  echo ""
  echo "ATENCION: agregá manualmente esta línea dentro de 'volumes:' del servicio en ${COMPOSE_FILE}:"
  echo "      - ./mysql/ssl:/etc/mysql/ssl:ro"
  echo ""
fi

echo "== 4. Verificando my.cnf =="
if grep -q "ssl-ca=/etc/mysql/ssl/ca.pem" "${MYCNF_FILE}"; then
  echo "my.cnf ya tiene la config SSL, no se toca."
else
  cat >> "${MYCNF_FILE}" << 'INNEREOF'

ssl-ca=/etc/mysql/ssl/ca.pem
ssl-cert=/etc/mysql/ssl/server-cert.pem
ssl-key=/etc/mysql/ssl/server-key.pem
INNEREOF
  echo "Se agregaron las líneas SSL a ${MYCNF_FILE}"
fi

echo ""
echo "== LISTO =="
echo "Ahora tenés que:"
echo "1. Confirmar el volumen SSL en tu docker-compose.yml (ver arriba si hizo falta)."
echo "2. Reiniciar el slave:"
echo "     cd ${PROJECT_DIR} && docker compose down && docker compose up -d"
echo "3. Volver al MASTER y correr 04-master-repl-user.sh"
