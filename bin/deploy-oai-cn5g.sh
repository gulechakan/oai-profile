
exec > >(tee -a /var/tmp/deploy-oai-cn5g.log) 2>&1
set -x

# Exit on error
set -e

# Create directory to deploy OAI and mount extra disk space
cd /
sudo mkdir mydata
sudo /usr/local/etc/emulab/mkextrafs.pl -f /mydata

# change the ownership of this new space
username=$(whoami)
groupname=$(id -gn)

sudo chown $username:$groupname mydata
chmod 775 mydata

# verify the result
ls -ld mydata

# Define working directory for CN5G
CN_DIR="/mydata/oai-cn5g"

# Enable packet forwarding
sudo sysctl net.ipv4.conf.all.forwarding=1
sudo iptables -P FORWARD ACCEPT

# Install cmake from source
function install_cmake_327_from_source {
  set -e

  local VER="3.27.0"
  local TAR="cmake-${VER}.tar.gz"
  local DIR="cmake-${VER}"

  echo "[cmake] Installing CMake ${VER} from source..."

  # If already installed and version matches, skip
  if command -v cmake >/dev/null 2>&1; then
    if cmake --version | head -n1 | grep -q "${VER}"; then
      echo "[cmake] CMake ${VER} already installed. Skipping."
      return 0
    fi
  fi

  # Build dependencies (bootstrap needs these)
  sudo apt-get update -y
  sudo apt-get install -y \
    build-essential \
    wget \
    curl \
    ca-certificates \
    libssl-dev \
    libncurses5-dev \
    libncursesw5-dev

  cd /mydata

  # Download if missing
  if [ ! -f "${TAR}" ]; then
    wget -O "${TAR}" "https://github.com/Kitware/CMake/releases/download/v${VER}/${TAR}"
  fi

  # Extract fresh
  rm -rf "${DIR}"
  tar -xzf "${TAR}"

  cd "${DIR}"

  ./bootstrap
  gmake
  make -j 8
  sudo make install

  # Ensure shell sees the new cmake path
  hash -r

  echo "[cmake] Installed:"
  /usr/local/bin/cmake --version || cmake --version
}


# Setup the node for deployment
function setup_oai_node {
    # Install docker, docker compose, wireshark/tshark
    echo setting up oai node
    sudo apt-get update && sudo apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      docker.io \
      docker-compose-v2 \
      gnupg \
      lsb-release

    sudo add-apt-repository -y ppa:wireshark-dev/stable
    echo "wireshark-common wireshark-common/install-setuid boolean false" | sudo debconf-set-selections

    sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo apt-get install -y \
        wireshark \
        tshark

    sudo systemctl enable docker
    sudo usermod -aG docker $USER

    printf "installing compose"
    until sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; do
        printf '.'
        sleep 2
    done

    sudo chmod +x /usr/local/bin/docker-compose

    sudo sysctl net.ipv4.conf.all.forwarding=1
    sudo iptables -P FORWARD ACCEPT

    echo setting up oai node... done.
}

# Setup GCC-13 toolchain for OAI 
function setup_gcc13 {
    echo "Setting up GCC-13 toolchain"

    sudo apt-get update -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

    sudo apt-get install -y build-essential software-properties-common

    sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
    sudo apt-get update -y

    sudo apt-get install -y gcc-13 g++-13 cpp-13

    # Set gcc-13 as default (NON-interactive)
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-13 \
        --slave /usr/bin/gcov gcov /usr/bin/gcov-13

    sudo update-alternatives --set gcc /usr/bin/gcc-13

    sudo apt-get install -y libsctp-dev cmake-curses-gui libpcre2-dev

    gcc --version
    echo "GCC setup done"
}

install_cmake_327_from_source
# setup_oai_node
# setup_gcc13