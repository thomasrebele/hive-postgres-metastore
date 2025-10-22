#!/bin/bash

podman run -e POSTGRES_PASSWORD=postgres --replace --name hive-postgres-metastore-import -p 15433:5432 citusdata/citus


