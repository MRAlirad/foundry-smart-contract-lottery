// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    * @title A sample Raffle Contract
    * @author Mohammadreza Alirad
    * @notice This contract is for creating a sample raffle
    * @dev It implements Chainlink VRFv2.5 and Chainlink Automation
*/
contract Raffle {
    /** Errors */
    error Raffle__SendMoreToEnterRaffle();

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval; // duration of the lottery in seconds
    address payable[] private s_players;
    uint256 private s_timestamp;

    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestmap;
    }

    function enterRaffle() external payable {
        if(msg.value < i_entranceFee) revert Raffle__SendMoreToEnterRaffle();

        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }

    function pickWinner() public {
        // check to see if enough time has passed
        if ((block.timestamp - s_lastTimeStamp) < interval) revert();
    }

    /**
        * Getters
    */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}