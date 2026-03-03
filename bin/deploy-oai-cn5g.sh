cd /mydata

git clone https://github.com/gulechakan/oai-5gc-modified.git

cd oai-5gc-modified/docker-compose

sudo python3 ./core-network.py --type start-basic-slice --scenario 1
