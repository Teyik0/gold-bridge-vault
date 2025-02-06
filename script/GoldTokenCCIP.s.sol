// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {GoldTokenCCIP} from "../src/GoldTokenCCIP.sol";
import {IRouterClient} from "@chainlink/ccip/ccip/interfaces/IRouterClient.sol";

contract GoldTokenCCIPScript is Script {
    GoldTokenCCIP public goldTokenCCIP;

    uint256 public chainId = block.chainid;

    address public ethUsdFeed;
    address public xauUsdFeed;
    address public routerAddress;
    uint64 public DESTINATION_CHAIN_SELECTOR; // BNB destination chain selector;

    function setUp() public {
        if (chainId == 11155111) {
            // Sepolia Testnet
            ethUsdFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306; // Sepolia ETH/USD Feed
            xauUsdFeed = 0xC5981F461d74c46eB4b0CF3f4Ec79f025573B0Ea; // Sepolia XAU/USD Feed
            routerAddress = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59; // Sepolia Router
            DESTINATION_CHAIN_SELECTOR = 13264668187771770619; // BNB destination chain selector on testnet
        } else if (chainId == 137) {
            // Polygon mainnet
            ethUsdFeed = 0xF9680D99D6C9589e2a93a78A04A279e509205945; // Polygon ETH/USD Feed
            xauUsdFeed = 0x0C466540B2ee1a31b441671eac0ca886e051E410; // Polygon XAU/USD Feed
            routerAddress = 0x849c5ED5a80F5B408Dd4969b78c2C8fdf0565Bfe; // Polygon Router
            DESTINATION_CHAIN_SELECTOR = 11344663589394136015; // BNB destination chain selector on mainnet
        } else {
            revert("Unsupported network");
        }
    }

    function run() public {
        vm.startBroadcast();

        goldTokenCCIP = new GoldTokenCCIP(
            ethUsdFeed,
            xauUsdFeed,
            routerAddress,
            DESTINATION_CHAIN_SELECTOR
        );

        vm.stopBroadcast();
    }
}
