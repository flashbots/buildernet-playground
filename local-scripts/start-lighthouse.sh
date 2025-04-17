. ./metadata.sh

./lighthouse bn \
  --execution-jwt ./jwt.hex \
  --enr-address 127.0.0.1 \
  --port 9001 \
  --discovery-port 9001 \
  --quic-port 9101 \
  --http \
  --http-port 3501 \
  --http-address 0.0.0.0 \
  --execution-endpoint http://127.0.0.1:8552 \
  --disable-packet-filter \
  --target-peers 5 \
  --trusted-peers "$DOCKER_PEER_ID" \
  --enable-private-discovery \
  --boot-nodes "$DOCKER_ENR" \
  --libp2p-addresses "/ip4/172.17.0.1/tcp/9000/p2p/$DOCKER_PEER_ID" \
  --private \
  --debug-level debug \
  --suggested-fee-recipient 0x690B9A9E9aa1C9dB991C7721a92d351Db4FaC990 \
  --testnet-dir ./testnet \
  --datadir ./lighthouse_data