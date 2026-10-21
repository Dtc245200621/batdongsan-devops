#!/bin/bash
# Hạn chế quyền DB:
#  - bds_user chỉ còn SELECT, INSERT, UPDATE, DELETE trên database của ứng dụng
#    (mặc định image MySQL cấp ALL PRIVILEGES)
#  - Xóa root@'%' để root KHÔNG đăng nhập được từ xa (chỉ còn root@localhost trong container)
# Chạy SAU KHI container db đã chạy: ./scripts/harden-db.sh
set -e
cd "$(dirname "$0")/.."
set -a; source .env; set +a

docker compose exec -T db mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<SQL
REVOKE ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* FROM '${MYSQL_USER}'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
DROP USER IF EXISTS 'root'@'%';
FLUSH PRIVILEGES;
SQL
echo "Da han che quyen DB"
