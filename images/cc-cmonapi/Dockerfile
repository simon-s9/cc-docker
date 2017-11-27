FROM ninescontrol/dap:latest

# Install clustercontrol-cmonapi packages
RUN wget --no-check-certificate https://severalnines.com/downloads/cmon/s9s-repo-nightly.list -P /etc/apt/sources.list.d/
RUN wget --no-check-certificate http://repo.severalnines.com/severalnines-repos.asc -O- | apt-key add -
RUN apt-get update
RUN apt-get install -y --no-install-recommends clustercontrol-cmonapi

RUN chown -R www-data:www-data /var/www
RUN rm /etc/apache2/sites-enabled/000-default.conf
COPY http.conf /etc/apache2/sites-enabled/000-default.conf