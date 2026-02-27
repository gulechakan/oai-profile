# Profile Notes

- This repository is based on Ubuntu22.
- It reserves one d430 compute node. 
- `setup.sh` creates a sirectory `mydata` to deply OAI 5G Core Network, OAI 5G RAN, and FlexRIC. It sets up the node for deployment, and installs `cmake` and change `gcc` version to 13 by using helper scripts. 
- `deploy-oai-cn5g.sh` script is used to deploy the OAI 5G Core Network. It clones a modified latest version (currently v2.2.0) of the core network.
