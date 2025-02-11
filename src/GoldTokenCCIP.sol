// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.19;

import {console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract GoldTokenCCIP {
    error NotEnoughBalance(uint256 currentBalance, uint256 neededAmount);
    error InvalidReceiverAddress();

    using SafeERC20 for IERC20;

    event TokensTransferred(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        address token,
        uint256 tokenAmount,
        address feeToken,
        uint256 fees
    );

    IRouterClient private s_router;
    uint64 immutable DESTINATION_CHAIN_SELECTORR;
    address public goldToken;

    /**
     * @notice Constructor initializes the contract with the router address.
     * @param _router The address of the router contract.
     */
    constructor(
        address _router,
        uint64 _destinationChainSelector,
        address _goldToken
    ) {
        s_router = IRouterClient(_router);
        goldToken = _goldToken;
        DESTINATION_CHAIN_SELECTORR = _destinationChainSelector;
    }

    /**
     * @notice Transfer tokens to receiver on BNB chain.
     * @notice pay in native gas such as ETH on Ethereum or POL on Polygon.
     * @notice the token must be in the list of supported tokens.
     * @notice This function can only be called by the owner.
     * @dev Assumes your contract has sufficient native gas like ETH on Ethereum or POL on Polygon.
     * @param _receiver The address of the recipient on the destination blockchain.
     * @param _amount token amount.
     * @return messageId The ID of the message that was sent.
     */
    function bridgeToBNBChain(
        address _receiver,
        uint256 _amount
    ) external returns (bytes32 messageId) {
        if (_receiver == address(0)) revert InvalidReceiverAddress();
        if (_amount > IERC20(address(goldToken)).balanceOf(msg.sender)) {
            revert NotEnoughBalance(
                IERC20(address(goldToken)).balanceOf(msg.sender),
                _amount
            );
        }

        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _receiver,
            address(goldToken),
            _amount,
            address(0)
        );

        uint256 fees = s_router.getFee(
            DESTINATION_CHAIN_SELECTORR,
            evm2AnyMessage
        );

        IERC20(goldToken).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(goldToken).approve(address(s_router), _amount);

        messageId = s_router.ccipSend{value: fees}(
            DESTINATION_CHAIN_SELECTORR,
            evm2AnyMessage
        );

        emit TokensTransferred(
            messageId,
            DESTINATION_CHAIN_SELECTORR,
            _receiver,
            address(this),
            _amount,
            address(0),
            fees
        );

        return messageId;
    }

    /**
     * @notice Construct a CCIP message.
     * @dev This function will create an EVM2AnyMessage struct with all the necessary information for tokens transfer.
     * @param _receiver The address of the receiver.
     * @param _token The token to be transferred.
     *  @param _amount The amount of the token to be transferred.
     * @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas.
     * @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
     */
    function _buildCCIPMessage(
        address _receiver,
        address _token,
        uint256 _amount,
        address _feeTokenAddress
    ) private pure returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });

        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver),
                data: "",
                tokenAmounts: tokenAmounts,
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV2({
                        gasLimit: 0,
                        allowOutOfOrderExecution: true
                    })
                ),
                feeToken: _feeTokenAddress
            });
    }
}
