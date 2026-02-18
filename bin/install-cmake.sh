cd /mydata

# Install cmake from source
function install_cmake_327_from_source {
    
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

install_cmake_327_from_source