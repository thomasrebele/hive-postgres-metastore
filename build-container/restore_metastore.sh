#!/bin/bash
# Restore may exit with non-blocking errors so we shouldn't stop the script
# since in many cases the dump will be restored correctly

#zstdcat /tmp/clean-dump.zstd | awk '/^SET default_table_access_method/ {print "set default_table_access_method = columnar;"; next} {print}' | psql -U hive metastore || true

printf "CREATE EXTENSION citus_columnar;\n" | psql

(#printf "set archive_command='/bin/true';\n";
zstdcat /tmp/clean-dump.zstd) | awk '/^CREATE TABLE public./ {FOUND=1} /^$/ {FOUND=0} /^);\s/ { print ") USING columnar;"; next} {print $0}' | psql -U hive metastore

printf "CHECKPOINT; CHECKPOINT; CHECKPOINT;\n" | psql

#printf 'vacuum full;' | psql -U hive metastore

# Remove the temporary file
#rm /tmp/clean-dump.zstd
