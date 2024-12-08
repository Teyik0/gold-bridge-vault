// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {GoldToken} from "../src/GoldToken.sol";

contract DataFeedScript is Script {
    GoldToken public goldToken;

    uint256 chainId = block.chainid;

    address ethUsdFeed;
    address xauUsdFeed;

    function setUp() public {
        if (chainId == 11155111) {
            // Sepolia Testnet
            ethUsdFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306; // Sepolia ETH/USD Feed
            xauUsdFeed = 0xC5981F461d74c46eB4b0CF3f4Ec79f025573B0Ea; // Sepolia XAU/USD Feed
        } else if (chainId == 137) {
            // Polygon mainnet
            ethUsdFeed = 0xF9680D99D6C9589e2a93a78A04A279e509205945; // Polygon ETH/USD Feed
            xauUsdFeed = 0x0C466540B2ee1a31b441671eac0ca886e051E410; // Polygon XAU/USD Feed
        } else {
            revert("Unsupported network");
        }
    }

    function run() public {
        vm.startBroadcast();

        goldToken = new GoldToken(
            vm.envAddress("PUBLIC_WALLET_ADDRESS"),
            ethUsdFeed,
            xauUsdFeed
        );

        vm.stopBroadcast();
    }
}
