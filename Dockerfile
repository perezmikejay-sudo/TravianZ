
FROM php:8.3-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        mysqli \
        pdo \
        pdo_mysql \
        zip

# Enable Apache modules
RUN a2enmod rewrite headers

# Production PHP configuration
RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Keep the repository's PHP configuration
COPY docker/php/zz-travianz.ini \
    /usr/local/etc/php/conf.d/zz-travianz.ini

# Apache document root
WORKDIR /var/www/html

# Copy game files into the Docker image
COPY --chown=www-data:www-data . /var/www/html/

# Configure Apache to allow access to the game
RUN printf '%s\n' \
    '<Directory /var/www/html>' \
    '    Options FollowSymLinks' \
    '    AllowOverride All' \
    '    Require all granted' \
    '    DirectoryIndex index.php index.html' \
    '</Directory>' \
    > /etc/apache2/conf-available/travianz.conf \
    && a2enconf travianz

# Create writable application directories
RUN mkdir -p /var/www/html/var \
    && chown -R www-data:www-data /var/www/html/var \
    && chmod -R u+rwX,g+rwX /var/www/html/var

# Default permissions for application files
RUN find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && chmod -R u+rwX,g+rwX /var/www/html/var

# Listen on HTTP port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
