# GoldToken ETF Bridge Contract

This contract allow users to have gold tokens on the Ethereum network that are backed by physical gold. The gold is stored in a vault and the tokens are minted when the gold is deposited and burned when the gold is withdrawn.
User can also bridge their gold tokens to the Binance Smart Chain network thanks to Chainlink CCIP technologies.
When the contract has recolted enough fees from the minting and burning of the tokens, the contract allow users to participate in a lottery to win a part of the fees in GoldToken.

## Quick Start

```bash
git clone https://github.com/Teyik0/erc20_gold_mint.git
cd erc20_gold_mint
```

Test the contract

```bash
forge install
forge test -vv
forge coverage
forge coverage --report debug > report.log
```

Deploy the contract on the Ethereum network

```bash
forge script --chain sepolia script/GoldTokenCCIP.s.sol:GoldTokenCCIPScript --rpc-url $RPC_URL -vvvv --broadcast
```

You can delete --broadcast if you just want to see if the deployment script is correct
