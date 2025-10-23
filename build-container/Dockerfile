FROM citusdata/citus:latest

COPY metastore_dump.zstd /tmp/metastore-dump.zstd
COPY postgresql.conf /etc/postgresql/postgresql.conf

COPY init_user_db.sql /docker-entrypoint-initdb.d/init_user_db.sql
COPY restore_metastore.sh /docker-entrypoint-initdb.d/restore_metastore.sh

CMD /usr/local/bin/docker-entrypoint.sh postgres -c 'config_file=/etc/postgresql/postgresql.conf'
