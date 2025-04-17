DOCKER_RETH_ENODE=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' \
    http://localhost:8545 | jq -r '.result.enode')

./reth node \
  --chain ./genesis.json \
  --datadir ./reth_data \
  --addr 0.0.0.0 \
  --port 30304 \
  --discovery.port 30304 \
  --authrpc.addr 0.0.0.0 \
  --authrpc.port 8552 \
  --authrpc.jwtsecret ./jwt.hex \
  --http \
  --http.addr 0.0.0.0 \
  --http.port 8547 \
  --http.api "admin,eth,net,web3,trace,rpc,debug,txpool" \
  --ws \
  --ws.addr 0.0.0.0 \
  --ws.port 8548 \
  --metrics "127.0.0.1:9002" \
  --bootnodes "$DOCKER_RETH_ENODE" \
  --nat extip:127.0.0.1