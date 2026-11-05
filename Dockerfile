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
COPY . /var/www/html

# CardPay وابستگی runtime نداره (composer.json فقط افزونه‌های PHP رو می‌خواد)، ولی نصاب
# وجود vendor/autoload.php رو الزامی چک می‌کنه. این autoloader ساده همون app/autoload.php است.
RUN mkdir -p vendor \
 && printf '<?php\ndeclare(strict_types=1);\nrequire dirname(__DIR__) . "/app/autoload.php";\n' > vendor/autoload.php \
 && php -l vendor/autoload.php

# داده‌های ماندگار (.env، storage، uploads) روی volume به اسم /data نگهداری می‌شه
VOLUME ["/data"]
EXPOSE 80
ENTRYPOINT ["cardpay-entrypoint"]
CMD ["apache2-foreground"]
