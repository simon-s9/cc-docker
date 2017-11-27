#!/bin/bash

# Apply SQL schema
cat /var/www/clustercontrol/sql/dc-schema.sql | mysql -uroot -pbukashka

# Start Apache
apache2 -DFOREGROUND