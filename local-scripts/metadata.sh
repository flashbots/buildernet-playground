# Get Docker Lighthouse ENR and peer ID
DOCKER_ENR=$(curl -s http://localhost:3500/eth/v1/node/identity | jq -r '.data.enr')
DOCKER_PEER_ID=$(curl -s http://localhost:3500/eth/v1/node/identity | jq -r '.data.peer_id')
DOCKER_P2P_ADDR=$(curl -s http://localhost:3500/eth/v1/node/identity | jq -r '.data.p2p_addresses[0]')

echo "Docker ENR: $DOCKER_ENR"
echo "Docker Peer ID: $DOCKER_PEER_ID"
echo "Docker P2P Address: $DOCKER_P2P_ADDR"

# Get Local Lighthouse ENR and peer ID
LOCAL_ENR=$(curl -s http://localhost:3501/eth/v1/node/identity | jq -r '.data.enr')
LOCAL_PEER_ID=$(curl -s http://localhost:3501/eth/v1/node/identity | jq -r '.data.peer_id')
LOCAL_P2P_ADDR=$(curl -s http://localhost:3501/eth/v1/node/identity | jq -r '.data.p2p_addresses[0]')

echo "Local ENR: $LOCAL_ENR"
echo "Local Peer ID: $LOCAL_PEER_ID"
echo "Local P2P Address: $LOCAL_P2P_ADDR"
