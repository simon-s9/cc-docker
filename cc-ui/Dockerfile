FROM httpd

# Install packages
RUN apt-get update
RUN apt-get -y install wget
RUN wget http://severalnines.com/downloads/cmon/s9s-repo-nightly.list -P /etc/apt/sources.list.d/
RUN wget http://repo.severalnines.com/severalnines-repos.asc -O- | apt-key add -
RUN apt-get update
RUN apt-get install -y --no-install-recommends php-mysql php-ldap php-gd php-curl clustercontrol-ui clustercontrol-cmonapi

RUN rm /etc/apache2/sites-enabled/000-default
COPY http.conf /etc/apache2/sites-enabled/000-default

# Configure Apache2
RUN a2enmod rewrite websocket
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
CMD ["apache2"]
