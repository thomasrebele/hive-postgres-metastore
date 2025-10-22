FROM citusdata/citus:latest

ENV METASTORE_DUMP tpcds30tb_metastore_3_1_3000

COPY ../clean-dump.zstd /tmp/clean-dump.zstd
COPY init_user_db.sql /docker-entrypoint-initdb.d/init_user_db.sql
COPY restore_metastore.sh /docker-entrypoint-initdb.d/restore_metastore.sh
COPY postgresql.conf /etc/postgresql/postgresql.conf

CMD /usr/local/bin/docker-entrypoint.sh postgres -c 'config_file=/etc/postgresql/postgresql.conf'
