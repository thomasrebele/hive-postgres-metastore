#!/bin/bash

# Restore the metastore
# The printf/awk construction is used to enable columnar storage, reducing the space requirements.

# The psql commands may exit with non-blocking errors so we shouldn't stop the script
# since in many cases the dump will be restored correctly.

(printf "
  CREATE EXTENSION citus_columnar;\n
  set columnar.compression_level=10;\n
  set columnar.stripe_row_limit=100000;\n";
  zstdcat /tmp/metastore_dump.zstd;
  printf "ALTER TABLE public.\"VERSION\" SET ACCESS METHOD heap;\n";
) | awk '
  /^SET default_table_access_method/ {print "SET default_table_access_method = columnar;"; next}
  # append "USING columnar" to the CREATE TABLE statements, except the VERSION table
  /^CREATE TABLE public./ {am="columnar"}
  /^CREATE TABLE public."VERSION"/ {am="heap"}
  am!="" && /^);\s/ { print ") USING " am ";"; next}
  /;[ \r]*$/ {am=""}
  # by default print the line
  {print $0}' | psql metastore || true

printf "CHECKPOINT;\n" | psql || true
