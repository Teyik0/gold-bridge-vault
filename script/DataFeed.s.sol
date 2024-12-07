// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DataFeed} from "../src/DataFeed.sol";

contract DataFeedScript is Script {
    DataFeed public dataFeed;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        dataFeed = new DataFeed();

        vm.stopBroadcast();
    }
}
