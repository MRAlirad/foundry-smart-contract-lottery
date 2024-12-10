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
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    /** Type Declarations */
    enum RaffleState {OPEN, CALCULATING}

    /** State Variables */
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
    RaffleState private s_raffleState;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyhash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if(msg.value < i_entranceFee) revert Raffle__SendMoreToEnterRaffle();
        
        if(s_raffleState != RaffleState.OPEN) revert Raffle__RaffleNotOpen();

        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }
    
    /**
        * @dev This is the function that the Chainlink Keeper nodes call
        * they look for `upkeepNeeded` to return True.
        * the following should be true for this to return true:
        * 1. The time interval has passed between raffle runs.
        * 2. The lottery is open.
        * 3. The contract has ETH.
        * 4. There are players registered.
        * 5. Implicity, your subscription is funded with LINK.
    */
    function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Automatically called
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded) revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));

        s_raffleState = RaffleState.CALCULATING;

        /** uint256 requestId = */ i_vrfCoordinator.requestRandomWords({
            keyHash : i_keyhash,
            subId: i_subscriptionId,
            minimumRequestConfirmations : REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords : NUM_WORDS
        });
    }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        emit WinnerPicked(recentWinner);

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if(!success) revert Raffle__TransferFailed();
    }

    /**
        * Getters
    */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }
}