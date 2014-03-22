#!/bin/bash
set -p -e
SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR"; pwd`
source "$SELFDIR/library.sh"


##### Argument parsing #####

function usage()
{
  echo "./start.sh [OPTIONS]"
  echo "Starts a container unless it's already running."
  echo
  echo "Required options:"
  echo "  -n NAMESPACE       Namespace for use under prefix directory"
  echo "  -t TYPE            Type name, e.g. 'mysql-5.5'"
  echo
  echo "Optional options:"
  echo "  -f PREFIX          Prefix directory (default: /rook)"
  echo "  -d DOCKER_IMAGE    Docker image name (default: rook/TYPE)"
  echo "  -a                 Specify that this component is an app server"
  echo "  -r                 Restart container if it's already running"
  echo "  -s                 Instead of running the Docker container normally,"
  echo "                     run a shell inside the container"
  echo "  -h                 Show usage"
}

OPTIND=1
namespace=
component_type=
prefix=/rook
docker_image=
app_server=false
restart=false
shell=false

while getopts "n:t:f:d:arsh" opt; do
  case "$opt" in
  n)
    namespace="$OPTARG"
    ;;
  t)
    component_type="$OPTARG"
    ;;
  f)
    prefix="$OPTARG"
    ;;
  d)
    docker_image="$OPTARG"
    ;;
  a)
    app_server=true
    ;;
  r)
    restart=true
    ;;
  s)
    shell=true
    ;;
  h)
    usage
    exit
    ;;
  esac
done

shift $((OPTIND-1))

if [[ "$namespace" = "" ]]; then
  abort "Please specify a namespace with -n. Or specify -h for usage."
fi
if [[ "$component_type" = "" ]]; then
  abort "Please specify a type with -t. Or specify -h for usage."
fi
if [[ "$docker_image" = "" ]]; then
  docker_image="rook/$component_type"
fi

main_path="$prefix/$namespace/$component_type"
container_name="rook_${namespace}_${component_type}"


##### Main code #####

docker_opts=()
command_in_docker=()
silence=true

if $app_server; then
  docker_opts+=(-v)
  docker_opts+=("$main_path/app/current:/app")
fi
if $shell; then
  docker_opts+=(-t)
  docker_opts+=(-i)
  docker_opts+=(--rm)
  command_in_docker+=(/bin/bash)
  command_in_docker+=(-l)
  silence=false
else
  docker_opts+=(-d)
  command_in_docker+=(/sbin/rook_init)
fi
if [[ -e "$main_path/config/rook_docker_options" ]]; then
  docker_opts+=(`cat "$main_path/config/rook_docker_options"`)
fi

function start_container()
{
  docker run \
    "${docker_opts[@]}" \
    -v "$main_path/config:/rook/config:ro" \
    -v "$main_path/log:/rook/log" \
    -v "$main_path/persist:/rook/persist" \
    -v "$main_path/cache:/rook/cache" \
    --name "$container_name" \
    "$docker_image" \
    "${command_in_docker[@]}"
}

if container_exists "$container_name"; then
  if $restart || ! container_running "$container_name"; then
    /bin/bash "$SELFDIR/stop.sh" -n "$namespace" -t "$component_type"
  else
    exit 0
  fi
fi

header "Starting container $container_name"
if $silence; then
  start_container >/dev/null
else
  start_container
fi
# TODO: wait until container gives readiness signal
