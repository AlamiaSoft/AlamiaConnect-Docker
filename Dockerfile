# main image
FROM php:8.4-apache

# installing dependencies
RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    libfreetype6-dev \
    libicu-dev \
    libgmp-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxpm-dev \
    libzip-dev \
    unzip \
    zlib1g-dev \
    gnupg

# configuring php extension
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-configure intl

# installing php extension
RUN docker-php-ext-install bcmath calendar exif gd gmp intl mysqli pdo pdo_mysql zip

# installing composer
COPY --from=composer:2.8 /usr/bin/composer /usr/local/bin/composer

# installing node js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs

# arguments
ARG container_project_path
ARG uid
ARG user

# setting work directory
WORKDIR $container_project_path

# adding user
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# setting apache
COPY ./.configs/apache.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# copy entrypoint script
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# settings for entrypoint
ENV CONTAINER_PROJECT_PATH=$container_project_path
ENV USER=$user

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
