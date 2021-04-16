#!/bin/bash
set -e

echo "MBDB: PGDATA = ${PGDATA}"

# pg_hba.conf
echo "MBDB: Moving pg_hba.conf to pg_hba.conf.bak ..."
mv ${PGDATA}/pg_hba.conf ${PGDATA}/pg_hba.conf.bak
echo "MBDB: Setting pg_hba.conf ..."
echo -e "\
# Allow all MBARI systems access - modify for your institution
host    all everyone,mbdbadmin   134.89.0.0/16   md5\n\
# === MBDB - allow all private addresses that may be docker host\n\
host    all mbdbadmin,postgres   10.0.0.0/8      md5\n\
host    all mbdbadmin,postgres   172.16.0.0/12   md5\n\
host    all mbdbadmin,postgres   192.168.0.0/16  md5\n\
host    all mbdbadmin,postgres   127.0.0.1/8     md5\n\
local   all all                                 trust" > ${PGDATA}/pg_hba.conf
