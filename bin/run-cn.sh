#!/bin/bash

cd /mydata/oai-5gc-modified/docker-compose

if [ "$1" == "start" ]; then
    echo "Starting basic slice..."
    sudo python3 ./core-network.py --type start-basic-slice --scenario 1

elif [ "$1" == "stop" ]; then
    echo "Stopping basic slice..."
    sudo python3 ./core-network.py --type stop-basic-slice

else
    echo "Usage: $0 {start|stop}"
    exit 1
fi