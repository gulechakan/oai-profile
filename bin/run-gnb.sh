cp -r /mydata/oai-5gc-modified/docker-compose/ran-conf/ -r /local/repository/

sudo apt install -y moreutils

cd /mydata/openairinterface5g_modified/cmake_targets

sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem -O /local/repository/ran-conf/gnb.conf --sa --rfsim
