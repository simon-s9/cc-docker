FROM percona:5.7
RUN mkdir -p /usr/share/clustercontrol
COPY init.sql /usr/share/clustercontrol/init.sql
EXPOSE 3306
CMD ["mysqld", "--init-file=/usr/share/clustercontrol/init.sql"]
