// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {GoldTokenLottery} from "../src/GoldTokenLottery.sol";
import {GoldToken} from "../src/GoldToken.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {VRFV2PlusWrapper} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFV2PlusWrapper.sol";
import {LinkToken} from "chainlink-local/shared/LinkToken.sol";

// forge coverage --report debug > report.log
contract GoldTokenLotteryTest is Test {
    GoldTokenLottery public goldTokenLottery;
    GoldToken public goldToken;

    MockV3Aggregator public mock_eth_usd;
    MockV3Aggregator public mock_xau_usd;

    LinkToken public linkToken;
    // initial mocked value -> current LINK/ETH price
    int256 public constant LINK_USD_VAL = 6896230000000000;
    MockV3Aggregator public mock_link_usd;
    VRFV2PlusWrapper public mock_vrf_wrapper;
    VRFCoordinatorV2_5Mock public mock_vrf_coordinator;

    uint8 public constant DECIMALS = 18;
    // initial mocked value -> 1 eth = 4000 USD
    uint256 public constant ETH_USD_VAL = 4000 ether;
    // initial mocked value -> 1 ounce of gold = 2500 USD
    uint256 public constant XAU_USD_VAL = 2500 ether;

    address public alice;
    address public bob;

    function setUp() public {
        mock_eth_usd = new MockV3Aggregator(DECIMALS, int256(ETH_USD_VAL));
        mock_xau_usd = new MockV3Aggregator(DECIMALS, int256(XAU_USD_VAL));
        goldToken = new GoldToken(address(mock_eth_usd), address(mock_xau_usd));

        mock_vrf_coordinator = new VRFCoordinatorV2_5Mock(
            100000000000000000,
            1000000000,
            LINK_USD_VAL
        );
        uint256 _subId = mock_vrf_coordinator.createSubscription();
        mock_vrf_coordinator.fundSubscriptionWithNative{value: 100 ether}(
            _subId
        );
        mock_vrf_coordinator.fundSubscription(_subId, 100 ether);

        linkToken = new LinkToken();
        mock_link_usd = new MockV3Aggregator(DECIMALS, int256(LINK_USD_VAL));
        // mock_vrf_wrapper = new VRFV2PlusWrapper(
        //     address(linkToken),
        //     address(mock_link_usd),
        //     address(mock_vrf_coordinator),
        //     _subId
        // );
        // doc -> https://docs.chain.link/vrf/v2/direct-funding/examples/test-locally#deploy-vrfv2wrapper
        // mock_vrf_wrapper.setConfig(
        //     60000,
        //     52000,
        //     52000,
        //     10000,
        //     0,
        //     0,
        //     0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc,
        //     10,
        //     10,
        //     LINK_USD_VAL,
        //     1000,
        //     1000
        // );
        // mock_vrf_coordinator.addConsumer(_subId, address(mock_vrf_wrapper));

        // goldTokenLottery = new GoldTokenLottery(
        //     address(address(goldToken)),
        //     address(mock_vrf_wrapper)
        // );

        // alice = makeAddr("alice");
        // bob = makeAddr("bob");
        // vm.deal(alice, 2 ether);
        // vm.deal(bob, 1 ether);

        // vm.prank(alice);
        // goldToken.mint{value: 2 ether}();
        // vm.prank(bob);
        // goldToken.mint{value: 1 ether}();
    }

    // function test_startLottery() public {
    //     goldTokenLottery.startLottery(goldToken.collectedFees(), 0.0001 ether);
    //     assertEq(goldTokenLottery.entryFee(), 0.0001 ether);
    //     assertEq(goldTokenLottery.prizePool(), goldToken.collectedFees());
    //     assertEq(
    //         uint8(goldTokenLottery.lotteryState()),
    //         uint8(GoldTokenLottery.LotteryState.Open)
    //     );
    // }

    // function test_startLottery_failed_notOwner() public {
    //     vm.startPrank(alice);
    //     try
    //         goldTokenLottery.startLottery(
    //             goldToken.collectedFees(),
    //             0.0001 ether
    //         )
    //     {
    //         revert("error if call works");
    //     } catch {}
    //     vm.stopPrank();
    // }

    // function test_startLottery_failed_alreadyOpen() public {
    //     goldTokenLottery.startLottery(goldToken.collectedFees(), 0.0001 ether);
    //     try
    //         goldTokenLottery.startLottery(
    //             goldToken.collectedFees(),
    //             0.0001 ether
    //         )
    //     {
    //         revert("error if call works");
    //     } catch {}
    // }

    // function test_enterLottery() public {
    //     goldTokenLottery.startLottery(goldToken.collectedFees(), 0.0001 ether);
    //     vm.startPrank(alice);
    //     vm.deal(alice, 0.0001 ether);
    //     goldTokenLottery.enterLottery{value: 0.0001 ether}();
    //     assertEq(goldTokenLottery.participants(0), address(alice));
    //     vm.stopPrank();
    // }

    // function test_enterLottery_failed_notOpen() public {
    //     vm.startPrank(alice);
    //     vm.deal(alice, 0.0001 ether);
    //     try goldTokenLottery.enterLottery{value: 0.0001 ether}() {
    //         revert("error if call works");
    //     } catch {}
    //     vm.stopPrank();
    // }

    // function test_enterLottery_failed_incorrectEntryFee1() public {
    //     goldTokenLottery.startLottery(goldToken.collectedFees(), 0.0001 ether);
    //     vm.startPrank(alice);
    //     vm.deal(alice, 0.0002 ether);
    //     try goldTokenLottery.enterLottery{value: 0.0002 ether}() {
    //         revert("error if call works");
    //     } catch {}
    //     vm.stopPrank();
    // }

    // function test_enterLottery_failed_incorrectEntryFee2() public {
    //     goldTokenLottery.startLottery(goldToken.collectedFees(), 0.0001 ether);
    //     vm.startPrank(alice);
    //     try goldTokenLottery.enterLottery() {
    //         revert("error if call works");
    //     } catch {}
    //     vm.stopPrank();
    // }

    // function test_endLottery() public {
    //     goldTokenLottery.startLottery(goldToken.collectedFees(), 0.0001 ether);

    //     vm.deal(alice, 0.0001 ether);
    //     vm.prank(alice);
    //     goldTokenLottery.enterLottery{value: 0.0001 ether}();

    //     goldTokenLottery.endLottery();
    //     uint256 requestId = goldTokenLottery.lastRequestId();

    //     assertEq(requestId, 1);
    //     assertEq(
    //         uint8(goldTokenLottery.lotteryState()),
    //         uint8(GoldTokenLottery.LotteryState.Closed)
    //     );
    // }
}
