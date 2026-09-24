#!/bin/bash

if [ -f /tmp/metastore_db.zstd ]; then
  echo "found"
  time zstdcat /tmp/metastore_db.zstd | tar -C /var/lib/postgresql/ -x
fi

/usr/local/bin/docker-entrypoint.sh "$@"
