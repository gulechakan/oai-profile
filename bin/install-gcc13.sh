# Setup GCC-13 toolchain for OAI 
function setup_gcc13 {
    echo "Setting up GCC-13 toolchain"

    sudo apt-get update -y
    # sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

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

setup_gcc13