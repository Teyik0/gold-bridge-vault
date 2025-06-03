# 🏆 GoldBridge Vault - Digital Gold Revolution

> **Transform your crypto into real gold-backed tokens and bridge them across chains with cutting-edge DeFi technology** ⚡

## 🌟 What Makes GoldBridge Special?

### 💎 **Real Gold, Digital Power**
- **Gold-Backed ERC20 Tokens**: Every token represents actual physical gold stored securely
- **Live Price Feeds**: Real-time gold (XAU/USD) and ETH prices via Chainlink oracles
- **Instant Conversion**: Mint tokens with ETH, burn tokens for ETH refunds

### 🌉 **Cross-Chain Bridge Magic**
- **Seamless CCIP Integration**: Bridge your gold tokens to Binance Smart Chain effortlessly
- **Multi-Chain Liquidity**: Access DeFi opportunities across different blockchains
- **Secure Transfers**: Powered by Chainlink's battle-tested CCIP technology

### 🎰 **Community Lottery System**
- **Fee-Powered Rewards**: Collected fees fuel exciting lottery rounds
- **Provably Fair**: Chainlink VRF ensures cryptographically secure randomness
- **Community Benefits**: Win big while supporting the ecosystem

## 🚀 Key Features

| Feature | Technology | Benefit |
|---------|------------|---------|
| 🏅 **Gold Tokenization** | Chainlink Price Feeds | Real-time, accurate pricing |
| 🌐 **Cross-Chain Bridge** | Chainlink CCIP | Seamless multi-chain access |
| 🎲 **Fair Lottery** | Chainlink VRF | Transparent, verifiable randomness |
| 🔐 **Security First** | OpenZeppelin Standards | Battle-tested smart contracts |
| ⚡ **Gas Efficient** | Optimized Solidity | Lower transaction costs |

## 🛠 Quick Start

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Node.js and npm/yarn
- Ethereum wallet with testnet ETH

### 🚀 Installation & Setup

```bash
# Clone the golden repository
git clone https://github.com/Teyik0/gold-bridge-vault.git
cd gold-bridge-vault

# Install dependencies
forge install

# Set up environment variables
cp .env.template .env
# Edit .env with your configuration
```

### 🧪 Testing Suite

```bash
# Run comprehensive tests
forge test -vv

# Generate coverage report
forge coverage --ir-minimum

# Detailed coverage analysis
forge coverage --report debug > report.log --ir-minimum
```

### 🚀 Deployment

```bash
# Load environment variables
source .env

# Deploy to testnet (remove --broadcast for dry run)
forge script script/GoldTokenCCIP.s.sol:GoldTokenCCIPScript \
  --rpc-url $RPC_URL \
  --sender $PUBLIC_WALLET_ADDRESS \
  --private-key $PRIVATE_KEY \
  -vvvv --broadcast
```

## 🏗 Smart Contract Architecture

### 📊 **GoldToken.sol**
- **Minting**: Convert ETH to gold-backed tokens using live prices
- **Burning**: Redeem tokens for ETH (minus fees)
- **Fee Collection**: 5% fee on all transactions powers the ecosystem

### 🌉 **GoldTokenCCIP.sol**
- **Bridge Function**: Transfer tokens to BNB Chain
- **Gas Efficiency**: Optimized for minimal transaction costs
- **Security**: Built-in balance and address validation

### 🎰 **GoldTokenLottery.sol**
- **Entry System**: Pay entry fee to participate
- **Random Selection**: Chainlink VRF ensures fairness
- **Prize Distribution**: Automated winner selection and payout

## 📈 Supported Networks

| Network | Status | Chain ID | Features |
|---------|--------|----------|----------|
| 🔵 **Ethereum Sepolia** | ✅ Active | 11155111 | Full functionality |
| 🟣 **Polygon Mainnet** | ✅ Ready | 137 | Production ready |
| 🟡 **BNB Chain** | 🔄 Bridge Target | Various | CCIP destination |

## 🔧 Environment Configuration

```bash
# Required environment variables
FCT_PLUGIN_PATH=         # Foundry plugin path
ETH_URL=                 # Ethereum RPC URL
RPC_URL=                 # Primary RPC endpoint
PRIVATE_KEY=             # Deployment private key
PUBLIC_WALLET_ADDRESS=   # Deployer address
ROOT=                    # Project root directory
CHAINLINK_CONTAINER_NAME= # Docker container name
COMPOSE_PROJECT_NAME=    # Docker compose project
```

## 🎯 Use Cases

### 👨‍💼 **For Investors**
- 💰 **Hedge Against Inflation**: Digital gold exposure
- 🌍 **Global Access**: Trade gold 24/7 from anywhere
- 🔄 **Liquidity**: Easy conversion between ETH and gold

### 🏢 **For DeFi Protocols**
- 🤝 **Integration**: Add gold-backed assets to your protocol
- 📊 **Stability**: Non-correlated asset for portfolio diversification
- 🌉 **Multi-Chain**: Expand across different blockchains

### 🎮 **For Users**
- 🎰 **Entertainment**: Participate in fair lottery games
- 💎 **Rewards**: Earn from ecosystem fees
- 🚀 **Innovation**: Experience cutting-edge DeFi technology

## 🛡 Security Features

- ✅ **Reentrancy Protection**: ReentrancyGuard implementation
- ✅ **Oracle Security**: Chainlink price feed validation
- ✅ **Access Control**: ConfirmedOwner pattern
- ✅ **Input Validation**: Comprehensive parameter checking
- ✅ **Test Coverage**: Extensive testing suite

## 📊 How It Works

### 1. 🏅 **Mint Gold Tokens**
```solidity
// Send ETH, get gold-backed tokens
goldToken.mint{value: 1 ether}();
```

### 2. 🌉 **Bridge to BNB Chain**
```solidity
// Bridge tokens across chains
goldTokenCCIP.bridgeToBNBChain(recipient, amount);
```

### 3. 🎲 **Join the Lottery**
```solidity
// Enter lottery with collected fees
goldTokenLottery.enterLottery{value: entryFee}();
```

## 💡 Why Choose GoldBridge?

- 🏆 **First-of-its-kind**: Revolutionary gold-backed DeFi protocol
- 🔮 **Future-Proof**: Built for multi-chain ecosystem
- 💪 **Community-Driven**: Rewards shared with participants
- 🚀 **Innovation Leader**: Cutting-edge Chainlink integrations
- 🛡️ **Security Focused**: Audited and battle-tested code

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines:

1. 🍴 Fork the repository
2. 🌿 Create a feature branch
3. 💻 Write tests for new functionality
4. 📝 Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🚨 Disclaimer

⚠️ **Important**: This is experimental DeFi technology. Please understand the risks before using. Always do your own research and never invest more than you can afford to lose.

---

### ⚡ **Ready to revolutionize digital gold? Start building with GoldBridge Vault today!** 🚀

*Built with ❤️ using Chainlink, OpenZeppelin, and Foundry*