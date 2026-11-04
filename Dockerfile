# ایمیج CardPay برای اجرا کنار THEA با docker compose.
# PHP 8.2 + Apache، DocumentRoot = public/ ، دیتابیس MySQL/MariaDB جداست (سرویس cardpay_db).
FROM php:8.2-apache

RUN docker-php-ext-install pdo_mysql \
 && a2enmod rewrite headers remoteip \
 && rm -rf /var/lib/apt/lists/* \
 # نیازمندی‌های docs/requirements.md؛ اگه یکی نباشه همین‌جا build شکست می‌خوره
 && php -r 'foreach (["pdo_mysql","openssl","mbstring","json","curl","fileinfo"] as $e) { if (!extension_loaded($e)) { fwrite(STDERR, "missing ext: $e\n"); exit(1); } }'

COPY docker/vhost.conf /etc/apache2/sites-available/000-default.conf
COPY docker/php.ini /usr/local/etc/php/conf.d/zz-cardpay.ini
COPY docker/entrypoint.sh /usr/local/bin/cardpay-entrypoint
RUN chmod +x /usr/local/bin/cardpay-entrypoint

WORKDIR /var/www/html
# vendor/ لازم نیست: public/index.php در نبود vendor از app/autoload.php استفاده می‌کنه.
COPY . /var/www/html

# داده‌های ماندگار (.env، storage، uploads) روی volume به اسم /data نگهداری می‌شه
VOLUME ["/data"]
EXPOSE 80
ENTRYPOINT ["cardpay-entrypoint"]
CMD ["apache2-foreground"]
