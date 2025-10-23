FROM citusdata/citus:latest

COPY postgresql.conf /etc/postgresql/postgresql.conf

COPY data /var/lib/postgresql/data

CMD /usr/local/bin/docker-entrypoint.sh postgres -c 'config_file=/etc/postgresql/postgresql.conf'

