#!/bin/bash
set -p -e
SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR"; pwd`
source "$SELFDIR/library.sh"


##### Argument parsing #####

function usage()
{
  echo "./install.sh [OPTIONS]"
  echo
  echo "Required options:"
  echo "  -n NAMESPACE       Namespace for use under prefix directory"
  echo "  -t TYPE            Type name, e.g. 'mysql-5.5'"
  echo
  echo "Optional options:"
  echo "  -f PREFIX          Prefix directory (default: /rook)"
  echo "  -d DOCKER_IMAGE    Docker image name (default: rook/TYPE)"
  echo "  -i INPUT_PATH      Path to input directory (default: same dir as where this script is)"
  echo "  -a                 Specify that this component is an app server"
  echo "  -p APP_PATH        Path to application code"
  echo "  -r ROOKDIR         Path to Rookdir, relative to app path (default: rookdir)"
  echo "  -e                 Development mode"
  echo "  -h                 Show usage"
}

OPTIND=1
namespace=
component_type=
prefix=/rook
docker_image=
input_path="$SELFDIR"
app_server=false
app_path=
rookdir=rookdir
development_mode=false

while getopts "n:t:f:d:i:ap:r:eh" opt; do
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
  i)
    input_path="$OPTARG"
    ;;
  a)
    app_server=true
    ;;
  p)
    app_path="$OPTARG"
    ;;
  r)
    rookdir="$OPTARG"
    ;;
  e)
    development_mode=true
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
if $app_server && $development_mode && [[ "$app_path" = "" ]]; then
  abort "Please specify an app path with -p. Or specify -h for usage."
fi

container_name="rook_${namespace}_${component_type}"


##### Sanity checks #####

# Check user.
if [[ `id -u` != 0 ]]; then
  abort "You must invoke this script as root."
fi

# Autodetect OSes.
is_debian=false
is_ubuntu=false
is_redhat=false
if [[ -e /etc/debian_version ]]; then
  # Debian and compatible derivatives.
  is_debian=true
fi
if grep -q ubuntu /etc/os-release 2>/dev/null; then
  is_ubuntu=true
fi
if [[ -e /etc/redhat-release ]]; then
  # Red Hat and compatible derivatives (e.g. CentOS and Fedora).
  # TODO: check whether Fedora really has redhat-release
  # TODO: check whether CentOS really has redhat-release
  is_redhat=true
fi

# Check kernel.
kernel_major=`uname -r | cut -d. -f 1`
kernel_minor=`uname -r | cut -d. -f 2`
if [[ "$kernel_major" -lt 3 ]] || [[ "$kernel_major" = 3 && "$kernel_minor" -lt 8 ]]; then
  abort "Rook requires at least kernel 3.8. You are running kernel `uname -r`. Please upgrade your kernel first."
fi


##### Main code #####

# Basic system setup: create user accounts and groups.
header "Checking user accounts"
if ! grep -q rookapp /etc/group; then
  status "Installing group 'rookapp'"
  silence_unless_failed indent_output addgroup --gid 9362 rookapp
else
  status "Group 'rookapp' already installed"
fi
if ! grep -q rookapp /etc/passwd; then
  status "Installing user 'rookapp'"
  silence_unless_failed indent_output adduser --uid 9362 --gid 9362 --disabled-password --gecos "Rook App" rookapp
else
  status "User 'rookapp' already installed"
fi

# Basic system setup: install Docker.
if ! command -v docker >/dev/null 2>/dev/null; then
  if $is_ubuntu; then
    header "Installing Docker for Ubuntu"

    status "Adding GPG key..."
    silence_unless_failed indent_output apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9

    echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
    run apt-get update

    status "apt-get install lxc-docker"
    silence_unless_failed indent_output apt-get install -y lxc-docker
  else
    abort "Docker not found on `hostname -f`. Please install Docker from: https://www.docker.io/gettingstarted/#h_installation"
  fi
fi


# Setup Rook directories and update configuration and code
# TODO: set permissions on directories

header "Installing Rook directory structure"
run mkdir -p "$prefix"
# Only change owner/mode of the following directories if they didn't exist before.
if ! [[ -e "$prefix/$namespace" ]]; then
  run mkdir "$prefix/$namespace"
  run chown root:docker "$prefix/$namespace"
  run chmod u=rwx,g=x,o= "$prefix/$namespace"
fi
main_path="$prefix/$namespace/$component_type"
if ! [[ -e "$main_path" ]]; then
  run mkdir "$main_path"
  run chown root:docker "$main_path"
  run chmod u=rwx,g=x,o= "$main_path"
fi

run mkdir -p "$main_path/persist"
run mkdir -p "$main_path/cache"
if $app_server; then
  run mkdir -p "$main_path/app"
fi

if $development_mode; then
  run rm -rf "$main_path/config" "$main_path/log"
  run ln -s "$app_path/$rookdir/$component_type/config" "$main_path/config"
  run ln -s "$app_path/$rookdir/$component_type/log" "$main_path/log"
  if $app_server; then
    run rm -rf "$main_path/app/current"
    run ln -s "$app_path" "$main_path/app/current"
  fi
else
  run mkdir -p "$main_path/config"
  run mkdir -p "$main_path/log"
  if [[ -e "$input_path/config.tar.gz" ]]; then
    status "Installing component configuration"
    pushd "$main_path/config" >/dev/null
    shopt -s dotglob
    indent_output rm -rf *
    indent_output tar xzf "$input_path/config.tar.gz"
    shopt -u dotglob
    indent_output chmod -R root: .
    popd >/dev/null
  fi
fi

if ! $development_mode && $app_server; then
  header "Installing application code"

  release_name=`date +%Y%d%m-%H%M%S`
  run mkdir -p "$main_path/app/releases"
  run mkdir "$main_path/app/releases/$release_name"
  pushd "$main_path/app/releases/$release_name" >/dev/null
  status "Extracting app files to $main_path/app/releases/$release_name"
  indent_output tar xzf "$input_path/app.tar.gz"
  indent_output chmod -R rookapp: .
  popd >/dev/null

  status "Committing application release"
  run rm -rf "$main_path/app/current.new"
  run ln -sf "$main_path/app/releases/$release_name" "$main_path/app/current.new"
  if ! [[ -h "$main_path/app/current" ]]; then
    run rm -rf "$main_path/app/current"
  fi
  run mv -Tf "$main_path/app/current.new" "$main_path/app/current"

  # TODO: cleanup old releases
fi


# Pull latest Docker image.
echo "---- Installing/updating Rook runtime: $docker_image ----"
docker pull "$docker_image"

echo "---- Installation done! ----"
