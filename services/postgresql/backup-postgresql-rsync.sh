#!/bin/sh
echo 'PostgreSQL rsync started'
set -e

BACKUP_DIR=/shared/postgresql/backup/data

# run
mkdir -p $BACKUP_DIR
chown -R postgres:postgres $BACKUP_DIR
rsync -a --delete --checksum /data/pgsql/ $BACKUP_DIR/
echo 'PostgreSQL rsync finished'


