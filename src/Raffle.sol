// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
    * @title A sample Raffle Contract
    * @author Mohammadreza Alirad
    * @notice This contract is for creating a sample raffle
    * @dev It implements Chainlink VRFv2.5 and Chainlink Automation
*/
contract Raffle is VRFConsumerBaseV2 {
    /** Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval; // duration of the lottery in seconds
    bytes32 private immutable i_keyhash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyhash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        if(msg.value < i_entranceFee) revert Raffle__SendMoreToEnterRaffle();

        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }

    function pickWinner() public {
        // check to see if enough time has passed
        if ((block.timestamp - s_lastTimeStamp) > i_interval) revert();

        uint256 requestId = i_vrfCoordinator.requestRandomWords({
            keyHash : i_keyhash,
            subId: i_subscriptionId,
            minimumRequestConfirmations : REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords : NUM_WORDS
        });
    }
    
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if(!success) revert Raffle__TransferFailed();
    }

    /**
        * Getters
    */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}