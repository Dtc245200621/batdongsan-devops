# Các truy vấn LogQL dùng trong dự án

Chạy trong Grafana: menu Explore, chọn datasource Loki, chuyển sang chế độ Code.

## Query 1: Toàn bộ log của Nginx (lọc theo chuỗi)

    {service="nginx"} |= "GET"

## Query 2: Log lỗi/cảnh báo của MySQL (lọc bằng regex)

    {service="db"} |~ "(?i)warning|error"

## Query 3: Đếm số request Nginx theo mã trạng thái HTTP trong 5 phút

    sum by (status) (count_over_time({service="nginx"} | pattern `<ip> - <user> [<_>] "<method> <uri> <_>" <status> <size> "<_>" "<agent>" "<_>"` [5m]))

## Query 4: Chỉ các request lỗi (HTTP 4xx/5xx)

    {service="nginx"} | pattern `<ip> - <user> [<_>] "<method> <uri> <_>" <status> <size> "<_>" "<agent>" "<_>"` | status >= 400
