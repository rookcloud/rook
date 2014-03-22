#!/bin/bash
set -p -e
SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR"; pwd`
source "$SELFDIR/library.sh"


##### Argument parsing #####

function usage()
{
  echo "./uninstall.sh [OPTIONS]"
  echo
  echo "Required options:"
  echo "  -n NAMESPACE       Namespace for use under prefix directory"
  echo "  -t TYPE            Type name, e.g. 'mysql-5.5'"
  echo
  echo "Optional options:"
  echo "  -f PREFIX          Prefix directory (default: /rook)"
  echo "  -d DOCKER_IMAGE    Docker image name (default: rook/TYPE)"
  echo "  -h                 Show usage"
}

OPTIND=1
namespace=
component_type=
prefix=/rook
docker_image=

while getopts "n:t:f:d:h" opt; do
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

container_name="rook_${namespace}_${component_type}"


##### Main code #####

/bin/bash "$SELFDIR/stop.sh" -n "$namespace" -t "$component_type"

header "Removing $namespace, component $component_type"
run rm -rf "$prefix/$namespace/$component_type"
set +e
rmdir "$prefix/$namespace" 2>/dev/null
