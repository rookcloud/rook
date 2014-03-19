function indent_output()
{
	local tempfile=`mktemp /tmp/output.XXXXXX`
	set +e
	"$@" >"$tempfile" 2>&1
	local status=$?
	set -e
	sed 's/^/     /g' "$tempfile"
	rm "$tempfile"
	return "$status"
}

function silence_unless_failed()
{
	local tempfile=`mktemp /tmp/output.XXXXXX`
	set +e
	"$@" >"$tempfile" 2>&1
	local status=$?
	set -e
	if [[ "$status" != 0 ]]; then
		cat "$tempfile"
		rm "$tempfile"
		return "$status"
	fi
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

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

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

# Install Docker.
if ! command -v docker >/dev/null 2>/dev/null; then
	echo "Is ubuntu: $is_ubuntu"
	if $is_ubuntu; then
		echo " --> Installing Docker for Ubuntu"
		echo "     adding GPG key..."
		silence_unless_failed indent_output apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
		echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
		echo "     apt-get update..."
		silence_unless_failed indent_output apt-get update
		echo "     apt-get install lxc-docker..."
		silence_unless_failed indent_output apt-get install -y lxc-docker
	else
		echo " *** ERROR: Docker not found on `hostname -f`. Please install Docker from: https://www.docker.io/gettingstarted/#h_installation"
		exit 1
	fi
fi

# Check kernel.
kernel_major=`uname -r | cut -d. -f 1`
kernel_minor=`uname -r | cut -d. -f 2`
if [[ "$kernel_major" -lt 3 ]] || [[ "$kernel_major" = 3 && "$kernel_minor" -lt 8 ]]; then
	echo " *** ERROR: Rook requires at least kernel 3.8. You are running kernel `uname -r`. Please upgrade your kernel first."
	exit 1
fi

# Pull latest runtime image.
echo " --> Pulling latest runtime ($docker_image)"
docker pull "$docker_image"

# Restart container.
echo " --> Restarting container"
container_name="rook-$type"
set +e
docker stop "$container_name" >/dev/null
docker rm "$container_name" >/dev/null
set -e
docker_opts=
if $is_app_server; then
	docker_opts="$docker_opts -v /rook/$type/code:/app"
fi
touch "$result_dir/result"
chmod 777 "$result_dir/result" # So that the provisioner, which isn't running as root, can delete the directory.
docker run $docker_opts \
	-d \
	--cidfile "$result_dir/result" \
	--name "$container_name" \
	"$image_name" \
	init_wrapper
