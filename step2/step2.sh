#!/usr/bin/env bash

tag=postgres-tpcds-metastore-step2:1.5

#podman build --tag "$tag" .

echo "create and start container:"
c_src=$(podman create -e POSTGRES_PASSWORD=postgres "$tag")
podman container start "$c_src" | sed -u 's/^/  /'

wait_with_logging() {
  # somehow waits extra time after the needle has been found;
  # works good enough for its purpose
  echo "waiting for 'database system is ready to accept connections' appearing twice in the logs"
  echo "display the last 50 lines and follow"
  container="$1"
  # line buffering for immediate action
  (stdbuf -oL -eL podman logs --follow "$container" 2>&1 | stdbuf -oL -eL awk '
    BEGIN {rc=1}
    {print $0; fflush()}
    /database system is ready to accept connections/ {
      c+=1;
      print "found, counter: " c;
      if(c>=2) {rc=0; exit rc}
    }
    END {exit rc}') | sed -u 's/^/    /'
  return ${PIPESTATUS[0]}
}

# wait until import is done and database has started
wait_with_logging "$c_src" || { echo "database did not start correctly"; exit 1; }


#c_src="$c_src" podman unshare bash -c '
#  printf "mounting %s\n" "$c_src"
#  mnt=$(podman mount "$c_src")
#  printf "mounting container %s to %s\n" "$c_src" "$mnt"
#  tar --zstd -cf metastore_db.zstd -C "$mnt/var/lib/postgresql/" .
#  realpath metastore_db.zstd
#'

echo "stopping container"
podman container stop "$c_src"

echo "compress database"
podman cp "$c_src:/var/lib/postgresql" - | zstd -T0 -15 > ../step3/metastore_db.zstd

echo "remove container"
podman container rm "$c_src"
