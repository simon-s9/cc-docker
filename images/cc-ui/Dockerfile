FROM ninescontrol/dap:latest

# Install clustercontrol-ui packages
RUN wget --no-check-certificate https://severalnines.com/downloads/cmon/s9s-repo-nightly.list -P /etc/apt/sources.list.d/
RUN wget --no-check-certificate http://repo.severalnines.com/severalnines-repos.asc -O- | apt-key add -
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    mysql-client \
    clustercontrol-ui

# Configure Apache
RUN chown -R www-data:www-data /var/www
RUN rm /etc/apache2/sites-enabled/000-default.conf
COPY http.conf /etc/apache2/sites-enabled/000-default.conf
COPY bootstrap.php /var/www/clustercontrol/bootstrap.php

# Configure UI
# RUN cp -f /var/www/clustercontrol/bootstrap.php.default /var/www/clustercontrol/bootstrap.php
# RUN sed -i "s|^define('DB_HOST'.*|define('DB_HOST', 'db');|g" /var/www/clustercontrol/bootstrap.php
# RUN sed -i "s|^define('DB_PORT'.*|define('DB_PORT', '3306');|g" /var/www/clustercontrol/bootstrap.php
# RUN sed -i "s|^define('APP_HOST'.*|define('APP_HOST', 'cmonapi');|g" /var/www/clustercontrol/bootstrap.php
# RUN sed -i "s|^define('RPC_TOKEN'.*|define('RPC_TOKEN', 'token');|g" /var/www/clustercontrol/bootstrap.php
# RUN echo "define('CONTAINER', 'docker');" >> /var/www/clustercontrol/bootstrap.php