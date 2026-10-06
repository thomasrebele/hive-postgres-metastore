#!/usr/bin/env bash

tag="$1"
 
confirm() {
	read -p "$1 (y/n): " choice
	case "$choice" in
	  y|Y ) return 0;;
	  n|N ) return 1;;
	  * ) echo "please enter y or n";;
	esac
	return 2
}

if [ "$tag" == "" ]; then
  echo "Error: specify the image tag as the first argument"
  exit 1
fi

tgt_file="../step3/metastore_db.zstd"
if [ -f "$tgt_file" ]; then
  printf "Error: file %s already exists\n" "$tgt_file"
  exit 1
fi

echo "build image"
podman build --tag "$tag" .

echo "create and start container:"
c_src=$(podman create -e POSTGRES_PASSWORD=postgres "$tag")
podman container start "$c_src" | sed -u 's/^/  /'

wait_with_logging() {
  # somehow waits extra time after the needle has been found;
  # works good enough for its purpose
  echo "display the last 50 lines and follow"
  container="$1"
  needle="$2"
  count="$3"
  printf "waiting for '%s' appearing %sx in the logs" "$needle" "$count"
  # line buffering for immediate action
  (stdbuf -oL -eL podman logs --follow "$container" 2>&1 | stdbuf -oL -eL awk -v NEEDLE="$needle" -v COUNT="$count" '
    BEGIN {rc=1}
    {
      print $0; fflush();
      if ($0 ~ NEEDLE) {
        c+=1;
        print "found, counter: " c;
        if(c>=2) {rc=0; exit rc}
      }
    }
    END {exit rc}') | sed -u 's/^/    /'
  return ${PIPESTATUS[0]}
}

# wait until import is done and database has started
wait_with_logging "$c_src" "database system is ready to accept connection" 2 || 
  { echo "database did not start correctly"; exit 1; }

while ! confirm "check that WAL activity has stopped with 'podman logs --follow $c_src'. Continue? "; do
  sleep 1
done

# execute pg_resetwal
echo "stop database"
podman exec -it "$c_src" bash -c 'su -l postgres -c "/usr/local/bin/pg_ctl stop -D /var/lib/postgresql/18/docker"'

chmod a+x,go-w entrypoint-resetwal.sh
podman cp entrypoint-resetwal.sh "$c_src:/usr/local/bin/docker-entrypoint.sh"

podman container start "$c_src" | sed -u 's/^/  /'
wait_with_logging "$c_src" "entrypoint-resetwal.sh done executing pg_resetwal" 1


echo
echo "compress database"
podman cp "$c_src:/var/lib/postgresql/" - | zstd -T0 -15 > ../step3/metastore_db.zstd

echo "remove container"
podman container rm "$c_src"
