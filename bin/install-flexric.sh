cd /mydata

git clone https://gitlab.eurecom.fr/mosaic5g/flexric

cd flexric/

git checkout rc_slice_xapp

mkdir build && cd build && cmake .. && make -j8

sudo make install