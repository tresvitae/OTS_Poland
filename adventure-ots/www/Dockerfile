FROM php:8.2-apache

# Instalacja rozszerzeń PHP wymaganych przez MyAAC
RUN apt-get update && apt-get install -y \
    libzip-dev \
    unzip \
    git \
    && docker-php-ext-install pdo pdo_mysql zip bcmath \
    && a2enmod rewrite \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalacja Composera
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Konfiguracja Apache - AllowOverride All dla .htaccess
RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# Kopiowanie źródeł MyAAC
COPY . /var/www/html/

WORKDIR /var/www/html

# Instalacja zależności Composera
RUN composer install --no-dev --optimize-autoloader --no-interaction 2>/dev/null || true

# Kopia .htaccess z dystrybucyjnego
RUN if [ -f .htaccess.dist ] && [ ! -f .htaccess ]; then cp .htaccess.dist .htaccess; fi

# Uprawnienia dla MyAAC
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && mkdir -p system/cache system/logs system/php_sessions \
    && chown -R www-data:www-data system/cache system/logs system/php_sessions \
    && chmod -R 775 system/cache system/logs system/php_sessions

EXPOSE 80
