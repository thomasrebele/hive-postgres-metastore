# Hive metastores in Postgres

The project holds scripts to spin up a dockerized Postgres from a given database dump from a [Hive metastore](https://cwiki.apache.org/confluence/display/Hive/AdminManual+Metastore+3.0+Administration).

The project was derived from [zabetak/hive-postgres-metastore](https://github.com/zabetak/hive-postgres-metastore).

## Building

### Prerequisite:

A Hive metastore dump comperessed with zstd. You can get it from a Hive metastore based on Postgres by executing a command similar to `/usr/bin/pg_dump metastore | zstd -T0 -15 > metastore_dump.zstd`.

### Instructions

-   Install [Podman](https://podman.io/) (or alternatively [Docker](https://www.docker.com/),
    though you would need to replace "podman" with "docker" in the scripts).
-   Configure the database renaming in `step1/cleanup.sql`.
-   Execute `cd step1; ./start-containers.sh` in one terminal.
-   Execute `cd step1; ./import-metastore.sh /path/to/your/metastore_dump.zstd` in another terminal.
    This will create a file `step2/metastore_dump.zstd` containing a dump of the cleaned up metastore.
    Once the script is done you can kill the start-containers.sh with Ctrl+C.
-   Execute `cd step2; podman build --tag postgres-tpcds-metastore:1.4 .`.
    This will build the docker image. Change the tag of the image,
    or just increase the version number if you want to publish it.

The image should appear in `podman image ls` as
`localhost/postgres-tpcds-metastore`
(or another tag if you changed it).

## Usage

-   Create and start Postgres container:
    `podman run --name postgres_metastore -p 5432:5432 -e POSTGRES_PASSWORD=postgres -d postgres-tpcds-metastore:1.4`.
    If you get `0.0.0.0:5432: bind: address already in use`, then change the first `5432` to a free port number.
    You'll need to use that port number for the JDBC conenction as well.
-   Verify that the container is running: `podman ps`.
-   Stop Postgres container: `podman stop postgres_metastore`.
-   Remove Postgres container: `podman rm postgres_metastore`.

If you want to check the contents of the metastore the easiest way would be to
open a shell in the container and connect to the database via psql.

    podman exec -it postgres_metastore bash -c 'su -l postgres -c "/usr/local/bin/psql -U hive -d metastore"'

Or, step by step:

    podman exec -it postgres_metastore bash
    su postgres
    psql -U hive -d metastore

The default configuration binds the host port 5432 to the database running in
the container. You can access the database via JDBC using the following
information:

-   URL: `jdbc:postgresql://localhost:5432/metastore`
-   DRIVER: `org.postgresql.Driver`
-   USER: `hive`
-   PASSWORD: `hive`

If you want to start Hive and instruct it to use this database as the metastore
you have to set the following properties in `hive-site.xml`:

-   `javax.jdo.option.ConnectionURL`
-   `javax.jdo.option.ConnectionDriverName`
-   `javax.jdo.option.ConnectionUserName`
-   `javax.jdo.option.ConnectionPassword`


##  Update metastore versions

If you need to use the current dumps with a more recent version of Hive then
after creating and starting the Postgres container you can use the
[schematool](https://cwiki.apache.org/confluence/display/Hive/Hive+Schema+Tool)
to upgrade the metastore:

    schematool -dbType postgres -upgradeSchemaFrom 3.1.3000 -driver org.postgresql.Driver -url jdbc:postgresql://localhost:5432/metastore -userName hive -passWord hive

## Related project

The project [zabetak/hive-postgres-metastore](https://github.com/zabetak/hive-postgres-metastore)
provides database dumps for metastore data from various [TPC-DS](http://www.tpc.org/tpcds/)
scale factors:

* TPC-DS 10TB without histogram statistics
* TPC-DS 30TB without histogram statistics

A ready-to-use docker image can be obtained from the [Docker hub](https://hub.docker.com/r/zabetak/postgres-tpcds-metastore).
