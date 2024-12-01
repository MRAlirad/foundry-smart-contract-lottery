// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    * @title A sample Raffle Contract
    * @author Mohammadreza Alirad
    * @notice This contract is for creating a sample raffle
    * @dev It implements Chainlink VRFv2.5 and Chainlink Automation
*/
contract Raffle {
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {}

    function pickWinner() public {}
    
    /**
        * Getters
    */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}