#!/bin/bash

################################################################################
# Helper script to cleanup the dump (remove unnecessary Hive databases).
# See cleanup.sql.
################################################################################

if [ "$1" == "" ]; then
  echo "usage: <histogram-dump.zstd>"
  exit
fi

HOST_DUMP_FILE="$1"
IMPORT_CONTAINER="hive-postgres-metastore-cleanup"

# check dump file
if ! zstdcat "$HOST_DUMP_FILE" | head | grep -q -- "-- ""PostgreSQL database dump" > /dev/null; then
  echo "error: provided file is not a PostgreSQL database dump:"
  printf "  %s\n" "$HOST_DUMP_FILE"
  exit 1
fi

# check container running
if ! podman ps --filter "name=$IMPORT_CONTAINER" | grep -q "$IMPORT_CONTAINER" > /dev/null; then
  printf "error: container not running: %s\nDid you execute start-containers.sh?\n" "$IMPORT_CONTAINER"
  exit 1
fi

# helper methods
exec_cmd() {
  podman exec -it "$1" bash -c "$2"
}
make_psql_cmd() {
  PSQL_OPTS="$1"
  printf 'su -l postgres -s /usr/bin/perl -- /usr/bin/psql %s' "$PSQL_OPTS"
}
PSQL_CMD=$(make_psql_cmd "-U hive metastore")

# setup database (execute setup.sql)
printf "\n\nsetup database\n"
podman cp "setup.sql" "$IMPORT_CONTAINER:/tmp/setup.sql"
exec_cmd "$IMPORT_CONTAINER" "cat /tmp/setup.sql | $(make_psql_cmd "postgres")"

# import dump
DUMP_FILE="$(basename "$HOST_DUMP_FILE")"
printf "\n\nimport dump\n"
podman cp "$HOST_DUMP_FILE" "$IMPORT_CONTAINER:/tmp/$DUMP_FILE"
exec_cmd "$IMPORT_CONTAINER" "(printf '\\c metastore\n'; zstdcat '/tmp/$DUMP_FILE') | $PSQL_CMD"

# cleanup the metastore
podman cp "cleanup.sql" "$IMPORT_CONTAINER:/tmp/cleanup.sql"
exec_cmd "$IMPORT_CONTAINER" "(printf '\\c metastore\n'; cat /tmp/cleanup.sql) | $PSQL_CMD"

# remove temporary files
exec_cmd "$IMPORT_CONTAINER" "rm /tmp/$DUMP_FILE; rm /tmp/setup.sql; rm /tmp/cleanup.sql"

# dump the metastore for the next step
exec_cmd "$IMPORT_CONTAINER" 'su -l postgres -s /usr/bin/perl -- /usr/bin/pg_dump --jobs=8 --format=c --compress=zstd:15 metastore' > ../step2/metastore_dump.zstd


