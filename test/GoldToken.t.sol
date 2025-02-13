// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {GoldToken} from "../src/GoldToken.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

// forge coverage --report debug > report.log
contract GoldTokenTest is Test {
    GoldToken public goldToken;
    MockV3Aggregator public mock_eth_usd;
    MockV3Aggregator public mock_xau_usd;

    uint256 public constant FEE_PERCENT = 5;
    uint8 public constant DECIMALS = 18;

    // initial mocked value -> 1 eth = 4000 USD
    uint256 public constant ETH_USD_VAL = 4000 ether;
    // initial mocked value -> 1 ounce of gold = 2500 USD
    uint256 public constant XAU_USD_VAL = 2500 ether;

    address public constant USER1 = address(0x1);
    address public constant USER2 = address(0x2);

    function setUp() public {
        mock_eth_usd = new MockV3Aggregator(DECIMALS, int256(ETH_USD_VAL));
        mock_xau_usd = new MockV3Aggregator(DECIMALS, int256(XAU_USD_VAL));

        goldToken = new GoldToken(address(mock_eth_usd), address(mock_xau_usd));

        vm.deal(USER1, 2 ether);
        vm.deal(USER2, 1 ether);
    }

    function test_getETHPrice() public view {
        uint256 price = goldToken.getETHPrice();
        assertEq(price, ETH_USD_VAL);
    }

    function test_getETHPrice_failed() public {
        mock_eth_usd.updateRoundData(0, 0, block.timestamp, block.timestamp);
        vm.expectRevert(
            abi.encodeWithSignature(
                "InvalidAmount(address,uint256,string)",
                address(this),
                0,
                "Invalid price"
            )
        );
        goldToken.getETHPrice();
    }

    function test_getXAUPrice() public view {
        uint256 price = goldToken.getXAUPrice();
        assertEq(price, XAU_USD_VAL);
    }

    function test_getXAUPrice_failed() public {
        mock_xau_usd.updateRoundData(0, 0, block.timestamp, block.timestamp);
        vm.expectRevert(
            abi.encodeWithSignature(
                "InvalidAmount(address,uint256,string)",
                address(this),
                0,
                "Invalid price"
            )
        );
        goldToken.getXAUPrice();
    }

    function test_mint_1OounceXau() public {
        // user want to buy 1 ounce of gold and xau price mocked to 2500 USD
        vm.startPrank(USER1);
        uint256 etherSpent = (ETH_USD_VAL * 1e18) / XAU_USD_VAL;
        goldToken.mint{value: etherSpent}();
        assertEq(goldToken.balanceOf(USER1), 0.95 ether); // 1 ounce - 5% fee = 0.95 ounce
        vm.stopPrank();
    }

    function test_mint_failed_zeroValue() public {
        vm.startPrank(USER1);
        vm.expectRevert(
            abi.encodeWithSignature(
                "InvalidAmount(address,uint256,string)",
                USER1,
                0,
                "Value should be strictly positive"
            )
        );
        goldToken.mint{value: 0}();
        vm.stopPrank();
    }

    function test_burn_1OounceXau() public {
        // user want to burn 0.5 ounce of gold, user rest is 0.45 ounce
        vm.startPrank(USER1);
        uint256 etherSpent = (ETH_USD_VAL * 1e18) / XAU_USD_VAL;
        goldToken.mint{value: etherSpent}();
        goldToken.burn(0.5 ether);
        assertEq(goldToken.balanceOf(USER1), 0.45 ether);
        vm.stopPrank();
    }

    function test_burn_1OunceXau_failed_notEnoughFund() public {
        // user want to burn 1.5 ounce of gold, but he can't
        vm.startPrank(USER1);
        uint256 etherSpent = (ETH_USD_VAL * 1e18) / XAU_USD_VAL;
        goldToken.mint{value: etherSpent}();

        vm.expectRevert(
            abi.encodeWithSignature(
                "InvalidAmount(address,uint256,string)",
                USER1,
                1.5 ether,
                "Insufficient balance"
            )
        );
        goldToken.burn(1.5 ether);
        vm.stopPrank();
    }

    function test_burn_1OounceXau_failed_etherRefundNotEnoughtBalance() public {
        // user want to burn 0.5 ounce of gold, user rest is 0.45 ounce
        vm.startPrank(USER1);
        uint256 etherSpent = (ETH_USD_VAL * 1e18) / XAU_USD_VAL;
        goldToken.mint{value: etherSpent}();

        vm.startPrank(USER1);
        mock_xau_usd.updateRoundData(
            0,
            80000 ether,
            block.timestamp,
            block.timestamp
        ); // Gold price has increased a lot
        vm.expectRevert(
            abi.encodeWithSignature(
                "refundFailed(address,string)",
                USER1,
                "Contract has insufficient balance"
            )
        );
        goldToken.burn(0.5 ether);
        vm.stopPrank();
    }

    function test_receive() public {
        vm.expectRevert("Use mint function to send Ether");
        (bool success, ) = address(goldToken).call{value: 1 ether}("");
        require(success, "Use mint function to send Ether");
    }

    function test_withdraw() public {
        vm.deal(USER1, 1 ether);
        vm.prank(USER1);
        goldToken.mint{value: 1 ether}();

        vm.deal(USER2, 2 ether);
        vm.prank(USER2);
        goldToken.mint{value: 1 ether}();

        goldToken.withdraw(goldToken.collectedFees());
        vm.stopPrank();
    }

    function test_withdraw_failed() public {
        vm.expectRevert("Insufficient balance");
        goldToken.withdraw(1 ether);
    }

    fallback() external payable {
        // Necessary to make work witdraw
    }
}

contract WithdrawFailed is Test {
    GoldToken public goldToken;
    MockV3Aggregator public mock_eth_usd;
    MockV3Aggregator public mock_xau_usd;

    uint256 public constant FEE_PERCENT = 5;
    uint8 public constant DECIMALS = 18;

    // initial mocked value -> 1 eth = 4000 USD
    uint256 public constant ETH_USD_VAL = 4000 ether;
    // initial mocked value -> 1 ounce of gold = 2500 USD
    uint256 public constant XAU_USD_VAL = 2500 ether;

    address public constant USER1 = address(0x1);
    address public constant USER2 = address(0x2);

    function setUp() public {
        mock_eth_usd = new MockV3Aggregator(DECIMALS, int256(ETH_USD_VAL));
        mock_xau_usd = new MockV3Aggregator(DECIMALS, int256(XAU_USD_VAL));

        goldToken = new GoldToken(address(mock_eth_usd), address(mock_xau_usd));

        vm.deal(USER1, 2 ether);
        vm.deal(USER2, 1 ether);
    }

    function test_withdraw_fails() public {
        vm.deal(USER1, 1 ether);
        vm.prank(USER1);
        goldToken.mint{value: 1 ether}();

        vm.deal(USER2, 2 ether);
        vm.prank(USER2);
        goldToken.mint{value: 1 ether}();

        try goldToken.withdraw(goldToken.collectedFees()) {
            revert("Withdraw should fail");
        } catch Error(string memory reason) {
            assertEq(reason, "Withdraw failed");
        }

        vm.stopPrank();
    }
}
