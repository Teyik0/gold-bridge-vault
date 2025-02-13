// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {GoldTokenCCIP} from "../src/GoldTokenCCIP.sol";
import {GoldToken} from "../src/GoldToken.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {CCIPLocalSimulator, IRouterClient, BurnMintERC677Helper} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract GoldTokenCCIPTest is Test {
    GoldTokenCCIP public goldTokenCCIP;
    GoldToken public goldToken;

    MockV3Aggregator public mock_eth_usd;
    MockV3Aggregator public mock_xau_usd;

    uint8 public constant DECIMALS = 18;
    // initial mocked value -> 1 eth = 4000 USD
    uint256 public constant ETH_USD_VAL = 4000 ether;
    // initial mocked value -> 1 ounce of gold = 2500 USD
    uint256 public constant XAU_USD_VAL = 2500 ether;

    CCIPLocalSimulator public ccipLocalSimulator;
    address public alice;
    address public bob;
    IRouterClient public router;
    uint64 public destinationChainSelector;
    BurnMintERC677Helper public ccipBnMToken;

    function setUp() public {
        mock_eth_usd = new MockV3Aggregator(DECIMALS, int256(ETH_USD_VAL));
        mock_xau_usd = new MockV3Aggregator(DECIMALS, int256(XAU_USD_VAL));
        goldToken = new GoldToken(address(mock_eth_usd), address(mock_xau_usd));

        ccipLocalSimulator = new CCIPLocalSimulator();
        (
            uint64 chainSelector,
            IRouterClient sourceRouter,
            ,
            ,
            ,
            BurnMintERC677Helper ccipBnM,

        ) = ccipLocalSimulator.configuration();

        destinationChainSelector = chainSelector;
        router = sourceRouter;
        ccipBnMToken = ccipBnM;

        goldTokenCCIP = new GoldTokenCCIP(
            address(sourceRouter),
            chainSelector,
            address(goldToken)
        );

        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.deal(alice, 2 ether);
        vm.deal(bob, 1 ether);
    }

    function test_bridgeToBNBChain() external {
        vm.startPrank(alice);
        uint256 etherSpent = (ETH_USD_VAL * 1e18) / XAU_USD_VAL;
        goldToken.mint{value: etherSpent}();

        goldToken.approve(address(goldTokenCCIP), goldToken.balanceOf(alice));
        goldTokenCCIP.bridgeToBNBChain(alice, goldToken.balanceOf(alice));

        uint256 balanceOfAliceAfter = ccipBnMToken.balanceOf(alice);
        assertEq(balanceOfAliceAfter, 0);
        vm.stopPrank();
    }

    function test_bridge_failed_notEnoughBalance() external {
        vm.startPrank(alice);

        goldToken.approve(address(goldTokenCCIP), 1 ether);
        vm.expectRevert(
            abi.encodeWithSignature(
                "NotEnoughBalance(uint256,uint256)",
                0,
                1 ether
            )
        );
        goldTokenCCIP.bridgeToBNBChain(alice, 1 ether);
        vm.stopPrank();
    }

    function test_bridgeToBNBChain_failed_invalidReceiverAddress() external {
        vm.startPrank(alice);
        uint256 etherSpent = (ETH_USD_VAL * 1e18) / XAU_USD_VAL;
        goldToken.mint{value: etherSpent}();
        goldToken.approve(address(goldTokenCCIP), goldToken.balanceOf(alice));

        // https://book.getfoundry.sh/cheatcodes/expect-revert
        // vm.expectRevert();
        // goldTokenCCIP.bridgeToBNBChain(address(0), goldToken.balanceOf(alice));
        try
            goldTokenCCIP.bridgeToBNBChain(
                address(0),
                goldToken.balanceOf(alice)
            )
        {
            revert("error if call works");
        } catch {}
        vm.stopPrank();
    }
}
