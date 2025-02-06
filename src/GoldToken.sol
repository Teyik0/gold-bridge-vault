// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";

contract GoldToken is ERC20, ERC20Permit, ReentrancyGuard {
    error InvalidAmount(address caller, uint256 amount, string message);
    error refundFailed(address caller, string message);

    AggregatorV3Interface internal immutable ETH_USD_PRICE_FEED;
    AggregatorV3Interface internal immutable GOLD_USD_PRICE_FEED;
    // Fees for minting and burning
    uint256 public constant FEE_PERCENT = 5;

    event Mint(address indexed user, uint256 amount, uint256 etherSpent);
    event Burn(address indexed user, uint256 amount, uint256 etherRefunded);

    constructor(
        address _eth_usd_agg,
        address _gold_usd_agg
    ) ERC20("GOLD", "GLD") ERC20Permit("GOLD") {
        ETH_USD_PRICE_FEED = AggregatorV3Interface(_eth_usd_agg);
        GOLD_USD_PRICE_FEED = AggregatorV3Interface(_gold_usd_agg);
    }

    /**
     * @dev Mints tokens based on the current gold price and Ether sent.
     */
    function mint() external payable {
        if (msg.value <= 0)
            revert InvalidAmount(
                msg.sender,
                msg.value,
                "Value should be strictly positive"
            );
        uint256 etherPrice = getETHPrice();
        uint256 goldOuncePrice = getXAUPrice();

        uint256 goldOunceAmount = (msg.value * goldOuncePrice) / etherPrice;
        uint256 fee = (goldOunceAmount * FEE_PERCENT) / 100;

        _mint(msg.sender, goldOunceAmount - fee);
        emit Mint(msg.sender, goldOunceAmount, msg.value);
    }

    /**
     * @dev Burns tokens and refunds Ether equivalent minus fees.
     * @param amount The amount of GOLD tokens to burn.
     */
    function burn(uint256 amount) external nonReentrant {
        if (balanceOf(msg.sender) <= amount)
            revert InvalidAmount(msg.sender, amount, "Insufficient balance");
        uint256 goldOuncePrice = getXAUPrice();
        uint256 etherPrice = getETHPrice();

        uint256 userGoldAmountToRefund = (amount * goldOuncePrice) / 1e18;
        uint256 etherToRefund = (userGoldAmountToRefund * 1e18) / etherPrice;
        uint256 fee = (etherToRefund * FEE_PERCENT) / 100;

        (bool success, ) = msg.sender.call{value: etherToRefund - fee}("");
        if (!success)
            revert refundFailed(
                msg.sender,
                "Contract has insufficient balance"
            );

        _burn(msg.sender, amount);

        emit Burn(msg.sender, amount, etherToRefund);
    }

    /**
     * @dev Gets the latest price of gold in USD per gram.
     */
    function getXAUPrice() public view returns (uint256) {
        (, int256 price, , , ) = GOLD_USD_PRICE_FEED.latestRoundData();
        if (price <= 0)
            revert InvalidAmount(msg.sender, uint256(price), "Invalid price");
        return uint256(price);
    }

    /**
     * @dev Gets the latest Ether price in USD.
     */
    function getETHPrice() public view returns (uint256) {
        (, int256 price, , , ) = ETH_USD_PRICE_FEED.latestRoundData();
        if (price <= 0)
            revert InvalidAmount(msg.sender, uint256(price), "Invalid price");
        return uint256(price);
    }

    /**
     * @dev Fallback function to reject direct Ether transfers.
     */
    receive() external payable {
        revert("Use mint function to send Ether");
    }
}
