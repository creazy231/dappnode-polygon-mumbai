#!/bin/sh

# exit script on any error
set -e

# Set Bor Home Directory
BOR_HOME=/datadir

# Check for genesis file and download or update it if needed
if [ ! -f "${BOR_HOME}/genesis.json" ];
then
    echo "setting up initial configurations"
    cd ${BOR_HOME}
    echo "downloading launch genesis file"
    wget https://raw.githubusercontent.com/maticnetwork/launch/master/testnet-v4/sentry/sentry/bor/genesis.json
    echo "initializing bor with genesis file"
    bor --datadir ${BOR_HOME} init ${BOR_HOME}/genesis.json
else
    # Check if genesis file needs updating
    cd ${BOR_HOME}
    BERLINBLOCK=$(grep berlinBlock genesis.json | wc -l)                    # v0.2.5 Update
    STATESYNCRERCORDS=$(grep overrideStateSyncRecords genesis.json | wc -l) # v0.2.6 Update
    if [ ${BERLINBLOCK} == 0 ] || [ ${STATESYNCRERCORDS} == 0 ];
    then
        echo "Updating Genesis File"
        wget https://raw.githubusercontent.com/maticnetwork/launch/master/testnet-v4/sentry/sentry/bor/genesis.json -O genesis.json
        bor --datadir ${BOR_HOME} init ${BOR_HOME}/genesis.json
    fi
fi

if [ "${BOOTSTRAP}" == 1 ] && [ -n "${SNAPSHOT_URL}" ] && [ ! -f "${BOR_HOME}/bootstrapped" ];
then
  echo "downloading snapshot from ${SNAPSHOT_URL}"
  mkdir -p ${BOR_HOME}/bor/chaindata
  wget -c "${SNAPSHOT_URL}" -O - | tar -xz -C ${BOR_HOME}/bor/chaindata && touch ${BOR_HOME}/bootstrapped
fi


READY=$(curl -s heimdalld:26657/status | jq '.result.sync_info.catching_up')
while [[ "${READY}" != "false" ]];
do
    echo "Waiting for heimdalld to catch up."
    sleep 30
    READY=$(curl -s heimdalld:26657/status | jq '.result.sync_info.catching_up')
done

exec bor --port=40303 --maxpeers=200 --datadir=/datadir  --networkid=80001 --syncmode=full --miner.gaslimit=200000000  --miner.gastarget=20000000 --bor.heimdall=http://heimdallr:1317 --http --http.addr=0.0.0.0 --http.port=8545 --http.api=eth,net,web3,bor --http.corsdomain="*" --http.vhosts="*" --ws --ws.addr=0.0.0.0 --ws.port=8546 --ws.api=eth,net,web3,bor --ws.origins="*" --nousb --bootnodes=enode://320553cda00dfc003f499a3ce9598029f364fbb3ed1222fdc20a94d97dcc4d8ba0cd0bfa996579dcc6d17a534741fb0a5da303a90579431259150de66b597251@54.147.31.250:30303,enode://f0f48a8781629f95ff02606081e6e43e4aebd503f3d07fc931fad7dd5ca1ba52bd849a6f6c3be0e375cf13c9ae04d859c4a9ae3546dc8ed4f10aa5dbb47d4998@34.226.134.117:30303
