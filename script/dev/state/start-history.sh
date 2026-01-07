#!/bin/bash

EPOCH_COUNT=$1
EPOCH_SIZE=$2

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Missing Arguments - Usage: execute-epoch.sh EPOCH_START EPOCH_END EPOCH_SIZE"
    exit 1
fi

SLEEP_SECONDS=2

STATE_DIR="$PROJECT_ROOT/data/1337/state"

for ((epoch=0; epoch<EPOCH_COUNT; epoch++));
do
    echo "🧱 Building history for epoch $epoch"

    forge script $DEV_STATE/BuildHistory.s.sol \
        --rpc-url $RPC_URL \
        --broadcast \
        --sender $SENDER \
        --private-key $PRIVATE_KEY \
        --sig "run(uint256,uint256)" \
        $epoch $EPOCH_SIZE  \

    sleep $SLEEP_SECONDS

    #cast rpc evm_increaseTime $EPOCH_SIZE
    #cast rpc evm_mine
    
    order_count=$(cat $STATE_DIR/epoch_$epoch/order-count.txt)
    
    echo "🎬 Executing $order_count orders in epoch $epoch..."

    SUCCESS=0
    FAIL=0

    for((i=0; i < order_count; i++)); do
        if forge script $DEV_STATE/ExecuteOrder.s.sol \
            --rpc-url $RPC_URL \
            --broadcast \
            --sender $SENDER \
            --private-key $PRIVATE_KEY \
            --sig "run(uint256,uint256)" \
            --silent \
            $epoch $i
        then 
            ((SUCCESS++))
        else
            echo "Error executing order $i"
            ((FAIL++))
        fi
    done
    echo "📊 Epoch $epoch summary:"
    echo "   ✅ Executed: $SUCCESS"
    echo "   ❌ Reverted: $FAIL"

    sleep $SLEEP_SECONDS
done

echo "✔ All epochs completed!"

OUT_FILE="data/1337/latest-block.txt"

echo "Latest block saved to ${OUT_FILE}"

cast block latest > ${OUT_FILE}