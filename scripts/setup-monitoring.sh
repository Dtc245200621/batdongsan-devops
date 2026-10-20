#!/bin/bash
# Tạo user MySQL quyền tối thiểu cho mysqld-exporter và file cấu hình kết nối.
# Chạy SAU KHI container db đã chạy: ./scripts/setup-monitoring.sh
set -e
cd "$(dirname "$0")/.."
set -a; source .env; set +a

docker compose exec -T db mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
CREATE USER IF NOT EXISTS 'exporter'@'%' IDENTIFIED BY '${MYSQL_EXPORTER_PASSWORD}' WITH MAX_USER_CONNECTIONS 3;
ALTER USER 'exporter'@'%' IDENTIFIED BY '${MYSQL_EXPORTER_PASSWORD}';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
FLUSH PRIVILEGES;"

mkdir -p mysqld-exporter
cat > mysqld-exporter/.my.cnf <<CNF
[client]
user=exporter
password=${MYSQL_EXPORTER_PASSWORD}
host=db
CNF
chmod 644 mysqld-exporter/.my.cnf
echo "Da tao user exporter va mysqld-exporter/.my.cnf"
