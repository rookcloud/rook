export DEBIAN_FRONTEND=noninteractive
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# Autodetect OSes.
is_debian=false
is_ubuntu=false
is_redhat=true
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
	if $is_ubuntu; then
		echo " --> Installing Docker for Ubuntu"
		apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
		echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
		apt-get update
		apt-get install -y lxc-docker
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

# Install Git.
# if ! command -v git >/dev/null 2>/dev/null; then
# 	if $is_debian; then
# 		echo " --> Installing Git"
# 		apt-get update
# 		apt-get install git
# 	else
# 		echo " *** ERROR: Git not found on `hostname -f`. Please install Git first."
# 		exit 1
# 	fi
# fi

# Pull latest runtime image.
echo " --> Pulling latest runtime ($docker_image)"
docker pull "$docker_image"

# Fetch or update code.
if [[ "$app_dir" != "" ]]; then
	echo " --> Extracting application code"
	rm -rf "$app_dir"
	mkdir -p "$app_dir"
	cd "$app_dir"
	tar -xzf "$input_dir/app.tar.gz"
	chmod -R rook_app: .
fi

# Restart container.
echo " --> Restarting container"
(
	set +e
	docker stop $name >/dev/null
	docker rm $name >/dev/null
)
docker run -d $docker_opts "$name"
# TODO: wait until container signals readiness
