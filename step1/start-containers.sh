#!/bin/bash

podman run -e POSTGRES_PASSWORD=postgres --replace --name hive-postgres-metastore-cleanup -p 15433:5432 postgres:18-alpine


