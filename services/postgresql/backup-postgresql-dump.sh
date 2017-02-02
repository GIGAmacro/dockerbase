#!/bin/sh
echo 'PostgreSQL dump started'
set -e

BACKUP_DIR=/shared/postgresql/backup/dump

# run
mkdir -p $BACKUP_DIR
chown -R postgres:postgres $BACKUP_DIR
su - postgres -c "pg_dumpall --clean --if-exists | gzip > \"$BACKUP_DIR/sqldump.sql.gz\""
echo 'PostgreSQL dump finished'


