#!/bin/bash

ENV_FILE="../../.env"
source $ENV_FILE

# Kill previous anvil if running
pkill anvil 2>/dev/null

# Rewind 3 months back 
GENESIS_TS=$(date -d "3 months ago" +%s)
NOW_TS=$(date +%s)

echo "🕰 Genesis timestamp : $GENESIS_TS"
echo "⏰ Now timestamp     : $NOW_TS"

# Start a fresh fork
anvil --fork-url https://eth-mainnet.g.alchemy.com/v2/$ALCHEMY_KEY \
  --port 8545 \
  --chain-id 1337 \
  --host 0.0.0.0 \
  --silent &

# Wait for Anvil to start
sleep 2
