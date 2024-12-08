// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";

error InvalidAmount(address caller, uint256 amount, string message);

contract GoldToken is ERC20, Ownable, ERC20Permit {
    AggregatorV3Interface internal immutable ETH_USD_PRICE_FEED;
    AggregatorV3Interface internal immutable GOLD_USD_PRICE_FEED;
    // Fees for minting and burning
    uint256 public constant FEE_PERCENT = 5;

    event Mint(address indexed user, uint256 amount, uint256 etherSpent);
    event Burn(address indexed user, uint256 amount, uint256 etherRefunded);

    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     * Aggregator: XAU/USD
     * Address: 0xC5981F461d74c46eB4b0CF3f4Ec79f025573B0Ea
     */
    constructor(
        address initialOwner,
        address _eth_usd_agg,
        address _gold_usd_agg
    ) ERC20("GOLD", "GLD") Ownable(initialOwner) ERC20Permit("GOLD") {
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
                "Value should be positive"
            );
        uint256 etherPrice = getETHPrice();
        uint256 goldOuncePrice = getXAUPrice();
        uint256 feeValue = (msg.value * FEE_PERCENT) / 100;
        uint256 goldAmount = ((msg.value - feeValue) * etherPrice) /
            goldOuncePrice;
        _mint(msg.sender, goldAmount);
        emit Mint(msg.sender, goldAmount, msg.value);
    }

    /**
     * @dev Burns tokens and refunds Ether equivalent minus fees.
     * @param amount The amount of GOLD tokens to burn.
     */
    function burn(uint256 amount) external {
        if (balanceOf(msg.sender) <= amount)
            revert InvalidAmount(msg.sender, amount, "Insufficient balance");
        // Calculate fee and final refundable amount
        uint256 fee = (amount * FEE_PERCENT) / 100;
        uint256 refundableAmount = amount - fee;

        // Get the latest gold price
        uint256 goldPricePerGramUSD = getXAUPrice();

        // Calculate Ether equivalent for the refundable amount
        uint256 etherPrice = getETHPrice();
        uint256 etherRefund = (refundableAmount * goldPricePerGramUSD * 1e18) /
            etherPrice;

        // Burn the tokens
        _burn(msg.sender, amount);

        // Refund Ether
        (bool success, ) = msg.sender.call{value: etherRefund}("");
        require(success, "Ether refund failed");

        emit Burn(msg.sender, amount, etherRefund);
    }

    /**
     * @dev Gets the latest price of gold in USD per gram.
     */
    function getXAUPrice() public view returns (uint256) {
        (, int256 price, , , ) = GOLD_USD_PRICE_FEED.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }

    /**
     * @dev Gets the latest Ether price in USD.
     */
    function getETHPrice() public view returns (uint256) {
        (, int256 price, , , ) = ETH_USD_PRICE_FEED.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }

    /**
     * @dev Fallback function to reject direct Ether transfers.
     */
    receive() external payable {
        revert("Use the mint function to send Ether");
    }
}
