#!/bin/bash

# Restore the metastore
# The printf/awk construction is used to enable columnar storage, reducing the space requirements.

# The psql commands may exit with non-blocking errors so we shouldn't stop the script
# since in many cases the dump will be restored correctly.

zstdcat /tmp/metastore_dump.zstd | psql metastore || true

printf "CHECKPOINT;\n" | psql || true
