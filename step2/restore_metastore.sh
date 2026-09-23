#!/bin/bash

# Restore the metastore

# The psql commands may exit with non-blocking errors so we shouldn't stop the script
# since in many cases the dump will be restored correctly.

echo "select name, setting, unit from pg_settings where name in (
  'max_wal_size',
  'min_wal_size',
  'shared_buffers',
  'work_mem'
  );" | psql -U hive -d metastore

date +%s.%N

#gunzip -c /tmp/metastore_dump.gz | pg_restore -d metastore || true
cpus="$(nproc --all || echo 1)"
pg_restore -d metastore -j "$cpus" /tmp/metastore_dump.zstd || true

date +%s.%N

printf "CHECKPOINT;\n" | psql || true

date +%s.%N

whoami

# reduce the WAL size to reduce disk space requirement
cat /etc/postgresql/postgresql-run.conf > /etc/postgresql/postgresql.conf
