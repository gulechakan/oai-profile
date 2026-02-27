sudo apt update -y
sudo apt upgrade -y
sudo apt install -y build-essential
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt update
sudo apt install -y gcc-13 g++-13 cpp-13
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100 --slave /usr/bin/g++ g++ /usr/bin/g++-13 --slave /usr/bin/gcov gcov /usr/bin/gcov-13
sudo update-alternatives --config gcc 
sudo apt install libsctp-dev cmake-curses-gui libpcre2-dev