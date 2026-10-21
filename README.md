# Website Bất động sản — DevOps (Docker Compose)

- Sinh viên: **Nguyen Duc Trong** — MSSV: **Dtc245200621**
- Repository: https://github.com/Dtc245200621/batdongsan-devops

Website đăng tin bất động sản (đăng tin, tìm kiếm, liên hệ) chạy hoàn toàn bằng `docker-compose`, có reverse proxy HTTPS, giám sát, log tập trung và các biện pháp hardening.

## 1. Kiến trúc
Trình duyệt ──HTTPS 443──> [Nginx] ──> [App Node.js/Express] ──> [MySQL 8]
│ ▲
│ [phpMyAdmin] (127.0.0.1:8080)
┌─────────────────────┼─────────────────────────────┐
▼ ▼ ▼
[nginx-exporter] [cAdvisor] [mysqld-exporter]
└──────────────┬──────┴─────────────────────────────┘
▼
[Prometheus] ──> [Grafana] <── [Loki] <── [Promtail] <── log của mọi container


| Thành phần | Công nghệ | Vai trò |
|---|---|---|
| Web app | Node.js 20 + Express + EJS | Đăng tin, tìm kiếm, liên hệ |
| Database | MySQL 8.0 + phpMyAdmin 5 | Lưu dữ liệu, quản lý DB |
| Reverse proxy | Nginx 1.27 | HTTPS tự ký, security headers, rate limit |
| Giám sát | Prometheus, Grafana, cAdvisor, nginx-exporter, mysqld-exporter | Container / web server / database |
| Log | Loki + Promtail | Log tập trung, truy vấn LogQL |

## 2. Yêu cầu môi trường

Windows 11 + WSL2 (Ubuntu), Docker Desktop (bật WSL Integration), Git, OpenSSL, jq.

## 3. Hướng dẫn chạy hệ thống

```bash
# 1. Lấy mã nguồn
git clone git@github.com:Dtc245200621/batdongsan-devops.git
cd batdongsan-devops

# 2. Tạo file .env với mật khẩu mạnh (32 ký tự ngẫu nhiên)
cat > .env <<EOF
MYSQL_ROOT_PASSWORD=$(openssl rand -hex 16)
MYSQL_DATABASE=batdongsan
MYSQL_USER=bds_user
MYSQL_PASSWORD=$(openssl rand -hex 16)
MYSQL_EXPORTER_PASSWORD=$(openssl rand -hex 16)
GF_ADMIN_PASSWORD=$(openssl rand -hex 16)
EOF
chmod 600 .env

# 3. Sinh chứng chỉ HTTPS tự ký (nếu chưa có certs/server.key)
./scripts/gen-cert.sh

# 4. Khởi động DB trước, tạo user giám sát, sau đó chạy toàn bộ hệ thống
docker compose up -d db
sleep 30
./scripts/setup-monitoring.sh
docker compose up -d --build

# 5. Hạn chế quyền DB (hardening)
./scripts/harden-db.sh

# 6. Kiểm chứng hardening
./scripts/verify-hardening.sh
```

Mật khẩu Grafana: `grep GF_ADMIN_PASSWORD .env` (user `admin`).

## 4. Địa chỉ truy cập

| Dịch vụ | URL | Ghi chú |
|---|---|---|
| Website | https://localhost | Chứng chỉ tự ký: bấm Advanced → Continue |
| phpMyAdmin | http://localhost:8080 | Đăng nhập `bds_user` |
| Grafana | http://localhost:3000 | Dashboard container / NGINX / MySQL, Explore → Loki |
| Prometheus | http://localhost:9090/targets | 4 target phải UP |
| Loki | http://localhost:3100/ready | Trả `ready` |

Các cổng giám sát và phpMyAdmin chỉ mở ở `127.0.0.1`, không lộ ra mạng LAN.

## 5. Giám sát (Prometheus + Grafana)

Prometheus thu thập metrics của 4 job: `prometheus`, `cadvisor` (container), `nginx` (web server), `mysql` (database). Grafana tự nạp datasource và 3 dashboard (file JSON trong `grafana/dashboards/`).

## 6. Log tập trung (Loki + Promtail + LogQL)

Promtail thu log của mọi container qua Docker socket và gắn nhãn `service`, `container`. Các truy vấn LogQL mẫu nằm trong [docs/logql-queries.md](docs/logql-queries.md):

```logql
{service="nginx"} |= "GET"
{service="db"} |~ "(?i)warning|error"
sum by (status) (count_over_time({service="nginx"} | pattern `<ip> - <user> [<_>] "<method> <uri> <_>" <status> <size> "<_>" "<agent>" "<_>"` [5m]))
```

## 7. Hardening

| Biện pháp | Chi tiết |
|---|---|
| Mật khẩu mạnh | 32 ký tự ngẫu nhiên (`openssl rand -hex 16`), lưu trong `.env` (quyền 600, không commit) |
| Non-root container | App chạy user `node`; Grafana, Loki, Prometheus, mysqld-exporter, nginx-exporter chạy user không phải root (cAdvisor và Promtail cần root, xem mục Rủi ro còn lại) |
| Giới hạn quyền container | `no-new-privileges` cho mọi service; app thêm `read_only` và `cap_drop: ALL` |
| Network isolation | 5 mạng riêng (`frontend`, `backend`, `admin`, `monitoring`, `logging`); `backend` là `internal` nên DB không ra được internet, Nginx không thấy DB |
| Hạn chế quyền DB | `bds_user` chỉ có SELECT/INSERT/UPDATE/DELETE; xóa `root@'%'`; user `exporter` quyền tối thiểu và tối đa 3 kết nối |
| Nginx | HTTPS (TLS 1.2/1.3), HSTS, X-Frame-Options, X-Content-Type-Options, CSP, Referrer-Policy, Permissions-Policy, ẩn phiên bản, rate limit 10 req/s/IP (trả 429), chặn file ẩn |
| Giảm bề mặt tấn công | Cổng ứng dụng 3000 không publish; phpMyAdmin/Prometheus/Grafana/Loki chỉ nghe `127.0.0.1` |

### Rủi ro còn lại (đã nhận diện)

- **Promtail** đọc log qua `/var/run/docker.sock` nên chạy quyền root; `:ro` không ngăn việc gọi Docker API. Môi trường thật nên dùng log driver `loki` hoặc đọc file log thay vì mount socket.
- **cAdvisor** cần mount `/`, `/sys`, `/var/lib/docker` (chỉ đọc) để đọc số liệu container.
- Chứng chỉ HTTPS là tự ký, chỉ dùng cho môi trường học tập. Thực tế dùng Let's Encrypt.

## 8. Lịch sử commit

| Commit | Nội dung |
|---|---|
| Nền | Web app Node.js, MySQL, phpMyAdmin bằng docker-compose |
| 1 | `feat(nginx)`: reverse proxy, HTTPS tự ký, security headers |
| 2 | `feat(monitoring)`: Prometheus, Grafana, cAdvisor, nginx/mysqld exporter |
| 3 | `feat(logging)`: Loki, Promtail, truy vấn LogQL |
| 4 | `feat(security)`: hardening (network isolation, quyền DB, rate limit) |
| 5 | `docs`: README và ảnh minh chứng |

## 9. Minh chứng

Ảnh chụp màn hình minh chứng cho từng yêu cầu (2 đến 6) được trình bày trong file báo cáo của đồ án.

## 10. Cấu trúc thư mục

├── app/ # mã nguồn Node.js + Dockerfile
├── db/init.sql # schema + dữ liệu mẫu
├── nginx/conf.d/ # cấu hình reverse proxy + stub_status
├── prometheus/ # prometheus.yml
├── grafana/ # provisioning + dashboard JSON
├── loki/, promtail/ # cấu hình log
├── scripts/ # gen-cert, setup-monitoring, harden-db, verify-hardening
├── docs/ # truy vấn LogQL
└── docker-compose.yml

