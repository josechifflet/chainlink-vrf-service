#! /bin/bash

# $1: RPC URL
# $2: Account
# $3: Sender
# $4: Verify API Key
# $5: Chain ID
forge script script/deploy.s.sol:DeployVRFHandler \
--rpc-url $1 \
--keystore ~/.foundry/keystores/$2 \
--sender $3 \
--broadcast \
--verify \
--etherscan-api-key $4 \
--sig "run(uint256 chainId)" \
"$5"
