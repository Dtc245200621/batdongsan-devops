#!/bin/bash
# Sinh chứng chỉ HTTPS tự ký (self-signed) cho localhost, hạn 365 ngày
set -e
mkdir -p certs
openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -keyout certs/server.key -out certs/server.crt \
  -subj "/C=VN/ST=Thai Nguyen/O=BDS Online/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
chmod 600 certs/server.key
echo "Da tao certs/server.crt va certs/server.key"
