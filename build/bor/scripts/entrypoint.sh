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
    BERLINBLOCK=$(grep berlinBlock genesis.json | wc -l)                    # v0.2.5 Update
    STATESYNCRERCORDS=$(grep overrideStateSyncRecords genesis.json | wc -l) # v0.2.6 Update
    if [ ${BERLINBLOCK} == 0 ] || [ ${STATESYNCRERCORDS} == 0 ];
    then
        echo "Updating Genesis File"
        wget https://raw.githubusercontent.com/maticnetwork/launch/master/testnet-v4/sentry/sentry/bor/genesis.json -O genesis.json
        bor --datadir ${BOR_HOME} init ${BOR_HOME}/genesis.json
    fi
fi

if [ "${BOOTSTRAP}" == 1 ] && [ -n "${SNAPSHOT_DATE}" ];
then
  echo "downloading snapshot from ${SNAPSHOT_DATE}"
  mkdir -p ${BOR_HOME}/chaindata
  wget -c https://matic-blockchain-snapshots.s3.amazonaws.com/matic-mumbai/bor-snapshot-${SNAPSHOT_DATE}.tar.gz -O - | tar -xz -C ${BOR_HOME}/chaindata
fi


READY=$(curl -s heimdalld:26657/status | jq '.result.sync_info.catching_up')
while [[ "${READY}" != "false" ]];
do
    echo "Waiting for heimdalld to catch up."
    sleep 30
    READY=$(curl -s heimdalld:26657/status | jq '.result.sync_info.catching_up')
done

bor \
    --port=30303 \
    --maxpeers=200 \
    --datadir=${BOR_HOME} \
    --networkid=80001 \
    --syncmode=full
    --miner.gaslimit=200000000 \
    --miner.gastarget=20000000 \
    --bor.heimdall=http://heimdallr:1317 \
    --http \
    --http.addr=0.0.0.0 \
    --http.port=8545 \
    --http.api=eth,net,web3,bor \
    --http.corsdomain="*" \
    --http.vhosts="*" \
    --ws \
    --ws.addr=0.0.0.0 \
    --ws.port=8546 \
    --ws.api=eth,net,web3,bor \
    --ws.origins="*" \
    --bootnodes=enode://320553cda00dfc003f499a3ce9598029f364fbb3ed1222fdc20a94d97dcc4d8ba0cd0bfa996579dcc6d17a534741fb0a5da303a90579431259150de66b597251@54.147.31.250:30303