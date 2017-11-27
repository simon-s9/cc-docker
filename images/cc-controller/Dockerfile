FROM debian:jessie

# Install ClusterControl
RUN apt-get update
RUN apt-get -y install wget
RUN wget https://severalnines.com/downloads/cmon/s9s-repo-nightly.list -P /etc/apt/sources.list.d/
RUN wget http://repo.severalnines.com/severalnines-repos.asc -O- | apt-key add -
RUN apt-get update
RUN apt-get -y --no-install-recommends install clustercontrol-controller

# Configure cmon
COPY cmon.cnf /etc/cmon.cnf

EXPOSE 9500
EXPOSE 9501

CMD ["cmon", "-d", "--bind-addr=0.0.0.0"]
