#!/bin/bash

if [ -f /tmp/metastore_db.zstd ]; then
  echo "found"
  time zstdcat /tmp/metastore_db.zstd | tar -C /var/lib/postgresql/ -x
  rm /tmp/metastore_db.zstd
fi

/usr/local/bin/docker-entrypoint.sh "$@"
