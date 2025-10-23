#!/bin/bash

# Restore the metastore
# The printf/awk construction is used to enable columnar storage, reducing the space requirements.

# The psql commands may exit with non-blocking errors so we shouldn't stop the script
# since in many cases the dump will be restored correctly.

(printf "
  CREATE EXTENSION citus_columnar;\n
  set columnar.compression_level=15;\n
  set columnar.stripe_row_limit=1000000;\n";
  zstdcat /tmp/metastore-dump.zstd;
) | awk '
  /^SET default_table_access_method/ {print "SET default_table_access_method = columnar;"; next}
  # append "USING columnar" to the CREATE TABLE statements
  /^CREATE TABLE public./ {FOUND=1}
  /^$/ {FOUND=0}
  /^);\s/ { print ") USING columnar;"; next}
  # by default print the line
  {print $0}' | psql metastore || true

printf "CHECKPOINT;\n" | psql || true
