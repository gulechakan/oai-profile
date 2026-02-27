cd /mydata

git clone https://github.com/swig/swig.git

cd swig

git checkout release-4.1 

./autogen.sh

./configure --prefix=/usr/

make -j8

sudo make install

sudo apt-get install python3.10-dev
