#!/bin/bash
# In ra bằng chứng cho từng biện pháp hardening
cd "$(dirname "$0")/.."
set -a; source .env; set +a

echo "=================== 1. MAT KHAU MANH (chi in do dai, khong lo mat khau) ==================="
awk -F= '/PASSWORD/ {print $1 ": " length($2) " ky tu"}' .env
ls -l .env

echo
echo "=================== 2. NON-ROOT CONTAINER ==================="
echo "--- bds_app:"
docker compose exec -T app id
for c in bds_grafana bds_loki bds_prometheus bds_nginx_exporter bds_mysqld_exporter bds_db; do
  echo "--- $c (user cua tien trinh chinh):"
  docker top $c -eo user,comm | sed -n '2,3p'
done

echo
echo "=================== 3. NETWORK ISOLATION ==================="
docker network ls | grep -E "NAME|batdongsan"
echo "--- backend la mang internal:"
docker network inspect batdongsan-devops_backend -f 'Internal={{.Internal}}'
echo "--- app -> db (phai ket noi duoc):"
docker compose exec -T app sh -c 'nc -z -w 3 db 3306 && echo "app ket noi duoc db (DUNG)" || echo "LOI"'
echo "--- nginx -> db (phai KHONG ket noi duoc):"
docker compose exec -T nginx sh -c 'nc -z -w 3 db 3306 && echo "nginx thay duoc db (SAI)" || echo "nginx khong thay duoc db (DUNG)"'
echo "--- db -> internet (phai bi chan):"
docker compose exec -T db bash -c 'timeout 3 bash -c "echo > /dev/tcp/1.1.1.1/53" 2>/dev/null && echo "DB ra internet duoc (SAI)" || echo "DB khong ra duoc internet (DUNG)"'
echo "--- cong dang mo ra may host:"
docker ps --format 'table {{.Names}}\t{{.Ports}}' | grep -E "NAMES|->"

echo
echo "=================== 4. HAN CHE QUYEN DB ==================="
docker compose exec -T db mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW GRANTS FOR '${MYSQL_USER}'@'%'; SHOW GRANTS FOR 'exporter'@'%'; SELECT user,host FROM mysql.user WHERE user IN ('root','${MYSQL_USER}','exporter');" 2>/dev/null

echo
echo "=================== 5. SECURITY HEADERS NGINX ==================="
curl -k -sI https://localhost | grep -iE "^(HTTP|server|strict|x-frame|x-content|referrer|permissions|content-security)"

echo
echo "=================== 6. RATE LIMIT NGINX (60 request lien tiep) ==================="
for i in $(seq 1 60); do curl -k -s -o /dev/null -w "%{http_code}\n" https://localhost/; done | sort | uniq -c
echo "--- chan file an (phai 404):"
curl -k -s -o /dev/null -w "%{http_code}\n" https://localhost/.env

echo
echo "=================== 7. GIAM SAT VAN HOAT DONG SAU HARDENING ==================="
sleep 20
curl -s 'http://localhost:9090/api/v1/query?query=up' | jq -r '.data.result[] | "\(.metric.job)\t\(.value[1])"'
