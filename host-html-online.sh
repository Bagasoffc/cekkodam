#!/bin/bash

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
  echo "Contoh: bash scripts/host-html-online.sh agasoffc.my.id"
  exit 1
fi

SUBDOMAIN="cekkodam"
FULL_DOMAIN="$SUBDOMAIN.$DOMAIN"

# Variabel direktori
WEB_ROOT="/var/www/$FULL_DOMAIN"
NGINX_AVAILABLE="/etc/nginx/sites-available/$FULL_DOMAIN"
NGINX_ENABLED="/etc/nginx/sites-enabled/$FULL_DOMAIN"
HTML_SOURCE_URL="https://raw.githubusercontent.com/Bagasoffc/cekkodam/main/index.html"

echo "[1/5] Install NGINX & Certbot..."
apt update -y && apt install nginx certbot python3-certbot-nginx wget -y

echo "[2/5] Siapkan direktori $WEB_ROOT ..."
mkdir -p "$WEB_ROOT"

echo "[3/5] Ambil HTML dari GitHub..."
wget -O "$WEB_ROOT/index.html" "$HTML_SOURCE_URL"

chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

echo "[4/5] Buat konfigurasi NGINX untuk $FULL_DOMAIN ..."
cat > "$NGINX_AVAILABLE" <<EOF
server {
    listen 80;
    server_name $FULL_DOMAIN;

    root $WEB_ROOT;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Buat symlink jika belum ada
if [ ! -L "$NGINX_ENABLED" ]; then
  ln -s "$NGINX_AVAILABLE" "$NGINX_ENABLED"
fi

nginx -t && systemctl reload nginx

echo "[5/5] Pasang SSL dari Let's Encrypt..."
certbot --nginx -d "$FULL_DOMAIN" --non-interactive --agree-tos -m admin@$DOMAIN --redirect

echo "✅ Website kamu aktif di: https://$FULL_DOMAIN"
