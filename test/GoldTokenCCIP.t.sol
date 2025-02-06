// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {GoldTokenCCIP} from "../src/GoldTokenCCIP.sol";
import {MockV3Aggregator} from "@chainlink/contracts/v0.8/tests/MockV3Aggregator.sol";
import {CCIPLocalSimulator, IRouterClient, BurnMintERC677Helper} from "@chainlink/local/ccip/CCIPLocalSimulator.sol";
import {Client} from "@chainlink/ccip/ccip/libraries/Client.sol";

contract GoldTokenCCIPTest is Test {
    GoldTokenCCIP public goldTokenCCIP;

    MockV3Aggregator public mock_eth_usd;
    MockV3Aggregator public mock_xau_usd;

    uint256 public constant FEE_PERCENT = 5;
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

        mock_eth_usd = new MockV3Aggregator(DECIMALS, int256(ETH_USD_VAL));
        mock_xau_usd = new MockV3Aggregator(DECIMALS, int256(XAU_USD_VAL));

        goldTokenCCIP = new GoldTokenCCIP(
            address(mock_eth_usd),
            address(mock_xau_usd),
            address(sourceRouter),
            chainSelector
        );

        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.deal(alice, 2 ether);
        vm.deal(bob, 1 ether);
    }

    function test_bridgeToBNBChain() external {
        vm.startPrank(alice);
        uint256 etherSpent = (ETH_USD_VAL * 1e18) / XAU_USD_VAL;
        goldTokenCCIP.mint{value: etherSpent}();

        goldTokenCCIP.approve(
            address(goldTokenCCIP),
            goldTokenCCIP.balanceOf(alice)
        );

        goldTokenCCIP.bridgeToBNBChain(alice, goldTokenCCIP.balanceOf(alice));

        uint256 balanceOfAliceAfter = ccipBnMToken.balanceOf(alice);
        assertEq(balanceOfAliceAfter, 0);
        vm.stopPrank();
    }

    function test_bridge_failed_notEnoughBalance() external {
        vm.startPrank(alice);

        goldTokenCCIP.approve(address(goldTokenCCIP), 1 ether);

        // https://book.getfoundry.sh/cheatcodes/expect-revert
        // vm.expectRevert(
        //     abi.encodeWithSelector(
        //         GoldTokenCCIP.NotEnoughBalance.selector,
        //         goldTokenCCIP.balanceOf(alice),
        //         goldTokenCCIP.balanceOf(alice) + 1
        //     )
        // );
        try goldTokenCCIP.bridgeToBNBChain(alice, 1 ether) {
            revert("error if call works");
        } catch {}
        vm.stopPrank();
    }

    function test_bridgeToBNBChain_failed_invalidReceiverAddress() external {
        vm.startPrank(alice);
        uint256 etherSpent = (ETH_USD_VAL * 1e18) / XAU_USD_VAL;
        goldTokenCCIP.mint{value: etherSpent}();

        goldTokenCCIP.approve(
            address(goldTokenCCIP),
            goldTokenCCIP.balanceOf(alice)
        );

        // https://book.getfoundry.sh/cheatcodes/expect-revert
        // vm.expectRevert(
        //     abi.encodeWithSelector(
        //         GoldTokenCCIP.InvalidReceiverAddress.selector,
        //         "Receiver address cannot be 0"
        //     )
        // );
        try
            goldTokenCCIP.bridgeToBNBChain(
                address(0),
                goldTokenCCIP.balanceOf(alice)
            )
        {
            revert("error if call works");
        } catch {}
        vm.stopPrank();
    }
}
