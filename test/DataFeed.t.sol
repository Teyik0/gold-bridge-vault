// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DataFeed} from "../src/DataFeed.sol";
import {MockV3Aggregator} from "@chainlink/contracts/v0.8/tests/MockV3Aggregator.sol";

contract DataFeedTest is Test {
    DataFeed public dataFeed;
    MockV3Aggregator public oracle;

    function setUp() public {
        oracle = new MockV3Aggregator(
            18, //decimals
            1   //initial data
        );
        dataFeed = new DataFeed();
    }

    function test_get_ETH_USD() public {
        int price = dataFeed.getLatestPrice();
        console.log(price);
        assertEq(price, 1);
    }
}
