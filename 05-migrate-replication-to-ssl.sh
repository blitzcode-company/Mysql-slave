#!/bin/bash
set -e

# CORRER EN EL SLAVE (192.168.1.106)
CONTAINER_NAME="mysql-slave"
ROOT_PASSWORD="Blitzcode1."
REPL_USER="repl"
REPL_PASSWORD="Blitzcode1."

echo "== 1. Estado ANTES de migrar =="
docker exec -i "${CONTAINER_NAME}" mysql -uroot -p"${ROOT_PASSWORD}" -e "SHOW REPLICA STATUS\G" \
  | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Source" || true

echo ""
echo "== 2. Deteniendo replica (se conserva la posicion) =="
docker exec -i "${CONTAINER_NAME}" mysql -uroot -p"${ROOT_PASSWORD}" -e "STOP REPLICA;"

echo ""
echo "== 3. Reconfigurando conexion con SSL =="
docker exec -i "${CONTAINER_NAME}" mysql -uroot -p"${ROOT_PASSWORD}" -e "
  CHANGE REPLICATION SOURCE TO
    SOURCE_USER='${REPL_USER}',
    SOURCE_PASSWORD='${REPL_PASSWORD}',
    SOURCE_SSL=1,
    SOURCE_SSL_CA='/etc/mysql/ssl/ca.pem',
    SOURCE_SSL_CERT='/etc/mysql/ssl/client-cert.pem',
    SOURCE_SSL_KEY='/etc/mysql/ssl/client-key.pem';
"

echo ""
echo "== 4. Reanudando replica =="
docker exec -i "${CONTAINER_NAME}" mysql -uroot -p"${ROOT_PASSWORD}" -e "START REPLICA;"

echo ""
echo "== 5. Esperando unos segundos y verificando estado FINAL =="
sleep 3
docker exec -i "${CONTAINER_NAME}" mysql -uroot -p"${ROOT_PASSWORD}" -e "SHOW REPLICA STATUS\G" \
  | grep -E "Slave_IO_Running|Slave_SQL_Running|Master_SSL_Allowed|Seconds_Behind_Source|Last_IO_Error|Last_SQL_Error"

echo ""
echo "Si ves Slave_IO_Running: Yes / Slave_SQL_Running: Yes / Master_SSL_Allowed: Yes -> exito."
echo "Si hay Last_IO_Error, revisa rutas y permisos de los .pem en el contenedor slave."
