#!/bin/bash

MBDB_SRVHOME=/srv
MBDB_SRVPROJ=/srv/mbdb

# Ensure that mbdb-postgis container is serving databases before continuing
POSTGRES_DB=postgres python ${MBDB_SRVHOME}/docker/database-check.py > /dev/null 2>&1
while [[ $? != 0 ]] ; do
    sleep 5; echo "*** Waiting for postgis container ..."
    POSTGRES_DB=postgres python ${MBDB_SRVHOME}/docker/database-check.py > /dev/null 2>&1
done

# Allow for psql execution (used for database creation) without a password
echo ${PGHOST}:\*:\*:postgres:${POSTGRES_PASSWORD} > /root/.pgpass &&\
    chmod 600 /root/.pgpass

export PYTHONPATH="${MBDB_SRVPROJ}:${PYTHONPATH}"

# If default mbdb database doesn't exist then load it - also running the unit and functional tests
echo "Checking for presence of mbdb database..."
POSTGRES_DB=mbdb python ${MBDB_SRVHOME}/docker/database-check.py
if [[ $? != 0 ]]; then
    echo "Creating default mbdb database and running tests..."
    ./test.sh changeme load noextraload
fi

# Fire up mbdb web app
if [ "$PRODUCTION" == "false" ]; then
    export MAPSERVER_SCHEME=http
    echo "Starting development server with DATABASE_URL=${DATABASE_URL}..."
    ${MBDB_SRVPROJ}/manage.py runserver 0.0.0.0:8000 --settings=config.settings.local
else
    echo "Starting production server with DATABASE_URL=${DATABASE_URL}..."
    # For testing on port 8000 before certificate is in place make a security exception in your browser
    export MAPSERVER_SCHEME=https
    python mbdb/manage.py collectstatic --noinput -v 0 # Collect static files
    /usr/local/bin/uwsgi --emperor /etc/uwsgi/django-uwsgi.ini --pidfile=/tmp/uwsgi.pid
fi

