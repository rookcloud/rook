function header()
{
  echo " --> $@"
}

function status()
{
  echo "     $@"
}

function run()
{
  status "$@"
  silence_unless_failed indent_output "$@"
}

function indent_output()
{
  local tempfile=`mktemp /tmp/output.XXXXXX`
  set +e
  ("$@" >"$tempfile" 2>&1)
  local status=$?
  set -e
  sed 's/^/     /g' "$tempfile"
  rm "$tempfile"
  return "$status"
}

function realtime_indent_output()
{
  set +e
  set -o pipefail
  (stdbuf -oL "$@" 2>&1 | sed 's/^/     /g')
  local status=$?
  set +o pipefail
  set -e
  return "$status"
}

function silence_unless_failed()
{
  local tempfile=`mktemp /tmp/output.XXXXXX`
  set +e
  ("$@" >"$tempfile" 2>&1)
  local status="$?"
  set -e
  if [[ "$status" != 0 ]]; then
    cat "$tempfile"
    rm "$tempfile"
    return "$status"
  fi
}

function abort()
{
  echo "*** ERROR: $@" >&2
  exit 1
}

function cleanup()
{
  local pids=`jobs -p`
  set +e
  if [[ "$pids" != "" ]]; then
    kill $pids >/dev/null 2>/dev/null
  fi
}

trap cleanup EXIT
umask u=rwx,g=rx,o=rx
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
