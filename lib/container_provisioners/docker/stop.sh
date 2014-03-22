#!/bin/bash
set -p -e
SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR"; pwd`
source "$SELFDIR/library.sh"


##### Argument parsing #####

function usage()
{
  echo "./stop.sh [OPTIONS]"
  echo
  echo "Required options:"
  echo "  -n NAMESPACE       Namespace for use under prefix directory"
  echo "  -t TYPE            Type name, e.g. 'mysql-5.5'"
  echo
  echo "Optional options:"
  echo "  -h                 Show usage"
}

OPTIND=1
namespace=
component_type=

while getopts "n:t:h" opt; do
  case "$opt" in
  n)
    namespace="$OPTARG"
    ;;
  t)
    component_type="$OPTARG"
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

container_name="rook_${namespace}_${component_type}"


##### Main code #####

if container_is_running "$container_name"; then
  header "Stopping container $container_name"
  silence_unless_failed indent_output docker stop "$container_name"
fi

if container_exists "$container_name"; then
  header "Removing container $container_name"
  silence_unless_failed indent_output docker rm -f "$container_name"
fi
