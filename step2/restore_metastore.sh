#!/bin/bash

# Restore the metastore

# The postgres commands may exit with non-blocking errors so we shouldn't stop the script
# since in many cases the dump will be restored correctly.

cpus="$(nproc --all || echo 1)"
pg_restore -d metastore -j "$cpus" /tmp/metastore_dump.zstd || true

sleep 5

printf "CHECKPOINT;\n" | psql

sleep 60

echo "disk usage:"
du -hs /var/lib/postgresql/

# replace the postgres config (reduces disk space requirements)
cat /etc/postgresql/postgresql-run.conf > /etc/postgresql/postgresql.conf

