#!/bin/bash

set -e
set -x

WORKDIR="/mydata"
REPO="https://gitlab.eurecom.fr/oaiworkshop/summerworkshop2023.git"
REPO_DIR="$WORKDIR/summerworkshop2023"

cd $WORKDIR

# Clone repo if needed
if [ ! -d "$REPO_DIR" ]; then
    git clone $REPO
fi

############################
# UE 1
############################
sudo $REPO_DIR/ran/multi-ue.sh -c1 -e
sudo ip route replace default via 10.201.1.100

############################
# UE 3
############################
sudo $REPO_DIR/ran/multi-ue.sh -c3 -e
sudo ip route replace default via 10.203.1.100

echo "All UE configurations completed"