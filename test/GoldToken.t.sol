// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {GoldToken} from "../src/GoldToken.sol";
import {MockV3Aggregator} from "@chainlink/contracts/v0.8/tests/MockV3Aggregator.sol";

contract GoldTokenTest is Test {
    GoldToken public goldToken;
    MockV3Aggregator public mock_eth_usd;
    MockV3Aggregator public mock_xau_usd;

    uint256 public constant FEE_PERCENT = 5;
    uint8 public constant DECIMALS = 18;

    // initial mocked value -> 1 eth = 4000 USD
    uint256 public constant ETH_USD_VAL = 4000 ether;
    // initial mocked value -> 1 ounce of gold = 2600 USD
    uint256 public constant XAU_USD_VAL = 2600 ether;

    address public constant USER1 = address(0x1);
    address public constant USER2 = address(0x2);

    function setUp() public {
        mock_eth_usd = new MockV3Aggregator(DECIMALS, int256(ETH_USD_VAL));
        mock_xau_usd = new MockV3Aggregator(DECIMALS, int256(XAU_USD_VAL));

        goldToken = new GoldToken(
            address(this),
            address(mock_eth_usd),
            address(mock_xau_usd)
        );

        vm.deal(USER1, 1 ether);
        vm.deal(USER2, 0.5 ether);
    }

    function testGetETHPrice() public view {
        uint256 price = goldToken.getETHPrice();
        assertEq(price, ETH_USD_VAL);
    }
    function testGetXAUPrice() public view {
        uint256 price = goldToken.getXAUPrice();
        assertEq(price, XAU_USD_VAL);
    }

    function testMint5OunceXau() public {
        // user want to buy 1 ounce of gold and xau price mocked to 2600 USD
        vm.startPrank(USER1);
        uint256 etherSpent = (XAU_USD_VAL * 1e18) / ETH_USD_VAL;
        goldToken.mint{value: etherSpent}();
        assertEq(goldToken.balanceOf(USER1), 0.95 ether); // 1 ounce - 5% fee
        vm.stopPrank();
    }

    function testMintFailedNotEnoughFund() public {
        // user want to buy 2 ounce of gold
        vm.startPrank(USER1);
        uint256 etherSpent = (XAU_USD_VAL * 2 * 1e18) / ETH_USD_VAL;
        vm.expectRevert();
        goldToken.mint{value: etherSpent}();
        vm.stopPrank();
    }
}
