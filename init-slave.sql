CHANGE MASTER TO
    MASTER_HOST='192.168.1.105',
    MASTER_PORT=3306,
    MASTER_USER='replication',
    MASTER_PASSWORD='Repli2024.',
    MASTER_SSL=1,
    MASTER_SSL_CA='/etc/mysql/ssl/ca.pem',
    MASTER_SSL_CERT='/etc/mysql/ssl/client-cert.pem',
    MASTER_SSL_KEY='/etc/mysql/ssl/client-key.pem';
START SLAVE;
