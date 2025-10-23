#!/usr/bin/env bash

CONTAINER_NAME="hive-postgres-metastore-step2"

#podman build --tag hive-postgres-tpcds-metastore-step2:0.1 .
#
#podman run --replace --name "$CONTAINER_NAME" -p 15433:5432 -e POSTGRES_PASSWORD=postgres -d hive-postgres-tpcds-metastore-step2:0.1
#

DONESTR="PostgreSQL init process complete; ready for start up."

check() {
  podman logs "$CONTAINER_NAME" 2>&1 | grep -q "$DONESTR" > /dev/null
}

for ((c=0; c<120; c++)) do
  if check; then
    break
  fi
  sleep 1
done

if ! check; then
  printf "Container %s was not started within 120s. Check the logs with:\n" "$CONTAINER_NAME"
  printf "  podman logs %s\n" "$CONTAINER_NAME"
  exit 1
fi

printf "Database initialized; copy the data\n"

podman stop "$CONTAINER_NAME"

rm -rf data
rm -rf ../step3/data
mkdir -p data
# somehow the cp command has problems with slashes ...
podman cp hive-postgres-metastore-step2:/var/lib/postgresql/data data

mv data ../step3/data
