#!/bin/bash
su -l postgres -c "/usr/local/bin/pg_resetwal /var/lib/postgresql/18/docker/"

echo "entrypoint-resetwal.sh done executing pg_resetwal"
