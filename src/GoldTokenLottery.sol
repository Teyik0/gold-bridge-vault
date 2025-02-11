// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.19;

import {console} from "forge-std/Test.sol";
import {GoldToken} from "./GoldToken.sol";
import {VRFV2PlusWrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

/**
 * @title GoldTokenLottery
 * @notice This contract implements a lottery system using GoldToken and Chainlink VRF.
 */
contract GoldTokenLottery is ConfirmedOwner, VRFV2PlusWrapperConsumerBase {
    GoldToken public goldToken;
    uint256 public entryFee; // User fee in native tokens
    address[] public participants;
    uint256 public prizePool; // Total prize pool for the lottery

    enum LotteryState {
        Open,
        Closed
    }
    LotteryState public lotteryState;

    event LotteryEntered(address indexed participant);
    event WinnerSelected(address indexed winner, uint256 amountWon);

    struct RequestStatus {
        uint256 paid; // Amount paid for the request
        bool fulfilled; // Whether the request has been fulfilled
        uint256[] randomWords; // Random words received
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    // Past request IDs
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // VRF parameters
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1; // Only one random number needed for the winner

    /**
     * @notice Constructor initializes the contract with the router address.
     * @param _goldTokenAddress The address of the goldToken contract.
     * @param _wrapperAddress The address of the Chainlink VRF wrapper.
     */
    constructor(
        address _goldTokenAddress,
        address _wrapperAddress
    ) ConfirmedOwner(msg.sender) VRFV2PlusWrapperConsumerBase(_wrapperAddress) {
        goldToken = GoldToken(payable(_goldTokenAddress));
        lotteryState = LotteryState.Closed;
    }

    /**
     * @notice Starts the lottery with a specified prize pool and entry fee.
     * @param _prizePool The total prize pool for the lottery.
     * @param _entryFee The entry fee in native tokens.
     */
    function startLottery(
        uint256 _prizePool,
        uint256 _entryFee
    ) external onlyOwner {
        require(lotteryState == LotteryState.Closed, "Lottery is already open");
        require(
            goldToken.collectedFees() >= _prizePool,
            "Prize pool must be less or equal to collected fees"
        );

        prizePool = _prizePool;
        entryFee = _entryFee;
        lotteryState = LotteryState.Open;
    }

    /**
     * @notice Allows users to enter the lottery by paying the entry fee.
     */
    function enterLottery() external payable {
        require(lotteryState == LotteryState.Open, "Lottery is not open");
        require(msg.value == entryFee, "Incorrect entry fee");

        participants.push(msg.sender);
        emit LotteryEntered(msg.sender);
    }

    /**
     * @notice Ends the lottery and requests randomness from Chainlink VRF.
     */
    function endLottery() external onlyOwner {
        require(lotteryState == LotteryState.Open, "Lottery is not open");
        require(participants.length > 0, "No participants in the lottery");

        lotteryState = LotteryState.Closed;

        // Request randomness from Chainlink VRF
        _requestRandomWords();
        emit WinnerSelected(address(0), prizePool); // Placeholder for winner event
    }

    /**
     * @notice Requests random words from Chainlink VRF.
     * @return requestId The ID of the randomness request.
     */
    function _requestRandomWords() internal returns (uint256) {
        bytes memory extraArgs = VRFV2PlusClient._argsToBytes(
            VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
        );
        uint256 requestId;
        uint256 reqPrice;
        (requestId, reqPrice) = requestRandomnessPayInNative(
            callbackGasLimit,
            requestConfirmations,
            numWords,
            extraArgs
        );
        s_requests[requestId] = RequestStatus({
            paid: reqPrice,
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        return requestId;
    }

    /**
     * @notice Callback function that is called by Chainlink VRF with the random words.
     * @param _requestId The ID of the randomness request.
     * @param _randomWords The random words received from Chainlink VRF.
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "Request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        // Select the winner based on the random number
        uint256 winnerIndex = _randomWords[0] % participants.length;
        address winner = participants[winnerIndex];

        // Transfer the prize pool to the winner
        (bool success, ) = winner.call{value: prizePool}("");
        require(success, "Transfer to winner failed");

        emit WinnerSelected(winner, prizePool);

        // Reset participants for the next lottery
        delete participants;
    }

    /**
     * @notice Allows the owner to withdraw any native tokens from the contract.
     * @param amount The amount of native tokens to withdraw.
     */
    function withdrawNative(uint256 amount) external onlyOwner {
        require(amount <= goldToken.collectedFees());
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Withdraw failed");
    }
}
