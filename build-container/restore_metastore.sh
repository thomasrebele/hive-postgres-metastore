#!/bin/bash
# Restore may exit with non-blocking errors so we shouldn't stop the script
# since in many cases the dump will be restored correctly

printf "CREATE EXTENSION citus_columnar;\n" | psql

(zstdcat /tmp/metastore-dump.zstd; printf 'vacuum full;') | awk '/^CREATE TABLE public./ {FOUND=1} /^$/ {FOUND=0} /^);\s/ { print ") USING columnar;"; next} {print $0}' | psql -U hive metastore

printf "CHECKPOINT;\n" | psql
