cd /mydata

git clone -b rebased-5g-nvs-rc-rf --single-branch https://github.com/gulechakan/openairinterface5g_modified.git

cd /mydata/openairinterface5g_modified/cmake_targets

./build_oai -I -w SIMU --gNB --nrUE --build-e2 --ninja
