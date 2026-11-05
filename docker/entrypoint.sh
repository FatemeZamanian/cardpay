#!/bin/sh
# آماده‌سازی داده‌های ماندگار CardPay و بعد اجرای Apache.
#
# نصاب CardPay فایل .env و storage/installed.lock رو داخل پوشه‌ی برنامه می‌نویسه.
# برای اینکه با ساخت دوباره‌ی کانتینر از بین نرن:
#   storage/ و public/uploads/ → symlink به /data  (volume)
#   .env → هر ۵ ثانیه اگه تغییر کرده باشه به /data/.env کپی می‌شه، و موقع استارت برمی‌گرده.
set -e

APP=/var/www/html
DATA=/data

mkdir -p "$DATA/storage" "$DATA/uploads"

persist_dir() {  # persist_dir <مسیر داخل برنامه> <مسیر روی volume>
  src="$1"; dst="$2"
  if [ ! -L "$src" ]; then
    # بار اول: فایل‌های پیش‌فرض (.gitkeep، .htaccess) رو بدون بازنویسی منتقل کن
    cp -a -n "$src"/. "$dst"/ 2>/dev/null || true
    rm -rf "$src"
    ln -s "$dst" "$src"
  fi
}
persist_dir "$APP/storage" "$DATA/storage"
persist_dir "$APP/public/uploads" "$DATA/uploads"
mkdir -p "$DATA/storage/logs" "$DATA/storage/cache" "$DATA/storage/sessions" "$DATA/storage/uploads"

# برگردوندن .env بعد از ساخت دوباره‌ی کانتینر
if [ -f "$DATA/.env" ]; then
  cp "$DATA/.env" "$APP/.env"
  chown www-data:www-data "$APP/.env"; chmod 600 "$APP/.env"
fi

chown -R www-data:www-data "$DATA"
chown -h www-data:www-data "$APP/storage" "$APP/public/uploads"
# خود پوشه‌ی storage و زیرپوشه‌ها حتما برای www-data قابل نوشتن باشن (نصاب هر کدوم رو جدا چک می‌کنه)
chmod 775 "$DATA" "$DATA/storage" "$DATA/uploads" "$DATA/storage/logs" "$DATA/storage/cache" "$DATA/storage/sessions" "$DATA/storage/uploads"
# نصاب باید بتونه .env.tmp بسازه و روی .env rename کنه
chown www-data:www-data "$APP"

(
  while true; do
    if [ -f "$APP/.env" ] && ! cmp -s "$APP/.env" "$DATA/.env" 2>/dev/null; then
      cp "$APP/.env" "$DATA/.env" && chmod 600 "$DATA/.env"
    fi
    sleep 5
  done
) &

exec docker-php-entrypoint "$@"
