FROM postgres:18-alpine

COPY metastore_db.zstd /tmp/metastore_db.zstd
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
#COPY postgresql.conf /etc/postgresql/postgresql.conf
#RUN chown postgres:postgres /etc/postgresql/postgresql.conf

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

#CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
CMD ["postgres"]

