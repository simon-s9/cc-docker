#
# DAP - Docker Apache PHP
#

FROM debian:jessie-slim

# Install packages
RUN apt-get update
RUN apt-get -y --no-install-recommends install \
    wget \
    apache2 \
    php5 \
    php5-mysql \
    php5-ldap \
    php5-gd \
    php5-curl 

# Configure Apache2
RUN a2enmod rewrite php5 proxy proxy_http proxy_wstunnel
ENV APACHE_RUN_USER  www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR   /var/log/apache2
ENV APACHE_PID_FILE  /var/run/apache2.pid
ENV APACHE_RUN_DIR   /var/run/apache2
ENV APACHE_LOCK_DIR  /var/lock/apache2
ENV APACHE_LOG_DIR   /var/log/apache2

# Configure ports
EXPOSE 80

# Run apache2
CMD ["apache2", "-DFOREGROUND"]