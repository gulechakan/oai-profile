export DEBIAN_FRONTEND=noninteractive

sudo apt update -y

sudo apt-get install -y python3.10-dev

cd /mydata

git clone https://github.com/swig/swig.git

cd swig

git checkout release-4.1 

sudo apt install -y build-essential automake autoconf libtool

./autogen.sh

./configure --prefix=/usr/

make -j8

sudo make install