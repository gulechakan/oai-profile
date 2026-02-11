# Exit on error
set -e

# Create directory to deploy OAI and mount extra disk space
cd /
sudo mkdir mydata
sudo /usr/local/etc/emulab/mkextrafs.pl -f /mydata

# change the ownership of this new space
username=$(whoami)
groupname=$(id -gn)

sudo chown $username:$groupname mydata
chmod 775 mydata

# verify the result
ls -ld mydata

# Define working directory for CN5G
CN_DIR="/mydata/oai-cn5g"

# Enable packet forwarding
sudo sysctl net.ipv4.conf.all.forwarding=1
sudo iptables -P FORWARD ACCEPT

# Setup the node for deployment
function setup_oai_node {
    # Install docker, docker compose, wireshark/tshark
    echo setting up oai node
    sudo apt-get update && sudo apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      docker.io \
      docker-compose-v2 \
      gnupg \
      lsb-release

    sudo add-apt-repository -y ppa:wireshark-dev/stable
    echo "wireshark-common wireshark-common/install-setuid boolean false" | sudo debconf-set-selections

    sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo apt-get install -y \
        wireshark \
        tshark

    sudo systemctl enable docker
    sudo usermod -aG docker $USER

    printf "installing compose"
    until sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; do
        printf '.'
        sleep 2
    done

    sudo chmod +x /usr/local/bin/docker-compose

    sudo sysctl net.ipv4.conf.all.forwarding=1
    sudo iptables -P FORWARD ACCEPT

    echo setting up oai node... done.
}

setup_oai_node
