FROM postgres:18-alpine

COPY metastore_dump.zstd /tmp/metastore_dump.zstd
COPY postgresql-*.conf /etc/postgresql/
COPY postgresql-load.conf /etc/postgresql/postgresql.conf
RUN chown postgres:postgres /etc/postgresql/postgresql*.conf

COPY init_user_db.sql /docker-entrypoint-initdb.d/init_user_db.sql
COPY restore_metastore.sh /docker-entrypoint-initdb.d/restore_metastore.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
